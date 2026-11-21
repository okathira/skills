#!/usr/bin/env python3
"""Maintain an OKF v0.3 LLM wiki bundle: generate index files and lint llm-wiki rules.

  llm_wiki.py index [--bundle docs/wiki] [--check]
  llm_wiki.py lint  [--bundle docs/wiki] [--strict]

lint runs okf-generate's validate.py (installed next to this skill) for OKF conformance, then adds
the llm-wiki layer: generated directory indexes, x-zvec-aliases, the directory/type map, repository
paths outside the bundle, and leftover pre-OKF keys. Requires Python 3.9+ and PyYAML.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.parse
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    print("llm_wiki.py: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

TYPE_BY_DIR = {
    "summaries": "Reference",
    "entities": "Entity",
    "concepts": "Concept",
    "analyses": "Analysis",
    "decisions": "Decision Record",
    "runbooks": "Playbook",
}
DEFAULT_DIRS = {
    "summaries": ("Summaries", "Source summaries and provenance."),
    "entities": ("Entities", "People, systems, projects, and products."),
    "concepts": ("Concepts", "Terms, patterns, rules, and ideas."),
    "analyses": ("Analyses", "Syntheses and crystallized answers."),
    "decisions": ("Decisions", "Architecture decision records."),
    "runbooks": ("Runbooks", "Repeatable procedures."),
}
DEFAULT_LOG = ("Operation log", "History of wiki operations, newest date first.")
LEGACY_KEYS = ("aliases", "source", "date", "deciders")
ALIAS_KEY = "x-zvec-aliases"
ALIAS_RANGE = (3, 6)

LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
ENTRY_RE = re.compile(r"^\*\s+\[([^\]]*)\]\(([^)\s]+)\)(?:\s+-\s+(.*))?$")
SCHEME_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")
WIKILINK_RE = re.compile(r"\[\[[^\]]+\]\]")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
FENCE_RE = re.compile(r"^\s{0,3}(```|~~~)")


@dataclass
class Doc:
    path: Path
    meta: dict[str, Any]
    has_frontmatter: bool
    frontmatter_text: str
    body: str
    body_line: int

    @property
    def is_concept(self) -> bool:
        value = self.meta.get("type")
        return isinstance(value, str) and value.strip() != ""


def read_doc(path: Path) -> Doc:
    text = path.read_text(encoding="utf-8").lstrip("\ufeff")
    lines = text.split("\n")
    if lines and lines[0].rstrip("\r") == "---":
        for index in range(1, len(lines)):
            if lines[index].rstrip("\r") == "---":
                block = "\n".join(lines[1:index])
                try:
                    meta = yaml.safe_load(block) or {}
                except yaml.YAMLError:
                    meta = {}
                if not isinstance(meta, dict):
                    meta = {}
                return Doc(path, meta, True, block, "\n".join(lines[index + 1:]), index + 2)
    return Doc(path, {}, False, "", text, 1)


def prose_lines(body: str):
    fenced = False
    for offset, line in enumerate(body.split("\n")):
        if FENCE_RE.match(line):
            fenced = not fenced
            continue
        if not fenced:
            yield offset, INLINE_CODE_RE.sub("", line)


def first_heading(body: str) -> str | None:
    for _, line in prose_lines(body):
        match = re.match(r"^#\s+(.+?)\s*#*\s*$", line)
        if match:
            return match.group(1)
    return None


def one_line(value: Any) -> str:
    return " ".join(str(value).split()) if value else ""


class Bundle:
    def __init__(self, root: Path):
        self.root = root.resolve()

    def rel(self, path: Path) -> str:
        return path.resolve().relative_to(self.root).as_posix()

    def inside(self, path: Path) -> bool:
        try:
            path.resolve().relative_to(self.root)
            return True
        except ValueError:
            return False

    def walk_dirs(self):
        for current, dirs, _files in os.walk(self.root):
            dirs[:] = sorted(d for d in dirs if not d.startswith("."))
            yield Path(current)

    def markdown_files(self, directory: Path) -> list[Path]:
        return sorted(p for p in directory.iterdir() if p.is_file() and p.suffix == ".md" and not p.name.startswith("."))

    def all_markdown(self):
        for directory in self.walk_dirs():
            yield from self.markdown_files(directory)


# ---- index generation (OKF section 8) --------------------------------------

def existing_entries(index_path: Path) -> dict[str, tuple[str, str]]:
    entries: dict[str, tuple[str, str]] = {}
    if not index_path.is_file():
        return entries
    for line in index_path.read_text(encoding="utf-8").split("\n"):
        match = ENTRY_RE.match(line.strip())
        if match:
            title, target, description = match.group(1), match.group(2), match.group(3) or ""
            key = target[:-len("index.md")] if target.endswith("/index.md") else target
            entries[key] = (title, description.strip())
    return entries


def entry(title: str, target: str, description: str) -> str:
    return f"* [{title}]({target})" + (f" - {description}" if description else "")


def has_content(bundle: Bundle, directory: Path) -> bool:
    for path in directory.rglob("*"):
        rel_parts = path.relative_to(directory).parts
        if any(part.startswith(".") for part in rel_parts):
            continue
        if path.is_file() and path.name not in ("index.md", "log.md"):
            return True
    return False


def build_index(bundle: Bundle, directory: Path) -> str:
    index_path = directory / "index.md"
    old_entries = existing_entries(index_path)
    is_root = directory.resolve() == bundle.root
    lines: list[str] = []

    old_doc = read_doc(index_path) if index_path.is_file() else None
    if is_root and old_doc and old_doc.has_frontmatter:
        lines += ["---", old_doc.frontmatter_text, "---", ""]

    heading = first_heading(old_doc.body) if old_doc else None
    if not heading:
        if is_root:
            title = old_doc.meta.get("title") if old_doc else None
            heading = one_line(title) or "Wiki"
        else:
            heading = DEFAULT_DIRS.get(directory.name, (directory.name.replace("-", " ").title(), ""))[0]
    lines += [f"# {heading}", ""]

    items: list[str] = []
    for sub in sorted(p for p in directory.iterdir() if p.is_dir() and not p.name.startswith(".")):
        if not has_content(bundle, sub):
            continue
        key = f"{sub.name}/"
        default_title, default_description = DEFAULT_DIRS.get(sub.name, (sub.name.replace("-", " ").title(), ""))
        title, description = old_entries.get(key, (default_title, default_description))
        items.append(entry(title or default_title, f"{sub.name}/index.md", description or default_description))

    for path in bundle.markdown_files(directory):
        if path.name in ("index.md", "log.md"):
            continue
        doc = read_doc(path)
        if not doc.is_concept:
            continue
        title = one_line(doc.meta.get("title")) or path.stem
        description = one_line(doc.meta.get("description"))
        items.append(entry(title, urllib.parse.quote(path.name), description))

    if (directory / "log.md").is_file():
        title, description = old_entries.get("log.md", DEFAULT_LOG)
        items.append(entry(title or DEFAULT_LOG[0], "log.md", description or DEFAULT_LOG[1]))

    lines += items
    return "\n".join(lines).rstrip("\n") + "\n"


def index_targets(bundle: Bundle) -> list[Path]:
    targets = [bundle.root]
    for directory in bundle.walk_dirs():
        if directory.resolve() != bundle.root and has_content(bundle, directory):
            targets.append(directory)
    return targets


def cmd_index(bundle: Bundle, check: bool) -> int:
    stale = 0
    for directory in index_targets(bundle):
        index_path = directory / "index.md"
        content = build_index(bundle, directory)
        current = index_path.read_text(encoding="utf-8") if index_path.is_file() else None
        if current == content:
            continue
        if check:
            stale += 1
            print(f"{bundle.rel(index_path) if index_path.exists() else bundle.rel(directory) + '/index.md'}: error ZE010 index.md is not up to date; run llm_wiki.py index")
        else:
            index_path.write_text(content, encoding="utf-8")
            print(f"wrote {bundle.rel(index_path)}")
    for directory in bundle.walk_dirs():
        if directory.resolve() != bundle.root and (directory / "index.md").is_file() and not has_content(bundle, directory):
            print(f"{bundle.rel(directory / 'index.md')}: warning ZW011 the directory has no content; delete this index.md")
    return 1 if stale else 0


# ---- lint (llm-wiki layer) -------------------------------------------------

class Linter:
    def __init__(self, bundle: Bundle):
        self.bundle = bundle
        self.errors = 0
        self.warnings = 0

    def report(self, path: Path, line: int, level: str, code: str, message: str) -> None:
        if level == "error":
            self.errors += 1
        else:
            self.warnings += 1
        print(f"{self.bundle.rel(path)}:{line}: {level} {code} {message}")

    def check_external_path(self, doc: Doc, line: int, value: Any, field: str) -> None:
        if not isinstance(value, str) or SCHEME_RE.match(value) or value.startswith("//"):
            return
        clean = urllib.parse.unquote(value.split("#", 1)[0].split("?", 1)[0])
        if not clean or clean.startswith("/"):
            return
        candidate = Path(os.path.normpath(doc.path.parent / clean))
        if not self.bundle.inside(candidate) and not candidate.exists():
            self.report(doc.path, line, "error", "ZE020", f"{field} {value!r} points outside the bundle to a path that does not exist")

    def lint_concept(self, doc: Doc) -> None:
        meta = doc.meta
        rel = self.bundle.rel(doc.path)
        top = rel.split("/")[0] if "/" in rel else ""
        expected = TYPE_BY_DIR.get(top)
        if expected and meta.get("type") != expected:
            self.report(doc.path, 1, "warning", "ZW030", f"pages in {top}/ use type {expected!r}; found {meta.get('type')!r}")

        for key in LEGACY_KEYS:
            if key in meta:
                self.report(doc.path, 1, "error", "ZE031", f"pre-OKF key {key!r}; run the zvec-llm-wiki-okf-migrate skill")
        if meta.get("status") in ("working", "decided", "proposed", "accepted", "superseded"):
            self.report(doc.path, 1, "error", "ZE032", f"pre-OKF status {meta.get('status')!r}; use draft, deprecated, or omit for stable")

        if not one_line(meta.get("description")):
            self.report(doc.path, 1, "warning", "ZW033", "add a one-sentence description; indexes copy it")
        if "generated" not in meta:
            self.report(doc.path, 1, "warning", "ZW034", "add generated: { by, at } when an agent writes or changes meaning")

        if meta.get("status") != "deprecated":
            aliases = meta.get(ALIAS_KEY)
            if aliases is None:
                self.report(doc.path, 1, "warning", "ZW035", f"add {ALIAS_KEY}: about {ALIAS_RANGE[0]}-{ALIAS_RANGE[1]} retrieval names for this page's fact")
            elif not isinstance(aliases, list) or not all(isinstance(a, str) and a.strip() for a in aliases):
                self.report(doc.path, 1, "warning", "ZW036", f"{ALIAS_KEY} is a YAML list of strings")
            elif not ALIAS_RANGE[0] <= len(aliases) <= ALIAS_RANGE[1]:
                self.report(doc.path, 1, "warning", "ZW037", f"{ALIAS_KEY} has {len(aliases)} names; aim for {ALIAS_RANGE[0]}-{ALIAS_RANGE[1]}")

        sources = meta.get("sources")
        for index, item in enumerate(sources if isinstance(sources, list) else [sources] if sources else []):
            if isinstance(item, dict):
                self.check_external_path(doc, 1, item.get("resource"), f"sources[{index}].resource")
        self.check_external_path(doc, 1, meta.get("superseded_by"), "superseded_by")

    def lint_body(self, doc: Doc) -> None:
        for offset, line in prose_lines(doc.body):
            number = doc.body_line + offset
            if WIKILINK_RE.search(line):
                self.report(doc.path, number, "error", "ZE040", "[[wikilinks]] are not links in OKF; use a relative .md link")
            if re.match(r"^#{1,6}\s+(Aliases|Source|Sources)\s*$", line):
                self.report(doc.path, number, "warning", "ZW041", "body restates frontmatter; keep aliases and sources only in frontmatter")
            for target in LINK_RE.findall(line):
                if not target.startswith("#"):
                    self.check_external_path(doc, number, target, "link")

    def run(self) -> None:
        for path in self.bundle.all_markdown():
            if path.name in ("index.md", "log.md"):
                continue
            doc = read_doc(path)
            if not doc.is_concept:
                if any(k in doc.meta for k in LEGACY_KEYS):
                    self.report(path, 1, "error", "ZE031", "pre-OKF page without type; run the zvec-llm-wiki-okf-migrate skill")
                else:
                    self.report(path, 1, "warning", "ZW021", "not a concept: add frontmatter with type, or move the file out of the bundle to docs/raw/")
                continue
            self.lint_concept(doc)
            self.lint_body(doc)


def find_validator() -> Path | None:
    skills_dir = Path(__file__).resolve().parent.parent.parent
    bases = [skills_dir]
    for root in (Path.cwd(), Path.home()):
        bases += [root / ".agents" / "skills", root / ".claude" / "skills"]
    for base in bases:
        candidate = base / "okf-generate" / "scripts" / "validate.py"
        if candidate.is_file():
            return candidate
    return None


def run_validator(bundle: Bundle, linter: Linter) -> None:
    """Run okf-generate's validate.py and report every finding. Nothing is excused."""
    validator = find_validator()
    if validator is None:
        linter.report(bundle.root, 0, "warning", "ZW050", "okf-generate is not installed next to this skill; run its validate.py --strict by hand")
        return
    result = subprocess.run([sys.executable, str(validator), str(bundle.root), "--json"], capture_output=True, text=True)
    try:
        findings = json.loads(result.stdout)["findings"]
    except (ValueError, KeyError):
        linter.report(bundle.root, 0, "error", "ZE051", f"validate.py failed: {result.stderr.strip() or result.stdout.strip()}")
        return
    for f in findings:
        path = str(f.get("path", ""))
        level = f.get("level")
        line = f"{path}:{f.get('line') or 0}: {level} {f.get('code')} {f.get('message')}"
        if level == "error":
            linter.errors += 1
        elif level == "warning":
            linter.warnings += 1
        print(line)
    print_change_report(findings)


def print_change_report(findings: list) -> None:
    """OKF's change signals are info, not conformance failures: I204 (text changed after
    verification) and I201 (stale_after has passed)."""
    unverified = [f for f in findings if f.get("code") == "I204"]
    stale = [f for f in findings if f.get("code") == "I201"]
    print(f"OKF change report: {len(unverified)} unverified after a change (I204), {len(stale)} past stale_after (I201).")
    for finding in unverified + stale:
        print(f"  {finding.get('path')}: {finding.get('code')}")


def cmd_lint(bundle: Bundle, strict: bool) -> int:
    linter = Linter(bundle)
    run_validator(bundle, linter)
    linter.run()
    stale = cmd_index(bundle, check=True)
    linter.errors += stale
    print(f"llm-wiki lint (OKF validate.py + llm-wiki rules): {linter.errors} errors, {linter.warnings} warnings.")
    if linter.errors or (strict and linter.warnings):
        return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate indexes and lint an OKF LLM wiki bundle.")
    sub = parser.add_subparsers(dest="command", required=True)
    index_parser = sub.add_parser("index", help="regenerate index.md in every directory with content")
    index_parser.add_argument("--bundle", type=Path, default=Path("docs/wiki"))
    index_parser.add_argument("--check", action="store_true", help="exit 1 instead of writing when an index is stale")
    lint_parser = sub.add_parser("lint", help="check llm-wiki rules on top of OKF")
    lint_parser.add_argument("--bundle", type=Path, default=Path("docs/wiki"))
    lint_parser.add_argument("--strict", action="store_true", help="exit 1 when there are warnings")
    args = parser.parse_args(argv)

    if not args.bundle.is_dir():
        print(f"llm_wiki.py: {args.bundle} is not a directory", file=sys.stderr)
        return 2
    bundle = Bundle(args.bundle)
    if args.command == "index":
        return cmd_index(bundle, args.check)
    return cmd_lint(bundle, args.strict)


if __name__ == "__main__":
    sys.exit(main())

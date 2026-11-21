#!/usr/bin/env python3
"""Migrate a pre-OKF zvec-llm-wiki wiki to OKF v0.3, and record review verifications.

  okf_migrate.py convert --actor <tool>/<model> [--bundle docs/wiki] [--title T] [--description D]
                         [--license SPDX] [--no-stubs] [--dry-run] [--now RFC3339]
  okf_migrate.py verify  --actor human:<id> [--now RFC3339] <page.md>...

convert is idempotent: pages that already have `type` are left alone. Requires Python 3.9+ and PyYAML.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    print("okf_migrate.py: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

TYPE_BY_DIR = {
    "summaries": "Reference",
    "entities": "Entity",
    "concepts": "Concept",
    "analyses": "Analysis",
    "decisions": "Decision Record",
    "runbooks": "Playbook",
}
STATUS_MAP = {
    "working": "draft",
    "proposed": "draft",
    "draft": "draft",
    "decided": None,
    "accepted": None,
    "stable": None,
    "superseded": "deprecated",
    "deprecated": "deprecated",
}
ORDER = ("type", "title", "description", "resource", "status", "superseded_by", "tags", "x-zvec-aliases",
         "generated", "verified", "stale_after", "sources", "usage_window")
LEGACY_LOG_RE = re.compile(r"^##\s+\[(\d{4}-\d{2}-\d{2})\]\s+([A-Za-z-]+)\s*\|\s*(.+?)\s*$")
OKF_LOG_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
LINK_RE = re.compile(r"(?<!!)(\[[^\]]*\]\(\s*<?)([^)\s>]+)(>?(?:\s+\"[^\"]*\")?\s*\))")
SCHEME_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")
ACTOR_RE = re.compile(r"^([^\s/:]+/\S+|[A-Za-z][A-Za-z0-9+.-]*:\S+)$")
FENCE_RE = re.compile(r"^\s{0,3}(```|~~~)")
HEADING_RE = re.compile(r"^(#{1,6})(\s+.*)$")
LOG_PREAMBLE = ("新しい日付が上。各 entry は **Ingest**、**Record**、**Crystallize**、**Lint** などの"
                "操作名の太字で始め、変更したページへリンクする。")


def utc_now(value: str | None) -> str:
    if value:
        return value
    return datetime.now(timezone.utc).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---- YAML emission ---------------------------------------------------------

def scalar(value: Any) -> str:
    if isinstance(value, bool) or value is None or isinstance(value, (int, float)):
        return json.dumps(value)
    text = str(value)
    try:
        if text == text.strip() and "\n" not in text and yaml.safe_load(f"k: {text}") == {"k": text}:
            return text
    except yaml.YAMLError:
        pass
    return json.dumps(text, ensure_ascii=False)


def quoted(value: Any) -> str:
    return json.dumps(str(value), ensure_ascii=False)


def emit_frontmatter(meta: dict[str, Any]) -> str:
    out: list[str] = []
    keys = [k for k in ORDER if k in meta] + [k for k in meta if k not in ORDER]
    for key in keys:
        value = meta[key]
        if key == "generated" and isinstance(value, dict):
            out.append(f"generated: {{ by: {quoted(value['by'])}, at: {quoted(value['at'])} }}")
        elif key == "verified" and isinstance(value, list):
            out.append("verified:")
            out += [f"  - {{ by: {quoted(v['by'])}, at: {quoted(v['at'])} }}" for v in value]
        elif key == "sources" and isinstance(value, list):
            out.append("sources:")
            for item in value:
                first = True
                for field in ("id", "resource", "title"):
                    if field in item:
                        out.append(f"  {'- ' if first else '  '}{field}: {scalar(item[field])}")
                        first = False
        elif key in ("tags", "x-zvec-aliases") and isinstance(value, list):
            out.append(f"{key}:")
            out += [f"  - {scalar(v)}" for v in value]
        elif isinstance(value, (dict, list)):
            out.append(yaml.safe_dump({key: value}, allow_unicode=True, sort_keys=False).rstrip("\n"))
        else:
            out.append(f"{key}: {scalar(value)}")
    return "\n".join(out)


# ---- documents -------------------------------------------------------------

def split(text: str) -> tuple[dict[str, Any] | None, str]:
    lines = text.lstrip("\ufeff").split("\n")
    if lines and lines[0].rstrip("\r") == "---":
        for index in range(1, len(lines)):
            if lines[index].rstrip("\r") == "---":
                meta = yaml.safe_load("\n".join(lines[1:index])) or {}
                return (meta if isinstance(meta, dict) else {}), "\n".join(lines[index + 1:])
    return None, text


def first_h1(path: Path) -> str | None:
    try:
        _, body = split(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, yaml.YAMLError):
        return None
    for line in body.split("\n"):
        match = re.match(r"^#\s+(.+?)\s*$", line)
        if match:
            return match.group(1)
    return None


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


class Migration:
    def __init__(self, bundle: Path, repo: Path, actor: str, now: str, stubs: bool, dry_run: bool):
        self.bundle = bundle.resolve()
        self.repo = repo.resolve()
        self.actor = actor
        self.now = now
        self.stubs = stubs
        self.dry_run = dry_run
        self.moves: dict[Path, Path] = {}
        self.notes: list[str] = []

    def rel(self, path: Path) -> str:
        try:
            return path.resolve().relative_to(self.bundle).as_posix()
        except ValueError:
            return os.path.relpath(path, self.repo)

    def inside(self, path: Path) -> bool:
        try:
            path.resolve().relative_to(self.bundle)
            return True
        except ValueError:
            return False

    def note(self, message: str) -> None:
        self.notes.append(message)

    def write(self, path: Path, text: str) -> None:
        if self.dry_run:
            print(f"would write {self.rel(path)}")
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"wrote {self.rel(path)}")

    def move_tree(self, src: Path, dst: Path) -> None:
        for path in sorted(src.rglob("*")):
            if path.is_file():
                target = dst / path.relative_to(src)
                self.moves[path.resolve()] = target.resolve()
                if self.dry_run:
                    print(f"would move {self.rel(path)} -> {self.rel(target)}")
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(path), str(target))
                    print(f"moved {self.rel(path)} -> {self.rel(target)}")
        if not self.dry_run:
            for directory in sorted((p for p in src.rglob("*") if p.is_dir()), reverse=True):
                directory.rmdir() if not any(directory.iterdir()) else None
            if src.is_dir() and not any(src.iterdir()):
                src.rmdir()

    # -- paths --

    def resolve_source(self, page: Path, value: str) -> str:
        if SCHEME_RE.match(value) or value.startswith("//"):
            return value
        clean = urllib.parse.unquote(value)
        candidates = [Path(os.path.normpath(page.parent / clean)), Path(os.path.normpath(self.repo / clean))]
        if clean.startswith("raw/"):
            rest = clean[len("raw/"):]
            candidates.insert(0, self.repo / "docs" / "raw" / rest)
            candidates.insert(0, self.bundle / "references" / rest)
        for candidate in candidates:
            candidate = self.moves.get(candidate.resolve(), candidate)
            if candidate.exists():
                if self.inside(candidate):
                    return "/" + self.rel(candidate)
                return os.path.relpath(candidate, page.parent)
        self.note(f"{self.rel(page)}: source {value!r} does not resolve; kept as written")
        return value

    def bundle_path(self, page: Path, value: str) -> str:
        if SCHEME_RE.match(value) or value.startswith("/"):
            return value
        candidate = Path(os.path.normpath(page.parent / urllib.parse.unquote(value)))
        candidate = self.moves.get(candidate.resolve(), candidate)
        return "/" + self.rel(candidate) if self.inside(candidate) else value

    def rewrite_links(self, page: Path, old_location: Path, body: str) -> str:
        def fix(match: re.Match) -> str:
            target = match.group(2)
            if SCHEME_RE.match(target) or target.startswith(("#", "/")):
                return match.group(0)
            path_part, sep, fragment = target.partition("#")
            if not path_part:
                return match.group(0)
            resolved = Path(os.path.normpath(old_location.parent / urllib.parse.unquote(path_part))).resolve()
            if resolved not in self.moves and old_location == page.resolve():
                return match.group(0)
            resolved = self.moves.get(resolved, resolved)
            new_target = os.path.relpath(resolved, page.parent)
            new_target = urllib.parse.quote(Path(new_target).as_posix()) + (sep + fragment if sep else "")
            return match.group(1) + new_target + match.group(3)

        out, fenced = [], False
        for line in body.split("\n"):
            if FENCE_RE.match(line):
                fenced = not fenced
            out.append(line if fenced else LINK_RE.sub(fix, line))
        return "\n".join(out)

    # -- pages --

    def sources_from(self, page: Path, value: Any) -> list[dict[str, str]]:
        items = value if isinstance(value, list) else [value]
        result, used = [], set()
        for raw in items:
            if not isinstance(raw, str) or not raw.strip():
                continue
            resource = self.resolve_source(page, raw.strip())
            if SCHEME_RE.match(resource):
                parsed = urllib.parse.urlparse(resource)
                parts = [p for p in parsed.path.split("/") if p]
                stem = Path(parts[-1]).stem if parts else ""
                base = slug(stem) if stem and len(stem) <= 32 and not re.fullmatch(r"[0-9a-f]{12,}", stem) else ""
                base = base or slug(parsed.netloc.split(".")[-2] if parsed.netloc.count(".") else parsed.netloc)
                title = None
            else:
                target = (self.bundle / resource.lstrip("/")) if resource.startswith("/") else (page.parent / resource)
                base = slug(target.name.replace(".md", "").replace(".", "-"))
                title = first_h1(target) if target.suffix == ".md" else None
            ident, n = base or "source", 2
            while ident in used:
                ident, n = f"{base}-{n}", n + 1
            used.add(ident)
            entry = {"id": ident, "resource": resource}
            if title:
                entry["title"] = title
            else:
                self.note(f"{self.rel(page)}: add a title to sources id {ident!r}")
            result.append(entry)
        return result

    def convert_body(self, page: Path, body: str, take_lead: bool) -> tuple[str | None, str | None, str]:
        lines = body.split("\n")
        title = description = None
        i = 0
        while i < len(lines) and not lines[i].strip():
            i += 1
        if i < len(lines) and re.match(r"^#\s+", lines[i]):
            title = re.sub(r"^#\s+", "", lines[i]).strip()
            del lines[i]
            while i < len(lines) and not lines[i].strip():
                i += 1
            end = i
            if i < len(lines) and lines[i].startswith(">"):
                while end < len(lines) and lines[end].startswith(">"):
                    end += 1
            elif (i < len(lines) and lines[i].strip() and not re.match(r"^(#|[-*+] |\d+\. |\||```|~~~|<)", lines[i])
                  and (i + 1 >= len(lines) or not lines[i + 1].strip())):
                end = i + 1
            lead = [line.lstrip(">").strip() for line in lines[i:end]]
            text = " ".join(" ".join(lead).split())
            sentences = len(re.findall(r"[.!?。](\s|$)", text))
            one_sentence = sentences == 1 or (sentences == 0 and end == i + 1)
            if lead and take_lead and one_sentence and not re.search(r"\]\(|\[\[|\[\^", text):
                del lines[i:end]
                description = re.sub(r"(\*\*|__)(.+?)\1", r"\2", text)
            elif lead and re.search(r"\]\(|\[\[|\[\^", text):
                self.note(f"{self.rel(page)}: the lead contains links; it stays in the body, so write a description by hand")
            elif lead and not one_sentence:
                self.note(f"{self.rel(page)}: the opening is longer than one sentence; it stays in the body")
            elif lead and not take_lead:
                self.note(f"{self.rel(page)}: description is already set; the opening stays in the body")
            elif not lead and i < len(lines) and lines[i].strip() and not lines[i].startswith("#"):
                self.note(f"{self.rel(page)}: the first paragraph is not a one-line lead; it stays in the body")
        text = "\n".join(lines).strip("\n")

        levels, fenced = [], False
        for line in text.split("\n"):
            if FENCE_RE.match(line):
                fenced = not fenced
            elif not fenced and HEADING_RE.match(line):
                levels.append(len(HEADING_RE.match(line).group(1)))
        shift = min(levels) - 1 if levels and min(levels) > 1 else 0
        if shift:
            out, fenced = [], False
            for line in text.split("\n"):
                if FENCE_RE.match(line):
                    fenced = not fenced
                match = None if fenced else HEADING_RE.match(line)
                out.append("#" * (len(match.group(1)) - shift) + match.group(2) if match else line)
            text = "\n".join(out)
        return title, description, text

    def convert_page(self, page: Path, old_location: Path) -> None:
        meta, body = split(page.read_text(encoding="utf-8"))
        meta = dict(meta or {})
        if isinstance(meta.get("type"), str) and meta["type"].strip():
            return
        rel = self.rel(page)
        top = rel.split("/")[0] if "/" in rel else ""
        new: dict[str, Any] = {"type": TYPE_BY_DIR.get(top, "Concept")}
        if top not in TYPE_BY_DIR:
            self.note(f"{rel}: no directory/type mapping; set type by hand (used 'Concept')")

        h1, lead, body = self.convert_body(page, self.rewrite_links(page, old_location, body), take_lead="description" not in meta)
        title = meta.pop("title", None) or h1
        description = meta.pop("description", None) or lead
        if title:
            new["title"] = title
        if description:
            new["description"] = description
            if len(re.findall(r"[.!?。](\s|$)", description)) > 1:
                self.note(f"{rel}: shorten description to one sentence")
        else:
            self.note(f"{rel}: no lead line found; write a one-sentence description")

        status = meta.pop("status", None)
        if status is not None:
            mapped = STATUS_MAP.get(str(status).strip(), str(status))
            if mapped not in (None, "draft", "deprecated"):
                self.note(f"{rel}: unknown status {status!r} kept; OKF readers treat it as not current")
            if mapped:
                new["status"] = mapped
        if "superseded_by" in meta:
            new["superseded_by"] = self.bundle_path(page, str(meta.pop("superseded_by")))
            new["status"] = "deprecated"

        aliases = meta.pop("aliases", None)
        if "x-zvec-aliases" in meta:
            aliases = meta.pop("x-zvec-aliases")
        if aliases:
            new["x-zvec-aliases"] = aliases if isinstance(aliases, list) else [aliases]
        if "tags" in meta:
            new["tags"] = meta.pop("tags")

        new["generated"] = {"by": self.actor, "at": self.now}
        history: list[dict[str, str]] = []
        date = meta.pop("date", None)
        deciders = meta.pop("deciders", None)
        if date and deciders:
            day = date.isoformat() if hasattr(date, "isoformat") else str(date)
            for decider in deciders if isinstance(deciders, list) else [deciders]:
                text = str(decider).strip()
                actor = text if ACTOR_RE.match(text) else f"human:{text}"
                history.append({"by": actor, "at": f"{day[:10]}T00:00:00Z"})
        elif date or deciders:
            self.note(f"{rel}: date or deciders alone cannot form a verified event; dropped")
        existing = meta.pop("verified", None)
        if existing:
            history = list(existing if isinstance(existing, list) else [existing]) + history
        if history:
            new["verified"] = history

        source = meta.pop("source", None)
        if "sources" in meta:
            new["sources"] = meta.pop("sources")
        elif source:
            new["sources"] = self.sources_from(page, source)

        for key, value in meta.items():
            new[key] = value
            self.note(f"{rel}: kept unknown key {key!r}")
        self.write(page, f"---\n{emit_frontmatter(new)}\n---\n\n{body.strip()}\n")

    def stub(self, old: Path, new: Path) -> None:
        meta, _ = split(new.read_text(encoding="utf-8")) if not self.dry_run else ({}, "")
        meta = meta or {}
        title = meta.get("title") or new.stem
        stub = {
            "type": meta.get("type", "Reference"),
            "title": title,
            "description": f"{self.rel(new)} へ移動した。",
            "status": "deprecated",
            "superseded_by": "/" + self.rel(new),
            "generated": {"by": self.actor, "at": self.now},
        }
        link = os.path.relpath(new, old.parent)
        self.write(old, f"---\n{emit_frontmatter(stub)}\n---\n\nこのページは移動した。[{title}]({link}) を参照する。\n")

    # -- log and root index --

    def convert_log(self, path: Path) -> None:
        text = path.read_text(encoding="utf-8")
        lines = text.split("\n")
        if not any(LEGACY_LOG_RE.match(line) for line in lines):
            return
        heading = next((l for l in lines if l.startswith("# ")), "# Wiki log")
        groups: dict[str, list[str]] = {}
        current: list[str] | None = None
        indent = ""
        for line in lines:
            legacy = LEGACY_LOG_RE.match(line)
            modern = OKF_LOG_RE.match(line)
            if legacy:
                day, kind, title = legacy.groups()
                current, indent = groups.setdefault(day, []), "  "
                current.append(f"* **{kind[:1].upper()}{kind[1:]}**: {title}")
            elif modern:
                current, indent = groups.setdefault(modern.group(1), []), ""
            elif line.startswith("## "):
                self.note(f"{self.rel(path)}: unrecognized log heading {line!r} dropped; restore it by hand")
                current = None
            elif current is not None and line.strip():
                current.append(indent + line)
        out = [heading, "", LOG_PREAMBLE, ""]
        for day in sorted(groups, reverse=True):
            out += [f"## {day}", ""] + groups[day] + [""]
        self.write(path, "\n".join(out).rstrip("\n") + "\n")

    def root_index(self, title: str | None, description: str | None, license_value: str | None) -> None:
        path = self.bundle / "index.md"
        text = path.read_text(encoding="utf-8") if path.is_file() else ""
        meta, body = split(text)
        meta = dict(meta or {})
        heading = next((re.sub(r"^#\s+", "", l).strip() for l in body.split("\n") if l.startswith("# ")), None)
        meta.setdefault("okf_version", "0.3")
        if title or "title" not in meta:
            meta["title"] = title or heading or "Wiki"
        if description:
            meta["description"] = description
        if "description" not in meta:
            self.note("index.md: pass --description with one sentence on the bundle scope")
        if license_value:
            meta["license"] = license_value
        lines = [f"okf_version: {quoted(meta.pop('okf_version'))}"] + [f"{k}: {scalar(v)}" for k, v in meta.items()]
        self.write(path, "---\n" + "\n".join(lines) + f"\n---\n\n{body.strip()}\n")

    def run(self, title: str | None, description: str | None, license_value: str | None) -> None:
        old_sources, summaries = self.bundle / "sources", self.bundle / "summaries"
        if old_sources.is_dir() and any(old_sources.rglob("*.md")):
            self.move_tree(old_sources, summaries)
        dest = self.repo / "docs" / "raw"
        for src in (self.repo / "raw", self.bundle / "references"):
            if src.is_dir() and src.resolve() != dest.resolve():
                self.move_tree(src, dest)
                self.note(f"{self.rel(src)}/ moved to docs/raw/, outside the bundle")

        reverse = {new: old for old, new in self.moves.items()}
        for page in sorted(self.bundle.rglob("*.md")):
            rel = self.rel(page)
            if page.name in ("index.md", "log.md") or rel.split("/")[0] == "references" or any(p.startswith(".") for p in rel.split("/")):
                continue
            if self.dry_run and page.resolve() in self.moves:
                continue
            self.convert_page(page, reverse.get(page.resolve(), page.resolve()))
        if self.stubs:
            for old, new in self.moves.items():
                if self.inside(old) and old.suffix == ".md" and not self.rel(old).startswith("references/"):
                    self.stub(old, new)
        if (self.bundle / "log.md").is_file():
            self.convert_log(self.bundle / "log.md")
        self.root_index(title, description, license_value)
        for message in self.notes:
            print(f"note: {message}")
        print("Next: run llm_wiki.py index, review the notes, then validate.py --strict and llm_wiki.py lint --strict.")


# ---- verify ----------------------------------------------------------------

def record_verification(path: Path, actor: str, at: str) -> None:
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    if not lines or lines[0] != "---" or "---" not in lines[1:]:
        raise SystemExit(f"{path}: no frontmatter")
    end = lines.index("---", 1)
    event = f"  - {{ by: {quoted(actor)}, at: {quoted(at)} }}"
    start = next((i for i in range(1, end) if re.match(r"^verified:", lines[i])), None)
    if start is None:
        anchor = next((i for i in range(1, end) if re.match(r"^(stale_after|sources|usage_window):", lines[i])), end)
        lines[anchor:anchor] = ["verified:", event]
    elif lines[start].strip() == "verified:":
        stop = start + 1
        while stop < end and (lines[stop].startswith(" ") or lines[stop].startswith("-")):
            stop += 1
        lines.insert(stop, event)
    else:
        old = lines[start].split(":", 1)[1].strip()
        lines[start:start + 1] = ["verified:", f"  - {old}", event]
    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"verified {path} by {actor}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Migrate a pre-OKF LLM wiki to OKF v0.3.")
    sub = parser.add_subparsers(dest="command", required=True)
    convert = sub.add_parser("convert", help="convert pages, log.md, and the root index.md")
    convert.add_argument("--bundle", type=Path, default=Path("docs/wiki"))
    convert.add_argument("--repo-root", type=Path, default=Path("."))
    convert.add_argument("--actor", required=True, help="generated.by actor, such as cursor/<model>")
    convert.add_argument("--title")
    convert.add_argument("--description")
    convert.add_argument("--license")
    convert.add_argument("--no-stubs", action="store_true", help="do not leave deprecated stubs at moved paths")
    convert.add_argument("--dry-run", action="store_true")
    convert.add_argument("--now", help="RFC 3339 date-time for generated.at")
    verify = sub.add_parser("verify", help="append a verified event after a person confirmed the pages")
    verify.add_argument("--actor", required=True, help="human:<id> stated by the reviewer")
    verify.add_argument("--now", help="RFC 3339 date-time for verified.at")
    verify.add_argument("pages", nargs="+", type=Path)
    args = parser.parse_args(argv)

    if not ACTOR_RE.match(args.actor):
        print(f"okf_migrate.py: {args.actor!r} is not an actor (<tool>/<model> or <scheme>:<id>)", file=sys.stderr)
        return 2
    now = utc_now(args.now)
    if args.command == "verify":
        for page in args.pages:
            record_verification(page, args.actor, now)
        return 0
    if not args.bundle.is_dir():
        print(f"okf_migrate.py: {args.bundle} is not a directory", file=sys.stderr)
        return 2
    Migration(args.bundle, args.repo_root, args.actor, now, not args.no_stubs, args.dry_run).run(
        args.title, args.description, args.license)
    return 0


if __name__ == "__main__":
    sys.exit(main())

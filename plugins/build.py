#!/usr/bin/env python3
"""Assemble a local, self-contained agent-tools plugin marketplace."""

import argparse
import io
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import tarfile
import tempfile
from urllib.request import urlopen


REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / "skills/zvec-llm-wiki"
REPO_URL = "https://github.com/okathira/agent-tools"
SCHEMAS = "https://agent-plugins.org/schemas/1.0.0"
OKF_SKILLS = ("okf-generate", "okf-consume")
LOCALES = {
    "zvec-llm-wiki": "Maintain and search an Open Knowledge Format wiki with zvec-grep.",
    "zvec-llm-wiki-ja": "zvec-grep で Open Knowledge Format の Wiki を検索・メンテナンスします。",
}


def read_pins():
    revisions = set()
    packages = set()
    for name in LOCALES:
        installer = (SOURCE / name / "install/install.sh").read_text(encoding="utf-8")
        match = re.search(r"^OKF_COMMIT=([0-9a-f]{40})$", installer, re.MULTILINE)
        if match is None:
            raise ValueError(f"Missing pinned OKF revision in {name} installer")
        revisions.add(match[1])
        bootstrap = (SOURCE / name / "scripts/zg-bootstrap.sh").read_text(encoding="utf-8")
        match = re.search(r'^ZG_PACKAGE="(@zvec/zvec-grep@[0-9]+\.[0-9]+\.[0-9]+)"$', bootstrap, re.MULTILINE)
        if match is None:
            raise ValueError(f"Missing pinned zvec-grep package in {name} bootstrap")
        packages.add(match[1])
    if len(revisions) != 1:
        raise ValueError("The standalone installers must pin the same OKF revision")
    if len(packages) != 1:
        raise ValueError("The bootstrap scripts must pin the same zvec-grep version")
    return revisions.pop(), packages.pop()


def unpack_okf(archive, revision, destination):
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as source:
        archive_root = f"open-knowledge-format-{revision}"
        license_text = source.extractfile(f"{archive_root}/LICENSE.md").read()
        for member in source:
            path = PurePosixPath(member.name)
            if not member.isfile() or len(path.parts) < 4:
                continue
            if path.parts[:2] != (archive_root, "skills") or path.parts[2] not in OKF_SKILLS:
                continue
            relative = path.parts[2:]
            if any(part == ".." or "\\" in part or ":" in part for part in relative):
                raise ValueError(f"Unexpected path in OKF archive: {member.name}")
            output = destination.joinpath(*relative)
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(source.extractfile(member).read())

        for name in OKF_SKILLS:
            skill = destination / name
            if not (skill / "SKILL.md").is_file():
                raise ValueError(f"Missing OKF dependency: {name}")
            (skill / "LICENSE.md").write_bytes(license_text)
            for notice in source.getmembers():
                if notice.isfile() and notice.name in (
                    f"{archive_root}/NOTICE",
                    f"{archive_root}/NOTICE.md",
                    f"{archive_root}/NOTICE.txt",
                ):
                    (skill / PurePosixPath(notice.name).name).write_bytes(source.extractfile(notice).read())


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build(destination, version):
    revision, package = read_pins()
    url = f"https://codeload.github.com/open-knowledge-format/open-knowledge-format/tar.gz/{revision}"
    with urlopen(url, timeout=60) as response:
        archive = response.read()

    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=destination.parent) as staging:
        stage = Path(staging) / "marketplace"
        dependencies = Path(staging) / "okf"
        unpack_okf(archive, revision, dependencies)

        codex_entries = []
        claude_entries = []
        for name, description in LOCALES.items():
            relative = f"./plugins/{name}"
            plugin = stage / relative
            skill = plugin / "skills" / name
            skill.mkdir(parents=True)
            shutil.copy2(SOURCE / name / "SKILL.md", skill)
            shutil.copy2(SOURCE / name / "LICENSE", skill)
            shutil.copy2(skill / "LICENSE", plugin)
            for directory in ("scripts", "references", "templates"):
                shutil.copytree(
                    SOURCE / name / directory,
                    skill / directory,
                    ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
                )
            for dependency in OKF_SKILLS:
                shutil.copytree(dependencies / dependency, plugin / "skills" / dependency)

            manifest = {
                "name": name,
                "description": description,
                "version": version,
                "author": {"name": "okathira"},
                "repository": REPO_URL,
                "license": "MIT",
            }
            server = {
                "type": "stdio",
                "command": "npx",
                "args": ["--yes", package, "--server", "--stdio", "--mcp-toolset", "agent"],
            }
            mcp = {"mcpServers": {"zvec_grep": server}}
            write_json(plugin / "plugin.json", {"$schema": f"{SCHEMAS}/plugin.schema.json", **manifest})
            write_json(plugin / "mcp.json", {"$schema": f"{SCHEMAS}/mcp.schema.json", **mcp})
            write_json(plugin / ".claude-plugin/plugin.json", manifest)
            write_json(plugin / ".mcp.json", mcp)
            codex_entries.append({
                "name": name,
                "source": {"source": "local", "path": relative},
                "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
                "category": "Productivity",
            })
            claude_entries.append({"name": name, "source": relative})

        write_json(stage / ".agents/plugins/marketplace.json", {
            "name": "agent-tools",
            "interface": {"displayName": "Agent Tools"},
            "plugins": codex_entries,
        })
        write_json(stage / ".claude-plugin/marketplace.json", {
            "name": "agent-tools",
            "owner": {"name": "okathira"},
            "plugins": claude_entries,
        })
        stage.rename(destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=REPO / "dist/agent-tools")
    parser.add_argument("--version", default="0.1.0")
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", args.version):
        parser.error("--version must use MAJOR.MINOR.PATCH")
    if args.output.exists():
        parser.error(f"Output already exists: {args.output}. Choose a different --output.")
    build(args.output.resolve(), args.version)
    print(args.output.resolve())


if __name__ == "__main__":
    main()

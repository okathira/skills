#!/usr/bin/env python3
"""Validate a generated distribution without loading any plugin client."""

import argparse
import json
from pathlib import Path
from urllib.request import urlopen

from jsonschema import Draft202012Validator
import yaml

from build import LOCALES, OKF_SKILLS, REPO, SCHEMAS, SOURCE, sync_zg, zg_server


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load_schema(kind):
    with urlopen(f"{SCHEMAS}/{kind}.schema.json", timeout=30) as response:
        return Draft202012Validator(json.load(response))


def validate_catalog(path, expected_paths, *, codex=False):
    catalog = load(path)
    require(catalog["name"] == "agent-tools", f"{path}: unexpected marketplace name")
    if codex:
        require(bool(catalog["interface"]["displayName"]), f"{path}: missing display name")
    else:
        require(bool(catalog["owner"]["name"]), f"{path}: missing owner")
    entries = {}
    for entry in catalog["plugins"]:
        name, source = entry["name"], entry["source"]
        require(name not in entries, f"{path}: duplicate plugin {name}")
        if codex:
            require(source["source"] == "local", f"{path}: expected a bundled plugin source")
            require(entry["policy"]["installation"] == "AVAILABLE", f"{path}: expected opt-in installation")
            source = source["path"]
        entries[name] = source
    require(entries == expected_paths, f"{path}: unexpected packages or relative paths")


def validate(dist, version):
    require({path.name for path in dist.iterdir()} == {
        ".agents", ".claude-plugin", ".cursor-plugin", "LICENSE", "README.md", "plugins",
    }, "Unexpected files at the distribution root")
    require(not any(path.is_symlink() for path in dist.rglob("*")), "Distribution contains a symlink")
    paths = {name: f"./plugins/{name}" for name in LOCALES}
    validate_catalog(dist / ".agents/plugins/marketplace.json", paths, codex=True)
    validate_catalog(dist / ".claude-plugin/marketplace.json", paths)
    validate_catalog(dist / ".cursor-plugin/marketplace.json", {name: path[2:] for name, path in paths.items()})
    require({path.name for path in (dist / "plugins").iterdir()} == set(LOCALES), "Unexpected plugin directories")
    plugin_schema, mcp_schema = load_schema("plugin"), load_schema("mcp")
    server = zg_server(sync_zg())
    license_text = (REPO / "LICENSE").read_bytes()
    require((dist / "LICENSE").read_bytes() == license_text, "Distribution license differs from source")
    for name, relative in paths.items():
        directory = dist / relative
        manifest = load(directory / "plugin.json")
        mcp = load(directory / "mcp.json")
        plugin_schema.validate(manifest)
        mcp_schema.validate(mcp)
        require(manifest["name"] == name and manifest["version"] == version, f"{name}: name/version mismatch")
        require(manifest["license"] == "MIT", f"{name}: expected MIT license")
        require(load(directory / ".claude-plugin/plugin.json") == {k: v for k, v in manifest.items() if k != "$schema"},
                f"{name}: Claude Code manifest differs from portable manifest")
        require(mcp["mcpServers"] == {"zvec_grep": server}, f"{name}: unexpected MCP configuration")
        require(load(directory / ".mcp.json") == {"mcpServers": mcp["mcpServers"]}, f"{name}: Claude Code MCP configuration differs")
        require((directory / "LICENSE").read_bytes() == license_text, f"{name}: plugin license differs from source")

        skills = directory / "skills"
        require({path.name for path in skills.iterdir()} == {name, *OKF_SKILLS}, f"{name}: unexpected bundled skills")
        for skill_name in (name, *OKF_SKILLS):
            content = (skills / skill_name / "SKILL.md").read_text(encoding="utf-8")
            parts = content.split("\n---\n", 1)
            require(len(parts) == 2 and parts[0].startswith("---\n"), f"{skill_name}: missing frontmatter")
            metadata = yaml.safe_load(parts[0][4:])
            require(metadata["name"] == skill_name and bool(metadata["description"]), f"{skill_name}: invalid skill metadata")
            license_file = "LICENSE" if skill_name == name else "LICENSE.md"
            require((skills / skill_name / license_file).stat().st_size > 0, f"{skill_name}: empty license")
        own = skills / name
        for path in (SOURCE / name).rglob("*"):
            relative_path = path.relative_to(SOURCE / name)
            included = relative_path.parts[0] in {"SKILL.md", "LICENSE", "scripts", "references", "templates"}
            if path.is_file() and included and "__pycache__" not in relative_path.parts and path.suffix != ".pyc":
                require((own / relative_path).read_bytes() == path.read_bytes(), f"{name}: bundled {relative_path} differs from source")
    print(f"Validated both locales for all three marketplaces ({version})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("distribution", type=Path)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    validate(args.distribution, args.version)

# Agent Skills catalog

A collection of [Agent Skills](https://agentskills.io/) for coding agents (Cursor, Codex, OpenCode, Claude Code).

## Language policy

- **English:** Default locale at the repo root (e.g. `zvec-llm-wiki/`). Folder name matches the skill `name` in `SKILL.md`. English is the default authoring language to reduce agent context load.
- **Japanese:** Locale variants under `ja/<skill-name>/` (e.g. `ja/zvec-llm-wiki/`). Each has its own `name` (e.g. `zvec-llm-wiki-ja`).
- **Independence:** Each locale folder is a complete package. Extracting that folder alone is enough to install and run it. File layout is one-to-one across locales (`SKILL.md`, `install/`, `scripts/`, `references/`, `templates/`). Do not share, symlink, or reach into another locale at runtime. Behavior and flags stay aligned; only natural language and `name` differ.
- **Maintenance:** When behavior changes, update every locale the same way. Pick one locale per install.

## Skills

| Skill | Description | 日本語 |
|-------|-------------|--------|
| [zvec-llm-wiki](zvec-llm-wiki/) | Maintain an LLM-facing wiki (`docs/wiki/`) with zvec-grep as the search layer | [ja/zvec-llm-wiki](ja/zvec-llm-wiki/) |

Each skill folder has an `install/` script that copies skill files (not the catalog README) into agent skill directories. Re-run `install.sh --force` after pulling catalog updates.

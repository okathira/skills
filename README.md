# Agent Skills catalog

A collection of [Agent Skills](https://agentskills.io/) for coding agents (Cursor, Codex, OpenCode, Claude Code).

## Skills

| Skill | Description |
|-------|-------------|
| [zvec-llm-wiki](zvec-llm-wiki/) | Maintain an LLM-facing wiki (`docs/wiki/`) with zvec-grep as the search layer |

Each skill lives in its own top-level folder. The folder name matches the skill `name` in `SKILL.md`. An `install/` script copies the skill files (not the catalog README) into agent skill directories. Re-run `install.sh --force` after pulling catalog updates.

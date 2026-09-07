# Agent Skills catalog

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-spec-111827?style=flat-square)](https://agentskills.io/) [![zvec-grep](https://img.shields.io/badge/search-zvec--grep-4f46e5?style=flat-square)](https://github.com/zvec-ai/zvec-grep)

Skills for coding agents — [Cursor](https://cursor.com/), Codex, OpenCode, and Claude Code.

[English](README.md) · [日本語](README.ja.md)

Each skill is a self-contained folder: install it, then agents follow `SKILL.md` while they work.

## Skills

| Skill | What it does | 日本語 |
|-------|----------------|--------|
| [zvec-llm-wiki](zvec-llm-wiki/) | Keep an LLM-facing wiki (`docs/wiki/`) in sync, with [zvec-grep](https://github.com/zvec-ai/zvec-grep) as the search layer | [ja/zvec-llm-wiki](ja/zvec-llm-wiki/) |

## Quick start

```bash
# English locale (default)
sh zvec-llm-wiki/install/install.sh

# Japanese locale
sh ja/zvec-llm-wiki/install/install.sh
```

Re-run with `--force` after pulling catalog updates. Restart the agent after install.

Install copies skill files into agent directories — not this catalog README. Next, bootstrap a *target* project with `scripts/zg-bootstrap.sh`. Full steps: [zvec-llm-wiki/README.md](zvec-llm-wiki/README.md) · [日本語](ja/zvec-llm-wiki/README.md).

## Language policy

English is the default locale so agents spend fewer tokens. Japanese is opt-in.

| | English | Japanese |
|---|---------|----------|
| **Skills** | Repo root, e.g. `zvec-llm-wiki/` — folder name matches `name` in `SKILL.md` | `ja/<skill-name>/`, e.g. `ja/zvec-llm-wiki/` — distinct `name` (`zvec-llm-wiki-ja`) |
| **This landing page** | [`README.md`](README.md) (GitHub default) | [`README.ja.md`](README.ja.md) |

- **Independence:** each skill locale folder is a complete package. Extracting that folder alone is enough to install and run it. Layout is one-to-one (`SKILL.md`, `install/`, `scripts/`, `references/`, `templates/`). No symlinks or cross-locale runtime deps. Behavior and flags stay aligned; only natural language and `name` differ.
- **Maintenance:** when behavior changes, update every locale in the same change. When catalog landing copy changes, update `README.md` and `README.ja.md` together (same sections, same facts). Pick one skill locale per install.

## Related

- [Agent Skills specification](https://agentskills.io/specification)
- [zvec-grep](https://github.com/zvec-ai/zvec-grep)
- [Karpathy — LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)

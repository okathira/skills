# Agent Skills catalog

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-spec-111827?style=flat-square)](https://agentskills.io/)

Skills for coding agents — [Cursor](https://cursor.com/), Codex, OpenCode, and Claude Code.

[English](README.md) · [日本語](README.ja.md)

A growing catalog of **independent** Agent Skills. Each skill is its own package: we add it here, install it into our agents, and dogfood it in this repository as well. After install, agents follow that skill's `SKILL.md`.

## Skills

| Skill | What it does | 日本語 |
|-------|----------------|--------|
| [zvec-llm-wiki](skills/zvec-llm-wiki/zvec-llm-wiki/) | Keep an LLM-facing wiki (`docs/wiki/`) in sync, with [zvec-grep](https://github.com/zvec-ai/zvec-grep) as the search layer | [zvec-llm-wiki-ja](skills/zvec-llm-wiki/zvec-llm-wiki-ja/) |

## Using a skill

Open the skill folder and follow **its** README. The usual first step is `install/install.sh`, then restart the agent. Re-run with `--force` after pulling catalog updates, if that skill's README says so.

Install copies skill files into agent directories — not this catalog README. Anything extra (bootstrap, tools, project wiring) is documented per skill.

## Language policy

English is the default locale so agents spend fewer tokens. Japanese is opt-in.

| | English | Japanese |
|---|---------|----------|
| **Skills** | `skills/<skill-name>/<skill-name>/` — folder name matches `name` in `SKILL.md` | `skills/<skill-name>/<skill-name>-ja/` — distinct `name` (suffix `-ja`) |
| **This landing page** | [`README.md`](README.md) (GitHub default) | [`README.ja.md`](README.ja.md) |

- **Independence:** each skill locale folder is a complete package. Extracting that folder alone is enough to install and run it. Locales of the same skill stay one-to-one; there are no symlinks or cross-locale runtime deps. Behavior and flags stay aligned; only natural language and `name` differ.
- **Maintenance:** when a skill's behavior changes, update every locale of that skill in the same change. When catalog landing copy changes, update `README.md` and `README.ja.md` together (same sections, same facts). Pick one locale per install.

## Related

- [Agent Skills specification](https://agentskills.io/specification)

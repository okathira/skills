# Agent Tools

[English](README.md) · [日本語](README.ja.md)

A catalog of standalone agent skills and plugins for searching and maintaining project wikis. The standalone skills target Codex, Claude Code, Cursor, and OpenCode.

## Skills

| Skill | What it does | 日本語 |
|-------|----------------|--------|
| [zvec-llm-wiki](skills/zvec-llm-wiki/zvec-llm-wiki/) | Compile sources, design knowledge, and project context into a living [OKF](https://github.com/open-knowledge-format/open-knowledge-format) wiki, using [zvec-grep](https://github.com/zvec-ai/zvec-grep) for staged retrieval | [zvec-llm-wiki-ja](skills/zvec-llm-wiki/zvec-llm-wiki-ja/) |
| [zvec-llm-wiki-okf-migrate](skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate/) | One-time migration of a pre-OKF zvec-llm-wiki wiki to OKF v0.3, ending with a human review | [zvec-llm-wiki-okf-migrate-ja](skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate-ja/) |

## Using a skill

Open the skill folder and follow its README. The default install location is `.agents/skills/` in the target repository. Use `install.sh --user` for a user-wide install.

## Plugins

`zvec-llm-wiki` bundles the wiki skill, its OKF companion skills, and zvec-grep MCP. Local installation for Codex, Claude Code, and Cursor is being prepared. See the [build and installation test instructions](plugins/README.md).

## MCP

The plugin uses the local stdio MCP server from [zvec-grep](https://github.com/zvec-ai/zvec-grep). For MCP-only setup, follow the [upstream agent instructions](https://zvec.org/en/docs/zvec-grep/agents/).

## Language policy

English is the default locale so agents spend fewer tokens. Japanese is opt-in.

| | English | Japanese |
|---|---------|----------|
| **Skills** | `skills/<skill-name>/<skill-name>/` — folder name matches `name` in `SKILL.md` | `skills/<skill-name>/<skill-name>-ja/` — distinct `name` (suffix `-ja`) |
| **This landing page** | [`README.md`](README.md) (GitHub default) | [`README.ja.md`](README.ja.md) |

- **Independence:** each skill locale folder is a complete package. Extracting that folder alone is enough to install and run it. Locales of the same skill stay one-to-one; there are no symlinks or cross-locale runtime deps. Behavior and flags stay aligned; only natural language and `name` differ.
- **Maintenance:** when a skill's behavior changes, update every locale of that skill in the same change. When catalog landing copy changes, update `README.md` and `README.ja.md` together (same sections, same facts). Pick one locale per install.

## License

The original skills and plugins are [MIT-licensed](LICENSE). Bundled third-party files retain their own licenses.

## Related

- [Agent Skills specification](https://agentskills.io/specification)

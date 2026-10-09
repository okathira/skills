---
status: decided
aliases:
  - sharp edges
  - pitfalls
  - dogfooding pitfalls
  - heading-only stubs
  - MCP zg PATH
  - stale skill install
  - project MCP
source:
  - ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
---
# Gotchas

> Sharp edges observed while dogfooding zvec-llm-wiki in this catalog.

## Do not commit `.zvec-grep/`

The bootstrap creates a local index under `.zvec-grep/`. It is not source of truth and must remain gitignored.

## Install and bootstrap are separate

- `install.sh` copies a skill package into an agent skill directory (default: `.agents/skills/` in the repo — commit it).
- `zg-bootstrap.sh` configures a target project wiki, hot memory, **project MCP**, and the index.

Running bootstrap from inside the skill package wires the wrong workspace.

Bootstrap does not copy `SKILL.md`. After catalog updates to the package, re-run `install.sh --force` and commit `.agents/skills/`, or the agent keeps a stale runtime copy.

## Do commit project skills and MCP

- `.agents/skills/<name>/` — runtime skill the agent loads (default install).
- `.cursor/mcp.json` — Cursor project MCP ([Cursor MCP](https://cursor.com/docs/mcp)).
- `.mcp.json` — Claude Code project MCP (repo root).

User-level `~/.agents/skills/` and `~/.cursor/mcp.json` are not shared with Cloud Agents or teammates.

## User-level `zg install` vs project MCP

`zg install --target cursor` writes `~/.cursor/mcp.json` with `command: zg` and does not install the npm package. Prefer committed project MCP with `npx @zvec/zvec-grep` from bootstrap. Re-running that upsert keeps compatible fields such as `env` and refuses to merge an existing HTTP `zvec_grep` entry into the stdio command. Use `zg install --target codex` (etc.) only when you need that agent's **user-level** config. Bootstrap's `--target` does the same install, and when `zg` is not already on PATH it installs `@zvec/zvec-grep` globally and checks that `zg` launches first. A one-shot `npx` install does not leave a `zg` binary for those user-level entries.

## Do not create heading-only stubs

Heading-only pages rank in semantic search but provide no evidence. The new scaffold creates category directories plus useful `index.md` and `log.md`, not empty topic pages.

## Japanese retrieval needs aliases

Do not assume BM25 tokenization handles Japanese proper nouns. On a Japanese wiki, keep Kanji, Kana, and English aliases in frontmatter `aliases` on the owning page and use exact rg when a name is known.

This catalog wiki is English. Prefer English ubiquitous-language aliases; see [Conventions](conventions.md).

## Related

- [Skill setup runbook](../runbooks/skill-setup.md)
- [ADR-0004](../decisions/ADR-0004-project-skill-install.md)
- [Conventions](conventions.md)

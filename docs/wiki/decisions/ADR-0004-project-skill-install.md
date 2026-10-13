---
status: accepted
date: 2026-10-08
deciders:
  - owner
aliases:
  - ADR-0004
  - project skill install
  - project MCP
  - committed agent skills
source:
  - ../../../skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh
  - ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
  - https://agentskills.io/
  - https://cursor.com/docs/skills
  - https://cursor.com/docs/mcp
---

# ADR-0004: Project-scoped skills and MCP

Skill installs and zvec-grep MCP wiring default to the **repository** so teammates and Cloud Agents share the same revision without reading a developer home directory.

## Context

Agent Skills clients converge on cross-client discovery under `.agents/skills/` at project scope, with project skills overriding user skills ([Agent Skills client guidance](https://agentskills.io/)). Cursor documents the same paths and states that unsynced user-level skills are **not** copied to Cloud Agents — project skills in the repo are ([Cursor skills](https://cursor.com/docs/skills)).

`install.sh` previously defaulted to `~/.agents/skills/`, which drifted from catalog updates ([gotchas](../concepts/gotchas.md)) and did not reach remote workers.

For MCP, Cursor and Claude Code recommend **committing** project configuration (`.cursor/mcp.json`, root `.mcp.json`) with secrets referenced via environment variables, not literals ([Cursor MCP](https://cursor.com/docs/mcp)). `zg install --target cursor` writes user-level config with `command: zg`, which requires a global binary and is a poor team default.

## Decision

1. **`install.sh` default** — copy the skill package to `.agents/skills/<name>/` in the current repository. Use `--user` for `~/.agents/skills/`. Use `--claude` when Claude Code should also read `.claude/skills/` (native path; not interchangeable with `.agents/skills/` for Claude-only setups).
2. **Commit project installs** — dogfooding and team repos check in `.agents/skills/` (runtime copy) alongside the distributable package under `skills/<name>/`.
3. **Bootstrap project MCP** — `zg-bootstrap.sh` upserts `.cursor/mcp.json` and `.mcp.json` with an `npx --yes @zvec/zvec-grep server --stdio` entry so MCP works without a global `zg`. Commit these files.
4. **User-level `zg install`** — optional; pass `--target codex`, `opencode`, etc. Bootstrap skips `cursor` and `claude` when targeting user install because project files own those clients.

## Why (rationale)

- **Reproducibility**: clone → same skill text and MCP wiring.
- **Cloud Agents**: project files travel with the repo; home-directory skills do not.
- **Separation**: package source (`skills/...`) vs agent runtime (`.agents/skills/`) stays explicit per [catalog layout](../concepts/catalog-layout.md).

## Alternatives considered

- **Default `--user` with docs-only project recommendation** — Rejected: easy to forget `--project`; Cloud Agents remain blind.
- **Only `.cursor/skills/`** — Rejected: Codex/OpenCode/Cursor all document `.agents/skills/` as the cross-client convention; this catalog targets multiple clients.
- **Global `zg` only for MCP** — Rejected: breaks fresh clones and nvm switches; npx in committed MCP matches Cursor MCP guidance for portable commands.

## Consequences

- After changing skill behavior, re-run `install.sh --force` and commit `.agents/skills/` in the same change.
- Developers may still run `zg install` for personal Codex/OpenCode config; it must not replace committed Cursor/Claude project MCP without review. Bootstrap `--target` installs a persistent `zg` when the binary is missing, because those user-level entries launch `zg` rather than `npx`.
- Project MCP re-runs keep compatible `zvec_grep` fields such as `env` and refuse an existing HTTP transport instead of merging it into the stdio entry.
- `.zvec-grep/` remains gitignored; indexes are local.

## References

- [Skill setup runbook](../runbooks/skill-setup.md)
- [Gotchas](../concepts/gotchas.md)
- [ADR-0002](ADR-0002-catalog-skills-directory.md)

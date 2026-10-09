---
status: decided
aliases:
  - skill setup
  - bootstrap runbook
  - zg-bootstrap
  - install.sh
  - incremental zg index
  - project MCP
source:
  - ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
---

# Runbook: Install skill and bootstrap this repo

> Verified setup steps for the Agent Skills catalog (re-dogfooded 2026-10-08).

## Prerequisites

- Node.js 22+; this catalog pins dogfood Node in the repo-root `.node-version` (version managers that read that file pick it up automatically).
- POSIX shell (Git Bash on Windows)

## 1. Install the skill (per repo; commit the result)

From the **target project root** (for this catalog, the repo root):

```bash
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --force
```

Installs to `.agents/skills/zvec-llm-wiki`. **Commit** `.agents/skills/` so teammates and Cloud Agents load the same skill revision. Restart the agent after install.

- **User-wide** (all repos on one machine): add `--user` → `~/.agents/skills/`.
- **Claude Code native path**: add `--claude` → `.claude/skills/` (same scope as default or `--user`).

Japanese locale:

```bash
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --force
```

## 2. Bootstrap the target repo (once per project)

From the **project root** (not the skill package folder):

```bash
bash skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
```

Creates or updates:

- `docs/wiki/`, `AGENTS.md`, `.zvec-grep/` (local index; gitignored)
- **Committed MCP**: `.cursor/mcp.json` (Cursor) and `.mcp.json` (Claude Code) with `npx @zvec/zvec-grep` stdio — no global `zg` required for agents
- First or incremental `zg index` with `local/potion-multilingual-128m` on a new wiki

Optional user-level agents (Codex, OpenCode, …):

```bash
bash skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --target codex opencode
```

Bootstrap does **not** run user-level `zg install` when `--target` is omitted. Cursor and Claude use the committed project MCP files instead of `~/.cursor/mcp.json` / user Claude config. Re-running the project upsert updates the `zvec_grep` command and args, keeps compatible fields such as `env`, and stops if that server is already an HTTP transport. When `--target` names a user-level agent and `zg` is not on PATH, bootstrap installs `@zvec/zvec-grep` globally and checks that `zg` launches before `zg install` writes `command: zg`.

Supported embeddings are whatever the installed zg lists — do not copy a model table into this wiki. Inspect the catalog:

```bash
zg help models
npx --yes @zvec/zvec-grep help models   # if zg is not on PATH
```

**Idempotent**: second run does not rebuild wiki scaffold or drop index; runs incremental `zg index`.

**Git**: add `.zvec-grep/` to `.gitignore` (local index only). Commit `.agents/skills/`, `.cursor/mcp.json`, and `.mcp.json`.

## 3. After wiki edits

```bash
npx --yes @zvec/zvec-grep index    # or `zg index` if on PATH
npx --yes @zvec/zvec-grep status --check-ready
```

Restart the agent after first MCP configuration.

## Verification

- `.agents/skills/zvec-llm-wiki/SKILL.md` matches `skills/zvec-llm-wiki/zvec-llm-wiki/SKILL.md` (same for `references/` and `templates/`).
- `.cursor/mcp.json` and `.mcp.json` contain a `zvec_grep` server using `npx` and `@zvec/zvec-grep`.
- `AGENTS.md` still contains the `ZVEC_LLM_WIKI` hot block; existing `docs/wiki/` pages were not replaced by the scaffold.
- `zg status --check-ready` succeeds after incremental `zg index`.

## Troubleshooting

| Issue | Action |
|-------|--------|
| MCP `zvec_grep` missing in Cursor | Confirm `.cursor/mcp.json` is committed; restart Cursor. Approve the server if prompted. |
| MCP works locally but not on a fresh clone | Install skill (step 1) and bootstrap (step 2); ensure Node 22+ and network for first `npx`. |
| `zg` not on PATH for CLI | Use `npx --yes @zvec/zvec-grep …` or `npm install -g @zvec/zvec-grep`. MCP does not require global `zg` when project MCP uses `npx`. |
| Query misses a new wiki page | Confirm it is registered in `index.md`, then run incremental `zg index` |
| Agent follows old frontmatter or loop rules | Catalog `SKILL.md` changed but `.agents/skills/` did not. Re-run step 1 with `--force`, commit, and restart the agent. |

## Related

- [ADR-0004](../decisions/ADR-0004-project-skill-install.md)
- [Catalog layout](../concepts/catalog-layout.md)
- [Conventions](../concepts/conventions.md)
- [Gotchas](../concepts/gotchas.md)

# zvec-llm-wiki

An [Agent Skill](https://agentskills.io/) that keeps a project's **LLM-facing wiki** (`docs/wiki/`) in sync while coding, using **zvec-grep (`zg`)** as the shared search layer.

Core loop: **Read (zg) → Work → Verify with human → Record (edit wiki) → Re-index (`zg index`)**.

## Layout

```
zvec-llm-wiki/
  README.md                       # this file (catalog / humans)
  install/install.sh              # copy the skill into agent skill directories
  SKILL.md                        # agent entry point
  scripts/zg-bootstrap.sh         # bootstrap zg + docs/wiki in a target repo
  references/
  templates/
```

The skill `name` is `zvec-llm-wiki` and matches this folder. `install.sh` copies `SKILL.md`, `scripts/`, `references/`, and `templates/` only — not this README or `install/`.

Two setup steps — do not confuse them:

1. **Install the skill** (once per machine or per repo) — `install/install.sh`
2. **Bootstrap a target repo** (once per project) — `scripts/zg-bootstrap.sh`

## 1. Install the skill

Copies the skill into `.agents/skills/zvec-llm-wiki` (Cursor, Codex, OpenCode) or optionally `.claude/skills/` (Claude Code).

```bash
# User-wide (default) — Cursor / Codex / OpenCode
sh zvec-llm-wiki/install/install.sh

# Project-scoped — team repos, Cloud Agents
cd your-repo
sh /path/to/skills/zvec-llm-wiki/install/install.sh --project

# Also install for Claude Code
sh zvec-llm-wiki/install/install.sh --claude
sh zvec-llm-wiki/install/install.sh --project --claude
```

Use `--force` to overwrite an existing install. On Windows, run from Git Bash or another POSIX shell.

Restart your agent after installing.

## 2. Bootstrap a target repo

Run from the **project** you are working in (not from this catalog). Requires **Node.js 22+** — zvec-grep has no standalone binary.

```bash
cd your-repo

# Auto-detect installed agents (Codex, Cursor, OpenCode, Claude, …)
bash /path/to/skills/zvec-llm-wiki/scripts/zg-bootstrap.sh

# Or pick agents explicitly
bash /path/to/skills/zvec-llm-wiki/scripts/zg-bootstrap.sh --target cursor codex opencode
```

This resolves `zg` (existing install → `npx` → optional global `npm install -g`), wires MCP via `zg install`, scaffolds `docs/wiki/`, and builds the first index. Restart the agent after MCP configuration.

## Skill package contents

| Path | Purpose |
|------|---------|
| `SKILL.md` | Entry point: read/record loop, structure, guardrails |
| `references/zvec-grep-cheatsheet.md` | Full `zg` flags, MCP tool names, index management |
| `references/wiki-workflow.md` | Governance invariants, what-vs-why, hot/cold memory |
| `scripts/zg-bootstrap.sh` | Idempotent, non-destructive repo setup |
| `templates/adr.md` | Architecture Decision Record template |
| `templates/wiki-page.md` | Generic wiki page template |

## Design sources

- [zvec-grep](https://github.com/zvec-ai/zvec-grep) docs (search routes, index management, MCP, freshness)
- Living-docs practices: docs-first, one-home-per-fact, human-as-checkpoint, what-vs-why, hot/cold memory
- [Agent Skills](https://agentskills.io/specification) authoring (concise SKILL.md, progressive disclosure)

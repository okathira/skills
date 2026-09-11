# zvec-llm-wiki

An [Agent Skill](https://agentskills.io/) for ingesting, querying, linting, recording, and
crystallizing a project's **LLM-facing wiki** (`docs/wiki/`) with **zvec-grep (`zg`)**.

Core loop: **Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg index`**.
Writes are involved: show the page plan, then edit unless the user stops. Destructive index
operations remain approval-gated.

The default Karpathy-style wiki contains `index.md`, `log.md`, `sources/`, `entities/`, `concepts/`,
and `analyses/`. `decisions/` and `runbooks/` are optional coding overlays; project-root `raw/` is
optional and immutable. Query order is index first, wiki-scoped zg hybrid, rg for exact names, then
wider raw or code scope only when needed. qmd is not used.

## Layout

```
skills/zvec-llm-wiki/zvec-llm-wiki/
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
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh

# Project-scoped — team repos, Cloud Agents
cd your-repo
sh /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --project

# Also install for Claude Code
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --claude
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --project --claude
```

Use `--force` to overwrite an existing install. After updating this catalog, re-run with
`--force` so `~/.agents/skills/` (or `.agents/skills/` in a project) picks up changes.

On Windows, run from Git Bash or another POSIX shell.

Restart your agent after installing.

## 2. Bootstrap a target repo

Run from the **project** you are working in (not from this catalog). Requires **Node.js 22+** — zvec-grep has no standalone binary.

```bash
cd your-repo

# Auto-detect installed agents (Codex, Cursor, OpenCode, Claude, …)
bash /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh

# Or pick agents explicitly (see: zg help install)
bash /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --target cursor codex opencode

# Override the default wiki embedding
bash /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --embedding local/potion-multilingual-128m
```

Supported embedding models come from the installed zg catalog. List them there (this README does
not duplicate the table):

```bash
zg help models
# if zg is not on PATH:
npx --yes @zvec/zvec-grep help models
```

If `zg` is missing, the script runs `npm install -g @zvec/zvec-grep` before `zg install`.
MCP stdio config always launches the `zg` binary (`zg install` does not install the npm package),
so an npx-only bootstrap would leave agents with `command not found: zg`. For a new wiki it creates
a useful registry, operation log, and category directories without empty stubs; an existing wiki is
untouched. It then upserts `AGENTS.md` hot memory and builds the first index with zg default file
discovery. Restart the agent after MCP configuration.

## Skill package contents

| Path | Purpose |
|------|---------|
| `SKILL.md` | Entry point: operations, wiki layers, staged zg routing |
| `references/wiki-workflow.md` | Page/log contracts, ingest depth, lint rules, embeddings |
| `scripts/zg-bootstrap.sh` | Idempotent, non-destructive repo setup |
| `templates/wiki-page.md` | Source, entity, concept, and analysis page template |
| `templates/adr.md` | Architecture Decision Record template (coding overlay) |
| `templates/runbook.md` | Procedure template (coding overlay) |

## Design sources

- [zvec-grep](https://github.com/zvec-ai/zvec-grep) — zg behavior and CLI reference (`zg help`)
- [Karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — persistent compiled wiki, categories, operations, index-first query, and log
- [zvec-grep open-source post](https://zvec.org/en/blog/2026-08-28-zvec-grep-open-source/) — one staged engine for semantic/hybrid discovery and rg verification
- [Agent Skills](https://agentskills.io/specification) authoring (concise SKILL.md, progressive disclosure)

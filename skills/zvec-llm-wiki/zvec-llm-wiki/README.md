# zvec-llm-wiki

An [Agent Skill](https://agentskills.io/) for ingesting, querying, linting, recording, and
crystallizing a project's **LLM-facing wiki** (`docs/wiki/`) with **zvec-grep (`zg`)**.

Core loop: **Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg.sh --index`**.
Writes are involved: show the page plan, then edit unless the user stops. Destructive index
operations remain approval-gated.

The wiki is an [Open Knowledge Format (OKF) v0.3](https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md)
bundle. The official `okf-generate` and `okf-consume` skills own the format, validation, and trust
rules; this skill adds Karpathy operations, staged zg retrieval, and `x-zvec-*` extensions.

The default Karpathy-style wiki contains `index.md`, `log.md`, `summaries/`, `entities/`, `concepts/`,
and `analyses/`, each mapped to an OKF `type`. `decisions/` and `runbooks/` are optional coding
overlays. Optional immutable imports live in `docs/raw/`, outside the bundle. Query order is indexes
first, wiki-scoped zg hybrid, rg for exact names, then wider scope only when needed. qmd is not used. Wikis written
before OKF are migrated with the separate [`zvec-llm-wiki-okf-migrate`](../../zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate/) skill.

## Layout

```
skills/zvec-llm-wiki/zvec-llm-wiki/
  README.md                       # this file (catalog / humans)
  install/install.sh              # copy the skill into agent skill directories
  SKILL.md                        # agent entry point
  scripts/zg-bootstrap.sh         # bootstrap zg + docs/wiki in a target repo
  scripts/llm_wiki.py             # generate index.md files and lint llm-wiki rules
  references/
  templates/
```

The skill `name` is `zvec-llm-wiki` and matches this folder. `install.sh` copies `SKILL.md`, `scripts/`, `references/`, and `templates/` only — not this README or `install/`. It also fetches the official `okf-generate` and `okf-consume` skills from the OKF repository at a pinned commit into the same skills directory (Apache-2.0; `LICENSE.md` is copied). Pass `--no-okf` to skip them.

Two setup steps — do not confuse them:

1. **Install the skill** (per repo; commit `.agents/skills/`) — `install/install.sh`
2. **Bootstrap a target repo** (once per project) — `scripts/zg-bootstrap.sh`

## 1. Install the skill

Copies the skill into `.agents/skills/zvec-llm-wiki` (Cursor, Codex, OpenCode) by default, or optionally `.claude/skills/` (Claude Code). **Commit** the project install so teammates and Cloud Agents share the same revision.

```bash
cd your-repo

# Project (default) — team repos, Cloud Agents
sh /path/to/agent-tools/skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh

# User-wide on one machine
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --user

# Also install for Claude Code (native path)
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --claude
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --user --claude
```

Use `--force` to overwrite an existing install. After updating this catalog, re-run with
`--force` and commit `.agents/skills/` (or refresh `~/.agents/skills/` when using `--user`).

On Windows, run from Git Bash or another POSIX shell.

Restart your agent after installing.

## 2. Bootstrap a target repo

Run from the **project** you are working in (not from this catalog). Requires **Node.js 22+** — zvec-grep has no standalone binary — and **Python 3.9+ with PyYAML** (`pip install pyyaml`) for `llm_wiki.py` and `validate.py`.

```bash
cd your-repo

# Auto-detect installed agents (Codex, Cursor, OpenCode, Claude, …)
bash /path/to/agent-tools/skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh

# Or pick agents explicitly (see: zg.sh --help install)
bash /path/to/agent-tools/skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --target cursor codex opencode

# Override the default wiki embedding
bash /path/to/agent-tools/skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --embedding local/potion-multilingual-128m
```

Supported embedding models come from the installed zg catalog. List them there (this README does
not duplicate the table):

```bash
bash /path/to/installed-skill/scripts/zg.sh --help models
```

Bootstrap upserts **committed** `.cursor/mcp.json` and `.mcp.json` with an `npx` launcher for a pinned zvec-grep version
so agents do not require a global `zg`. A re-run updates that server's command and args, keeps
compatible fields such as `env`, and refuses to merge an existing HTTP transport.
For index and search commands, run the bundled `scripts/zg.sh` from the target repository. It uses a matching `zg` on PATH or runs the pinned package through `npx`.
Pass `--target codex` (etc.) for optional user-level integration. If `zg` is missing, bootstrap installs the pinned package via npm. A different version already on PATH must be updated before user-level setup.
Cursor/Claude use the project MCP files.
For a new wiki it creates
an OKF root `index.md`, an operation log, and category directories without empty stubs; an existing
wiki is untouched (a pre-OKF wiki gets a migration warning). It then upserts `AGENTS.md` hot memory and builds the first index with zg default file
discovery. Restart the agent after MCP configuration.

## Skill package contents

| Path | Purpose |
|------|---------|
| `SKILL.md` | Entry point: operations, wiki layers, staged zg routing |
| `references/wiki-workflow.md` | Page/log contracts, ingest depth, lint rules, embeddings |
| `scripts/zg-bootstrap.sh` | Idempotent, non-destructive repo setup |
| `scripts/llm_wiki.py` | `index` regenerates directory indexes; `lint` checks the llm-wiki layer |
| `templates/wiki-page.md` | Summary, entity, concept, and analysis page template |
| `templates/adr.md` | Architecture Decision Record template (coding overlay) |
| `templates/runbook.md` | Procedure template (coding overlay) |

## Design sources

- [Open Knowledge Format](https://github.com/open-knowledge-format/open-knowledge-format) — bundle format, `okf-generate` / `okf-consume` skills, and `validate.py`
- [zvec-grep](https://github.com/zvec-ai/zvec-grep) — zg behavior and CLI reference (`zg.sh --help`)
- [Karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — persistent compiled wiki, categories, operations, index-first query, and log
- [zvec-grep open-source post](https://zvec.org/en/blog/2026-08-28-zvec-grep-open-source/) — one staged engine for semantic/hybrid discovery and rg verification
- [Agent Skills](https://agentskills.io/specification) authoring (concise SKILL.md, progressive disclosure)

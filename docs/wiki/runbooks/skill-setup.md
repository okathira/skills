---
type: Playbook
title: "Runbook: Install skill and bootstrap this repo"
description: Install the skill and its OKF sibling skills, bootstrap this repo, and refresh indexes after wiki edits.
x-zvec-aliases:
  - skill setup
  - bootstrap runbook
  - zg-bootstrap
  - install.sh
  - incremental zg --index
  - project MCP
generated: { by: "codex/gpt-6.2-sol", at: "2026-11-21T14:47:14Z" }
verified:
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
sources:
  - id: npm-release
    resource: https://registry.npmjs.org/npm/12.2.3
    title: npm 12.2.3 package metadata and Node.js compatibility
  - id: node-release-index
    resource: https://nodejs.org/dist/index.json
    title: Node.js release index with bundled npm versions
  - id: zg-bootstrap-sh
    resource: ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
    title: zvec-llm-wiki bootstrap script
  - id: install-sh
    resource: ../../../skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh
    title: zvec-llm-wiki install script
---

# Prerequisites

- Node.js 22+ for installation into other projects. For development and dogfooding in this repository, select the exact release in `.node-version` and install the version in `.npm-version`. For example, with the pinned Node active in your version manager, run `npm install -g npm@12.2.3` and check `npm --version`. CI installs npm into a temporary prefix, adds it to PATH, and verifies the pin.[^node-release-index][^npm-release]
- Python 3.9+ with PyYAML (`pip3 install --user pyyaml`) for `llm_wiki.py` and `validate.py`
- POSIX shell (Git Bash on Windows), plus `curl` and `tar` to fetch the OKF skills

# 1. Install the skill (per repo; commit the result)

From the **target project root** (for this catalog, the repo root):

```bash
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --force
```

Installs to `.agents/skills/zvec-llm-wiki` and fetches `okf-generate` and `okf-consume` from the pinned OKF commit into `.agents/skills/` (existing copies are kept unless `--force`; `--no-okf` skips them).[^install-sh] **Commit** `.agents/skills/` so teammates and Cloud Agents load the same skill revision. Restart the agent after install.

The one-time migration skill installs the same way: `sh skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate/install/install.sh --force`.

- **User-wide** (all repos on one machine): add `--user` → `~/.agents/skills/`.
- **Claude Code native path**: add `--claude` → `.claude/skills/` (same scope as default or `--user`).

Japanese locale:

```bash
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --force
```

# 2. Bootstrap the target repo (once per project)

From the **project root** (not the skill package folder):

```bash
bash skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
```

Creates or updates:

- `docs/wiki/` as an OKF bundle (only when absent; a pre-OKF wiki gets a migration warning), `AGENTS.md`, `.zvec-grep/` (local index; gitignored)[^zg-bootstrap-sh]
- **Committed MCP**: `.cursor/mcp.json` (Cursor) and `.mcp.json` (Claude Code) with an `npx` launcher for the pinned zvec-grep package — no global `zg` required for agents
- First or incremental `zg.sh --index` with `local/potion-multilingual-128m` on a new wiki

Optional user-level agents (Codex, OpenCode, …):

```bash
bash skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --target codex opencode
```

Bootstrap does **not** run user-level `zg --install` when `--target` is omitted. Cursor and Claude use the committed project MCP files instead of `~/.cursor/mcp.json` / user Claude config. Re-running the project upsert updates the `zvec_grep` command and args, keeps compatible fields such as `env`, and stops if that server is already an HTTP transport. When `--target` names a user-level agent and `zg` is not on PATH, bootstrap installs `@zvec/zvec-grep` globally at the pin and checks its version before writing user-level MCP settings. A different version already on PATH must be updated before user-level setup.

Supported embeddings are whatever the installed zg lists — do not copy a model table into this wiki. Inspect the catalog:

```bash
bash .agents/skills/zvec-llm-wiki/scripts/zg.sh --help models
npx --yes @zvec/zvec-grep help models   ```

**Idempotent**: second run does not rebuild wiki scaffold or drop index; runs incremental `zg.sh --index`.

**Git**: add `.zvec-grep/` to `.gitignore` (local index only). Commit `.agents/skills/`, `.cursor/mcp.json`, and `.mcp.json`.

# 3. After wiki edits

```bash
python3 .agents/skills/zvec-llm-wiki/scripts/llm_wiki.py index
python3 .agents/skills/zvec-llm-wiki/scripts/llm_wiki.py lint --strict
bash .agents/skills/zvec-llm-wiki/scripts/zg.sh --index
npx --yes @zvec/zvec-grep status --check-ready
```

Restart the agent after first MCP configuration. The project MCP launchers and the bundled `scripts/zg.sh` use the version in `plugins/zvec-grep.version`. Run the bundled launcher from the target repository. It reuses a matching global binary and otherwise invokes the pinned npm package. The npm launcher explicitly permits the zvec-grep package's lifecycle scripts. The index is local to each checkout or worktree. In a new session, open the intended worktree with Node/npm on PATH and check that the client connects to `zvec_grep`. See the [plugin test guide](../../../plugins/README.md) for the separate plugin installation path.

# Verification

- `.agents/skills/zvec-llm-wiki/SKILL.md` matches `skills/zvec-llm-wiki/zvec-llm-wiki/SKILL.md` (same for `references/` and `templates/`).
- `.cursor/mcp.json` and `.mcp.json` contain a `zvec_grep` server using `npx` and `@zvec/zvec-grep`.
- `AGENTS.md` still contains the `ZVEC_LLM_WIKI` hot block; existing `docs/wiki/` pages were not replaced by the scaffold.
- `.agents/skills/okf-generate/LICENSE.md` and `.agents/skills/okf-consume/LICENSE.md` exist.
- `llm_wiki.py lint --strict` exits 0; it also runs `okf-generate`'s `validate.py`.
- `zg.sh --status --check-ready` succeeds after incremental `zg.sh --index`.

An index created by zg 0.2.2 was reported as needing a rebuild by 0.3.1. If the pinned CLI reports `rebuild required`, confirm before running the bundled launcher with `--index --rebuild`. The bootstrap leaves that decision to the user.

# Troubleshooting

| Issue | Action |
|-------|--------|
| MCP `zvec_grep` missing in Cursor | Confirm `.cursor/mcp.json` is committed; restart Cursor. Approve the server if prompted. |
| MCP works locally but not on a fresh clone | Install skill (step 1) and bootstrap (step 2); ensure Node 22+ and network for first `npx`. |
| `zg` not on PATH for CLI | Use `npx --yes @zvec/zvec-grep …` or `npm install -g @zvec/zvec-grep`. MCP does not require global `zg` when project MCP uses `npx`. |
| Query misses a new wiki page | Run `llm_wiki.py index` so its directory index lists it, then run incremental `zg.sh --index` |
| `PyYAML is required` from a wiki script | Install it with `pip3 install --user pyyaml`; sandboxed agent shells need network access to PyPI. |
| Agent follows old frontmatter or loop rules | Catalog `SKILL.md` changed but `.agents/skills/` did not. Re-run step 1 with `--force`, commit, and restart the agent. |

# Related

- [ADR-0004](../decisions/ADR-0004-project-skill-install.md)
- [Catalog layout](../concepts/catalog-layout.md)
- [Conventions](../concepts/conventions.md)
- [Gotchas](../concepts/gotchas.md)
- [ADR-0005](../decisions/ADR-0005-okf-alignment.md)

[^install-sh]: zvec-llm-wiki install script
[^zg-bootstrap-sh]: zvec-llm-wiki bootstrap script

[^node-release-index]: The official Node.js release index lists each LTS version and its bundled npm.
[^npm-release]: The npm package metadata lists compatible versions of Node.js.

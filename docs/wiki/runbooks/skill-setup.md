# Runbook: Install skill and bootstrap this repo

> Verified setup steps for the Agent Skills catalog (dogfooded 2026-09-03; paths updated 2026-09-07).

## Prerequisites

- Node.js 22+
- POSIX shell (Git Bash on Windows)

## 1. Install the skill (once per machine)

From the catalog:

```bash
sh skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh --force
```

Installs to `~/.agents/skills/zvec-llm-wiki`. Restart the agent after install.

Project-scoped: add `--project` (installs to `.agents/skills/` in cwd).

Japanese locale:

```bash
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --force
```

## 2. Bootstrap the target repo (once per project)

From the **project root** (not the skill package folder):

```bash
bash skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh --target cursor
```

Creates `docs/wiki/`, `AGENTS.md`, `.zvec-grep/`, installs `@zvec/zvec-grep` globally if `zg` is missing, runs `zg install`, builds index with `local/potion-multilingual-128m`.

Supported embeddings are whatever the installed zg lists — do not copy a model table into this wiki. Inspect the catalog:

```bash
zg help models
npx --yes @zvec/zvec-grep help models   # if zg is not on PATH
```

**Idempotent**: second run does not rebuild wiki scaffold or drop index; runs incremental `zg index`.

**Git**: add `.zvec-grep/` to `.gitignore` (local index only).

## 3. After wiki edits

```bash
npx --yes @zvec/zvec-grep index    # or `zg index` if globally installed
npx --yes @zvec/zvec-grep status --check-ready
```

Restart agent after first MCP install.

## Troubleshooting

| Issue | Action |
|-------|--------|
| `zg` not on PATH / MCP `zvec_grep` error | `npm install -g @zvec/zvec-grep`, confirm `which zg`, restart Cursor. After an nvm Node switch, reinstall globally. |
| Query returns empty stubs | Wiki pages need content; re-run `zg index` after edits |
| MCP tool missing after a good `zg` | Restart Cursor after `zg install --target cursor` |

## Related

- [architecture.md](../architecture.md)
- [conventions.md](../conventions.md)

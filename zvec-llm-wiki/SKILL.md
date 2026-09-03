---
name: zvec-llm-wiki
description: Maintains a project's LLM wiki (docs/wiki/) with zvec-grep (zg) so agents read knowledge before acting and record after verification. Use for LLM wiki, living docs, zvec-grep, zg, ナレッジベース, wiki整備, conventions, ADRs, or gotchas. Not for web search or non-wiki Markdown.
license: Proprietary. Internal use.
---

# Maintaining an LLM wiki with zvec-grep

## Overview

Run the project's documentation as a **living system** that both humans and agents share.
`zg` (zvec-grep) is the retrieval layer; `docs/wiki/` is the source of truth. The loop is:

> **Read (zg) → Work → Verify with the human → Record (edit wiki) → Re-index (zg index)**

Two non-negotiable rules keep this trustworthy:

1. **Human is the checkpoint.** After work is verified, **propose** wiki updates (what page, what
   to add). Record only when the user approves. Never silently write docs — a wrong result would
   become a "rule" the next session trusts. Structural changes should include wiki/ADR updates in
   the **same PR** once approved.
2. **The agent never mutates the index lifecycle on its own.** You MAY run `zg index`
   (incremental update) *after wiki edits* as a routine refresh, but you MUST NOT run
   `--rebuild`, `--drop`, or `--reset-paths` without explicit user confirmation.

If `zg` is not installed or no index exists, follow **Bootstrap** below. Until bootstrap succeeds,
use normal search tools to read code — but do **not** update the wiki from unverified guesses.

## Wiki structure (docs/wiki/)

Principle: **one home per fact, cross-reference instead of copy.** Separate *what* (auto-derivable
from code) from *why* (human intent).

```
docs/wiki/
  index.md          # entry map: what lives where (the registry)
  glossary.md       # domain terms, acronyms, one-line definitions
  architecture.md   # components, boundaries, data flow (the "what")
  decisions/        # ADRs: one file per decision, the "why" (ADR-0001-*.md)
  conventions.md    # naming, patterns, do/don't
  gotchas.md        # sharp edges: "we don't touch X because ..."
  runbooks/         # how to build, test, deploy, release
```

Use `templates/adr.md` and `templates/wiki-page.md` as starting points. Keep each page short;
link, don't duplicate. Governance details: `references/wiki-workflow.md`.

## Read before acting

### MCP (when wired by `zg install`)

Prefer the agent's indexed search tool for intent-based lookup:

| Agent | Semantic search tool |
|---|---|
| Codex / Claude Code / Cursor | `zvec_grep_search` |
| OpenCode | `zvec_grep_zvec_grep_search` |
| Qwen / Qoder | `mcp__zvec_grep__zvec_grep_search` |

Use native grep/rg (or `zg query --rg`) for exact symbols, paths, or regex. Index lifecycle
(`zg index`, `zg status`) stays on the CLI. Optional `zvec_grep_rg` exists only with zg's `full`
MCP toolset — do not assume it is available.

### CLI (`zg query`)

| You know... | Command |
|---|---|
| Only the intent / meaning | `zg query "where feature flags are resolved" --limit 5` |
| Intent + exact anchors | `zg query --hybrid "auth flow" --fts "ForbiddenError" --fuse --limit 10` |
| A concept, no keyword | `zg query --vector "how retries back off"` |
| Exact symbol / path / regex | `zg query --rg -n -F "AuthService" -g "*.ts" src` |

Narrow first, then widen: add `-g "docs/wiki/**"` to hit only the wiki, `-t md` for Markdown,
`-t ts` for code. Stop searching once the returned evidence is enough — do not read whole files
"just in case". See `references/zvec-grep-cheatsheet.md` for full flags.

**Freshness:** results report `fresh` or `possibly_stale`. Act on a good-enough hit; only use
`--refresh wait` when the very latest file change must be included.

## Record after verifying

When the user confirms the work is correct:

1. **Propose** what to record: which page owns the fact, whether an ADR is needed, and a short
   draft. Wait for approval before editing.
2. **Find the single home** with `zg query -g "docs/wiki/**" "<topic>"`. Update that page; if
   none exists, create one under the right section and add it to `index.md`.
3. **Write the *why*, not just the *what*.** For structural/architectural decisions, add or
   update an ADR in `decisions/` (use `templates/adr.md`).
4. **Cross-reference** related pages instead of copying prose.
5. **Re-index** after edits:
   ```bash
   zg index            # incremental; reuses model + path selection
   zg status           # confirm files indexed / no failures
   ```

Keep diffs small and reviewable — the user reviews wiki changes like code.

## Bootstrap (first time in a repo)

Run `scripts/zg-bootstrap.sh` from this skill package (or equivalent commands). It is idempotent
and non-destructive:

```bash
bash scripts/zg-bootstrap.sh                          # auto-detect agents
bash scripts/zg-bootstrap.sh --target cursor codex    # explicit targets
```

Requires Node.js 22+. The script resolves `zg` via existing install → `npx` → confirmed global
`npm install -g`. It scaffolds `docs/wiki/`, runs `zg install`, and builds the first index.

Manual equivalent:

```bash
npm install -g @zvec/zvec-grep          # or: npx @zvec/zvec-grep ...
zg install --target cursor --yes        # codex | opencode | claude | qwen | all
zg index -g "src/**" -g "docs/**" -g "!dist/**"
zg status --check-ready
```

`zg install` wires the local MCP server (loopback `127.0.0.1:7999`). Restart the agent after
install. Details: `references/zvec-grep-cheatsheet.md`.

## Guardrails

- Do **not** run `--rebuild`, `--drop`, `--reset-paths` without explicit confirmation.
- Do **not** update the wiki from unverified work, or copy the same fact into two files.
- Do **not** flood context: prefer ranked `zg` evidence over opening full files.
- `.zvec-grep/` and `.git/` are auto-excluded; don't index build/cache/log dirs.

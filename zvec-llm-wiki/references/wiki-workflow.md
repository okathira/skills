# LLM wiki workflow & governance

Detailed reference for the read/record loop. Load when setting up a wiki or when the user asks
about structure/governance.

## Karpathy LLM Wiki alignment

This skill adapts [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) for coding projects:

| Karpathy | This skill |
| --- | --- |
| Raw sources (immutable) | Repo code and config — wiki links to source, does not replace it |
| Wiki (compiled, compounding) | `docs/wiki/**` |
| Schema | `AGENTS.md` hot block + this skill package |
| Ingest | Record after human verification (propose → approve → edit) |
| Query | Read `index.md` first; search scoped to `docs/wiki/**` via zg |
| Lint | Drift checks below |
| Optional search | zvec-grep (`zg`) instead of qmd at scale |
| Optional `log.md` | `docs/wiki/log.md` — append-only timeline of ingests/records (not created by bootstrap; add when useful) |

**Human checkpoint** is intentional for coding: Karpathy's pattern lets the LLM maintain most of the wiki; here, unverified wiki text becomes trusted rules in the next session.

## Five governance invariants

1. **Docs-first.** Files under `docs/wiki/` are the source of truth; any external tracker/wiki copy
   is a mirror. Author in the repo before publishing elsewhere.
2. **One home per fact.** Each concept/decision/requirement lives in exactly one file.
   Cross-reference instead of copying — duplicated prose is drift waiting to happen.
3. **Indexed.** Every page is reachable from `index.md` (the registry) and included in the `zg`
   index, so agents can find it without a manual path.
4. **Human checkpoint.** After verification, **propose** wiki updates; record only on explicit
   approval. No silent auto-updates.
5. **Nothing structural ships without its doc.** A new module/feature/decision includes a
   proposed wiki/ADR entry; once approved, land it in the **same PR** as the code change.

## What vs. why

- **What** (auto-derivable): file structure, component list, public API surface. Can be
  regenerated from code; keep it thin and link to source.
- **Why** (human intent): trade-offs, constraints, rejected alternatives, gotchas. This is the
  durable value — it cannot be recovered by scanning code. Capture it in ADRs and `gotchas.md`.

## Hot vs. cold memory

- **Hot memory** = `AGENTS.md` at repo root (bootstrap upserts a marked block). Loaded every
  session. Keep it short — where the wiki lives, search wiki before acting, propose-then-record.
- **Cold memory** = `docs/wiki/**`: pulled on demand through zg. Only the relevant page enters
  context, not the whole wiki.

Bootstrap writes or updates this block in `AGENTS.md`:

```md
<!-- ZVEC_LLM_WIKI_START -->
## Project knowledge (LLM wiki)

- Living wiki: `docs/wiki/` (registry: `docs/wiki/index.md`)
- Search wiki before acting (scope: `docs/wiki/**`)
- After verified work: propose wiki updates; on approval, edit the owning page, then incremental `zg index`

<!-- ZVEC_LLM_WIKI_END -->
```

For Claude Code, copy the same block into `CLAUDE.md` manually if needed.

## Session loop

1. **Start** — read `docs/wiki/index.md` (registry) so you know what exists and where.
2. **Before a task** — search for intent scoped to `docs/wiki/**` first, then widen to code if
   needed. How to pass scope: `zg help query`. Read only what ranked results point to.
3. **Do the work.**
4. **Verify** with the user (tests pass / behavior confirmed).
5. **Propose, then record on approval** — update the one owning page, add/adjust an ADR for
   decisions, register any new page in `index.md`, cross-reference.
6. **Re-index** — incremental `zg index`, then `zg status`.

## Index scope

First bootstrap uses zg default file discovery — no `src/` assumption. After you understand the
repo layout, propose narrower or wider index paths when defaults are wrong. Use `zg help index` for
path options. `--reset-paths` and `--rebuild` require explicit user confirmation.

## Registry format (Karpathy index)

`index.md` lists every page with a **link and one-line summary** (not just a table of roles). Register new pages on every ingest. Stubs with only a heading rank in search but answer nothing until filled in.

## Drift checks (lint — run periodically)

- Search `docs/wiki/**` for the feature you just changed — does the wiki still match reality?
- After a rename, use exact lookup across `docs/**` for stale references.
- If a page describes removed behavior, fix it in the same PR as the code change.
- Orphan pages: every file under `docs/wiki/` must appear in `index.md`.
- Mentioned-but-missing pages: concepts referenced in prose should have a home or a deliberate stub.

For search commands and flags, use `zg help query`.

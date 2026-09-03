# LLM wiki workflow & governance

Detailed reference for the read/record loop. Load when setting up a wiki or when the user asks
about structure/governance.

## Five governance invariants

1. **Docs-first.** The `docs/wiki/` file is the source of truth; any external tracker/wiki copy
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

- **Hot memory** = `AGENTS.md` / `CLAUDE.md` at repo root: loaded every session. Keep it short —
  conventions, where the wiki lives, and "read the wiki before acting via `zg`".
- **Cold memory** = `docs/wiki/**`: pulled on demand through `zg query`. Only the relevant page
  enters context, not the whole wiki.

Suggested `AGENTS.md` snippet:

```md
## Project knowledge
- Living wiki: docs/wiki/ (registry: docs/wiki/index.md)
- Search it before acting:  zg query "<intent>" -g "docs/wiki/**"
- After verified work: propose wiki updates; on approval, edit the owning page, then `zg index`.
```

## Session loop

1. **Start** — read `docs/wiki/index.md` (registry) so you know what exists and where.
2. **Before a task** — `zg query "<intent>"` to pull relevant pages + code evidence. Read only
   what the ranked results point to.
3. **Do the work.**
4. **Verify** with the user (tests pass / behavior confirmed).
5. **Propose, then record on approval** — update the one owning page, add/adjust an ADR for
   decisions, register any new page in `index.md`, cross-reference.
6. **Re-index** — `zg index` then `zg status`.

## Drift checks (run periodically)

- `zg query -g "docs/wiki/**" "<feature you just changed>"` — does the wiki still match reality?
- Grep for stale references after a rename: `zg query --rg -n -F "OldName" -g "docs/**"`.
- If a page describes removed behavior, fix it in the same PR as the code change.

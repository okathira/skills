<!-- ZVEC_LLM_WIKI_START -->
## Project knowledge (LLM wiki)

- Living wiki: `docs/wiki/` (registry: `docs/wiki/index.md`)
- Query order: read `index.md`; then zg hybrid scoped to `docs/wiki/**`; then rg for exact names; widen only if needed
- Wiki writes are involved: show the page plan, then edit unless stopped; after edits run incremental `zg index`
- When catalog facts the talks describe change, update `talks/decks/zvec-llm-wiki/` and `talks/decks/zvec-llm-wiki-ja/` in the same change; run `bunx dekc lint` from `talks/`

<!-- ZVEC_LLM_WIKI_END -->

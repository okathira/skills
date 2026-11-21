<!-- ZVEC_LLM_WIKI_START -->
## Project knowledge (LLM wiki)

- Living wiki: `docs/wiki/`, an OKF v0.3 bundle (start at `docs/wiki/index.md`, then directory indexes)
- Query order: indexes; then zg hybrid scoped to `docs/wiki/**`; then rg for exact names; widen to docs/raw or code only if needed
- Write with `okf-generate`; report trust and freshness with `okf-consume`; llm-wiki rules live in `zvec-llm-wiki`
- Wiki writes are involved: show the page plan, then edit unless stopped; after edits regenerate indexes, lint, and run `bash .agents/skills/zvec-llm-wiki/scripts/zg.sh --index`

<!-- ZVEC_LLM_WIKI_END -->

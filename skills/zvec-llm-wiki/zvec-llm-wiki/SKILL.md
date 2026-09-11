---
name: zvec-llm-wiki
description: Ingests, queries, lints, records, and crystallizes a project's LLM wiki (docs/wiki/) with zvec-grep (zg). Use for LLM wiki, living docs, knowledge bases, wiki maintenance, sources, entities, concepts, analyses, ADRs, or runbooks. Not for web search or non-wiki Markdown.
license: Proprietary. Internal use.
---

# Maintaining an LLM wiki with zvec-grep

## Overview
Run `docs/wiki/` as a living, compounding knowledge system shared by people and agents. `zg`
(zvec-grep) is the single retrieval engine. The loop is:

> **Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg index`**

Wiki writes are **involved**, not strict: show the pages and intended changes, then edit in the
same turn unless the user stops you. Keep changes small and evidence-linked. Only destructive
index operations require prior approval.

## Wiki structure (docs/wiki/)
Principle: **one home per fact; link instead of copying.**

```
docs/wiki/
  index.md          # registry grouped by category, with links and one-line summaries
  log.md            # append-only operation timeline
  sources/          # source summaries and provenance
  entities/         # people, systems, projects, products
  concepts/         # terms, patterns, rules, ideas
  analyses/         # synthesis and crystallized answers
  decisions/        # optional coding overlay: ADRs
  runbooks/         # optional coding overlay: procedures
raw/                # optional project-root immutable imported Markdown
```

Living documents belong in the wiki. Imported dumps may live in `raw/` and stay immutable.
Executable code is raw evidence: index and query it, but do not compile the whole codebase into
wiki pages. PDF/Office input must be converted to Markdown before ingest; native PDF ingest is not
supported. Use relative `.md` links, never `[[wikilinks]]`.

## Operations

### Query

1. Read `docs/wiki/index.md`.
2. If the registry is insufficient, use zg hybrid search scoped to `docs/wiki/**`.
3. For a known name, path, exact alias, or Japanese proper noun, use zg managed rg (or native
   `rg` when needed).
4. Widen to `raw/**` or code only when wiki evidence is insufficient.
5. Stop when ranked evidence is enough; do not open whole files just in case.

### Ingest and record

- Show the page plan, then proceed unless interrupted.
- Find existing homes using wiki-scoped hybrid plus rg on exact aliases.
- Deep-compile documents into a few short pages; shallow-index code without compiling it.
- Put `status` and `aliases` in the page frontmatter (the YAML block between `---`). Add
  `source` when there is provenance. ADR pages also put `date` and `deciders` there. Do not
  copy those keys into headings or body prose (no `## Aliases`, no Source section that repeats
  `source`). Omit keys with no value (`superseded_by` only when replaced).
- Treat aliases as ubiquitous language: about 3–6 high-signal names for the fact this page owns,
  in the wiki's authoring language. Not one synonym, not a thesaurus. Shared definitions live on a
  glossary (or one concepts page); other pages alias, they do not redefine. Add another
  language/script only when that exact form is expected in rg.
- Update `index.md` and append `log.md` for ingest or substantial records.
- Preserve rejected approaches and dead ends; mark them superseded instead of deleting history.

### Crystallize

File a durable, well-supported query result under `analyses/`, without duplicating its facts into
other pages. Register it and log the operation.

### Lint

- Every wiki `.md` page is registered in `index.md`; every relative `.md` link resolves.
- Contradictions are visibly isolated in a section or an `analyses/` page, never silently merged.
- Pages sourced from `raw/` still match their source path and optional raw-dump hash.
- Oversized pages are split when they stop representing one fact or useful heading-sized chunks.
- Renames and stale exact references are checked with rg.
- Superseded claims and dead ends remain visible.
- Content pages carry a handful of high-signal frontmatter `aliases` for their own fact; no body
  list restamps frontmatter; shared terms are defined once on a glossary page.

After wiki edits, run incremental `zg index`, then `zg status`/freshness before relying on a new
query. For detailed governance and log format, read `references/wiki-workflow.md`.

## zg usage

This skill defines **when**, not CLI syntax. Run `zg help query`, `zg help index`, `zg help
install`, or `zg help models`; do not invent flags. One workspace index serves wiki, raw, and
code through query-time scopes. Keep the multilingual default
`local/potion-multilingual-128m`; `local/qwen3-embedding-0.6b` is a same-engine quality upgrade
that requires a rebuild and therefore approval. Do not add qmd or a second indexer.

## Bootstrap

```bash
bash scripts/zg-bootstrap.sh                          # auto-detect agents
bash scripts/zg-bootstrap.sh --target cursor codex    # explicit targets; see zg help install
bash scripts/zg-bootstrap.sh --embedding <model>      # override default wiki embedding (list: zg help models)
```

Requires Node.js 22+. The script creates a useful scaffold only when `docs/wiki/` is absent,
upserts the `AGENTS.md` hot block, configures zg, and builds or incrementally updates one index.
An existing wiki is untouched.

Never run `--rebuild`, `--drop`, or `--reset-paths` without explicit user approval.

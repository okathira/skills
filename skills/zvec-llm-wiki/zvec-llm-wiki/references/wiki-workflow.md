# LLM wiki workflow & governance

Detailed reference for ingest, query, lint, record, and crystallize.

## Karpathy alignment

| Karpathy layer/op | This skill |
| --- | --- |
| Raw sources (immutable) | Optional `raw/` imported Markdown; executable code remains raw evidence |
| Wiki (compiled, compounding) | `sources/`, `entities/`, `concepts/`, `analyses/` |
| Optional coding overlay | `decisions/`, `runbooks/` |
| Schema | `index.md`, page frontmatter/headings, and the `AGENTS.md` hot block |
| Ingest | Deep-compile documents; shallow-index code; update registry and log |
| Query | index → wiki-scoped zg hybrid → rg for names → widen |
| Lint | Registry, links, contradictions, freshness, size, renames, history |
| Record | Show intended pages, then write unless interrupted (involved) |
| Crystallize | Preserve a durable query synthesis in `analyses/` |
| Log | Append-only `log.md` timeline |

zg is the only search engine. There is no qmd integration, second index, or strict wiki write-lock.

## Invariants

1. `docs/wiki/` is the home for living knowledge; mirrors are not authoritative.
2. One fact has one home. Use relative `.md` links, never copied prose or `[[wikilinks]]`.
3. Every page is linked from `index.md` with a one-line summary and indexed by zg.
4. Writes are involved: show the page plan and evidence, then edit unless the user stops.
5. Contradictions stay visible and isolated; rejected paths stay marked `superseded`.
6. Incremental `zg index` is routine. `--rebuild`, `--drop`, and `--reset-paths` require explicit
   approval.

## Page contract

Pages use thin YAML frontmatter:

```yaml
---
status: working # working | decided
aliases:
  - Exact alternate name
source: raw/example.md # repository-root raw path, repository path, or URL
---
```

Every content page carries this frontmatter, including the coding overlay; `index.md` and `log.md`
are schema and timeline, so they stay plain. zg indexes frontmatter as its own chunk, and rg reads the
whole file, so frontmatter keys do not need a body copy. Follow with a one-line lead and useful H2
sections such as `What`, `Why`, and `Related`. `source` may be omitted when no external source
exists. Hashes are optional and apply only to immutable `raw/` dumps, not the codebase. `Related`
and ADR `References` are the wiki graph; they must not restamp URLs or paths already listed in
`source`.

`decisions/` pages replace the enum with the ADR lifecycle and add decision metadata, so the
lifecycle has exactly one home instead of a body line that drifts from frontmatter:

```yaml
---
status: accepted # proposed = working; accepted and superseded = decided
date: 2026-09-08
deciders: name
---
```

Omit `superseded_by` until another ADR replaces this one. Omit `source` when there is no external
provenance. Do not leave blank keys.

Use `templates/wiki-page.md`, `templates/adr.md`, and `templates/runbook.md` as starting points.

## Ubiquitous language and aliases

Aliases are retrieval names for the fact a page owns, not extra prose and not a second glossary.

- Target **about 3–6** high-signal phrases people and agents actually type (`involved write`,
  `hot memory`, `zg-bootstrap`). One synonym is too thin; a thesaurus is too thick.
- Write them in the **wiki's authoring language**. Add Kanji, Kana, or English (or another
  script) only when that exact string is expected in rg.
- A glossary (or one `concepts/` page) owns shared term definitions. Other pages list names for
  their own fact; they do not copy definitions.
- One home: frontmatter only for `aliases`, `source`, `status`, and ADR `date` / `deciders` /
  `superseded_by`. Do not add a `## Aliases` section or a Source heading that copies frontmatter. A
  duplicated H2 alias list was tried for heading extract and is superseded.

When ingesting or recording, add aliases in the same edit. Lint thin alias lists the same way as
missing frontmatter.

## Staged query

1. Read `docs/wiki/index.md`.
2. Use zg hybrid search scoped to `docs/wiki/**` when the catalog is insufficient.
3. Use zg managed rg (or native rg) for known names, aliases, paths, and Japanese proper nouns.
4. Widen to `raw/**` or code only after wiki evidence is insufficient.
5. Stop when evidence is enough.

Use `zg help query` for current syntax. One workspace index serves all scopes.

## Ingest depths

- **Documents:** convert PDF/Office to Markdown first. Treat imported `raw/` files as immutable,
  find homes with hybrid plus alias rg, and compile claims into a few short wiki pages.
- **Code:** index and query it as raw evidence. Do not compile the repository tree into wiki pages.
- **Living Markdown:** move it into the wiki rather than keeping a second copy.

Every ingest updates `index.md`, appends `log.md`, then runs incremental `zg index` and checks
freshness before the next query.

## Log contract

Use `## [YYYY-MM-DD] kind | title`, where kind is `ingest`, `lint`, `crystallize`, or `record`.

```md
## [2026-09-08] ingest | Product brief

- Added [Product](entities/product.md) and updated [Pricing](concepts/pricing.md).
- Source: `raw/product-brief.md`
```

## Lint

- Compare wiki `.md` files with `index.md` to find orphans.
- Resolve every relative `.md` link; do not accept wikilinks.
- Use hybrid search to find semantic conflicts; isolate competing claims instead of merging them.
- Check source paths and optional hashes for pages compiled from `raw/`.
- Split pages that outgrow one fact or useful heading-sized sections.
- Use rg for stale names after renames.
- Preserve dead ends and superseded claims.
- Reject title-only or heading-only stubs because they pollute retrieval without answering.
- Reject empty or single-synonym `aliases` on content pages; expect a handful of high-signal
  frontmatter names, no body restamp of frontmatter keys, and shared definitions on one glossary page.

## Hot memory and embedding

The hot block says: read `index.md` first; then use wiki-scoped zg; show the write plan and proceed
unless stopped; run incremental `zg index` after edits.

The default remains `local/potion-multilingual-128m`. A higher-quality same-engine option is
`local/qwen3-embedding-0.6b`; switching requires a rebuild and explicit approval. Use `zg help
models` for the installed catalog.

---
status: decided
aliases:
  - catalog policy
  - wiki governance
  - involved write
  - alias policy
  - locale policy
source:
  - ../../../README.md
  - ../../../README.ja.md
---
# Catalog and wiki conventions

> This page owns locale policy, install boundaries, alias policy, and the accepted wiki workflow for this repository.

## Language policy

- English is the default package at `skills/<skill-name>/<skill-name>/`.
- Japanese variants live at `skills/<skill-name>/<skill-name>-ja/`.
- Each locale is a complete package; there are no cross-locale runtime dependencies.
- Behavioral changes update every locale in the same change.
- Root `README.md` and `README.ja.md` have the same sections and facts.

## Wiki workflow

The accepted loop is the same as `zvec-llm-wiki`:

> **Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg index`**

A second slogan (**Index → Retrieve → Work → Involved write → Incremental zg index**) was tried in this catalog and is superseded: it restated Query plus involved writes instead of naming the operations.

Query is staged:

- Read `docs/wiki/index.md` first.
- If it is insufficient, use zg hybrid search scoped to `docs/wiki/**`.
- Use exact rg for known names and aliases; widen to raw/code only if wiki evidence is insufficient.

Ingest, record, crystallize, and lint use involved writes: show the pages, then write unless the user stops the operation. There is no strict page write-lock. `zg index --rebuild`, `--drop`, and `--reset-paths` still require explicit confirmation. Preserve rejected or superseded ideas instead of deleting their history.

## Links and page shape

- Relative `.md` links are canonical in this GitHub-hosted catalog.
- Every page has a one-line lead and meaningful H2 sections so zg can return addressable evidence.
- Entity and concept aliases, provenance, and ADR lifecycle live only in YAML frontmatter.
- Do not restamp `status`, `source`, `date`, `deciders`, `superseded_by`, or `aliases` in the body.
- Every page is registered in `index.md`; one fact has one maintained home.

## Ubiquitous language and aliases

This wiki is English. Aliases are the English names people and agents actually type for the fact a page owns — not a thesaurus and not a Japanese mirror. Both skill locales encode this thickness.

- [Glossary](glossary.md) owns term definitions.
- Each other page lists only the names of its own fact in frontmatter `aliases`.
- Target about 3–6 high-signal phrases (`involved write`, `hot memory`, `coding overlay`). One synonym is too thin.
- Add a Japanese string only when that exact form is expected in rg. This catalog rarely needs that.
- Do not duplicate frontmatter in the body. zg already chunks frontmatter; a second list or Source heading drifts.
- `Related` / `References` are the wiki graph. They must not copy `source` paths or URLs.

## Related

- [Catalog layout](catalog-layout.md)
- [Glossary](glossary.md)
- [Deferred wiki tooling](deferred-wiki-tooling.md)
- [ADR-0003](../decisions/ADR-0003-karpathy-alignment-plan.md)

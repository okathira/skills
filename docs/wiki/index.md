# Wiki registry

> Content-oriented map of every maintained wiki page. Read this first, then retrieve only what the task needs.

## Sources

No imported source pages yet. Executable code and package files remain raw and are searched directly only when wiki evidence is insufficient.

## Entities

No entity pages yet.

## Concepts

| Page | One-line summary |
|------|------------------|
| [concepts/glossary.md](concepts/glossary.md) | Ubiquitous language for the catalog, Karpathy operations, and zg retrieval |
| [concepts/catalog-layout.md](concepts/catalog-layout.md) | Repository layout and boundaries between packages, raw code, wiki, and hot memory |
| [concepts/conventions.md](concepts/conventions.md) | Locale policy, alias policy, index-first retrieval, and involved writes |
| [concepts/gotchas.md](concepts/gotchas.md) | Dogfooding pitfalls around bootstrap, empty stubs, MCP, and Japanese aliases |
| [concepts/deferred-wiki-tooling.md](concepts/deferred-wiki-tooling.md) | Working list of optional viewer, conversion, claim, and maintenance tooling |

## Analyses

No crystallized analyses yet. Accepted design synthesis lives in ADR-0003.

## Decisions (coding overlay)

| Page | One-line summary |
|------|------------------|
| [decisions/ADR-0001-locale-independence.md](decisions/ADR-0001-locale-independence.md) | Locale folders are standalone packages without symlinks |
| [decisions/ADR-0002-catalog-skills-directory.md](decisions/ADR-0002-catalog-skills-directory.md) | Distributable packages live under `skills/<name>/` |
| [decisions/ADR-0003-karpathy-alignment-plan.md](decisions/ADR-0003-karpathy-alignment-plan.md) | zg-only, Karpathy-aligned architecture and first rewrite |

## Runbooks (coding overlay)

| Page | One-line summary |
|------|------------------|
| [runbooks/skill-setup.md](runbooks/skill-setup.md) | Install, bootstrap, and incrementally re-index the skill |

## Operations

| Page | One-line summary |
|------|------------------|
| [log.md](log.md) | Append-only timeline of ingest, lint, crystallize, and substantial record operations |

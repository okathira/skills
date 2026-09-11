---
status: working
aliases:
  - later tooling
  - deferred ideas
  - optional wiki tooling
  - Obsidian wikilinks
  - markitdown
source:
  - ../decisions/ADR-0003-karpathy-alignment-plan.md
---
# Deferred wiki tooling

> Optional tooling and integrations deliberately deferred beyond the first Karpathy-aligned rewrite.

## Obsidian and wikilinks

Obsidian can be an optional human viewer. This catalog keeps relative `.md` links as its canonical syntax because they also work on GitHub. Revisit `[[wikilinks]]` only with an explicit compatibility and lint strategy.

## PDF and Office conversion

zg does not natively extract PDF or Office files. A later guide may recommend `markitdown` or a similar converter before ingest, but the first rewrite does not bundle a converter.

## Code claim verification

A later coding overlay may let wiki claims record a source path and symbol, then verify them with zg exact search. Start without an OpenWiki-style claims runtime.

## Deterministic maintenance helpers

If agent-driven lint proves unreliable, add dependency-free, idempotent helpers for:

- synchronizing `index.md`;
- validating relative links;
- appending structured `log.md` entries;
- detecting changed immutable sources.

Do not add scripts before observed failures justify them.

## Related

- [Conventions](conventions.md)

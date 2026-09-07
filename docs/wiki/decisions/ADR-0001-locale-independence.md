# ADR-0001: Locale folders are independent packages

- **Status:** Accepted
- **Date:** 2026-09-03
- **Deciders:** Catalog maintainers

## Context

The skills catalog ships English and Japanese variants as separate installable packages. Agents may install only one locale. Cloud Agents and team repos need a predictable, copy-pasteable package without resolving cross-folder dependencies.

## Decision

Each locale folder is a **complete, standalone package**. English and Japanese folders mirror layout (`SKILL.md`, `install/`, `scripts/`, `references/`, `templates/`) but do not symlink, share, or reach into the other locale at runtime.

## Why (rationale)

- **Portability**: `skills/zvec-llm-wiki/zvec-llm-wiki-ja/` alone is enough to install and bootstrap.
- **Agent context**: default authoring language is English to reduce token load; Japanese is opt-in via `name: zvec-llm-wiki-ja`.
- **Maintenance contract**: behavior and flags stay aligned across locales; only natural language and `name` differ. Reduces drift vs a single mixed-language skill.

## Alternatives considered

- **Single skill with i18n strings** — Rejected: harder for agents to discover the right locale; violates one-skill-one-folder catalog layout.
- **Symlink `ja/` → English scripts** — Rejected: breaks standalone extraction; Windows and packaging tools handle symlinks poorly.

## Consequences

- Any behavior change requires editing both `skills/zvec-llm-wiki/zvec-llm-wiki/` and `skills/zvec-llm-wiki/zvec-llm-wiki-ja/` in the same PR.
- Wiki for this catalog is authored in English (default locale); Japanese skill README remains human-facing for Japanese installers.
- Catalog landing pages [README.md](../../../README.md) and [README.ja.md](../../../README.ja.md) stay in lockstep (see [conventions.md](../conventions.md)).

## References

- [conventions.md](../conventions.md)
- [architecture.md](../architecture.md)
- [decisions/ADR-0002-catalog-skills-directory.md](ADR-0002-catalog-skills-directory.md)
- Catalog [README.md](../../../README.md) · [README.ja.md](../../../README.ja.md)

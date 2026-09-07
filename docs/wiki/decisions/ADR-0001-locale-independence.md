# ADR-0001: Locale folders are independent packages

- **Status:** Accepted
- **Date:** 2026-09-03
- **Deciders:** Catalog maintainers

## Context

The skills catalog ships English skills at the repo root and Japanese variants under `ja/`. Agents may install only one locale. Cloud Agents and team repos need a predictable, copy-pasteable package without resolving cross-folder dependencies.

## Decision

Each locale folder is a **complete, standalone package**. English and Japanese folders mirror layout (`SKILL.md`, `install/`, `scripts/`, `references/`, `templates/`) but do not symlink, share, or reach into the other locale at runtime.

## Why (rationale)

- **Portability**: `ja/zvec-llm-wiki/` alone is enough to install and bootstrap.
- **Agent context**: default authoring language is English to reduce token load; Japanese is opt-in via `name: zvec-llm-wiki-ja`.
- **Maintenance contract**: behavior and flags stay aligned across locales; only natural language and `name` differ. Reduces drift vs a single mixed-language skill.

## Alternatives considered

- **Single skill with i18n strings** — Rejected: harder for agents to discover the right locale; violates one-skill-one-folder catalog layout.
- **Symlink `ja/` → English scripts** — Rejected: breaks standalone extraction; Windows and packaging tools handle symlinks poorly.

## Consequences

- Any behavior change requires editing both `zvec-llm-wiki/` and `ja/zvec-llm-wiki/` in the same PR.
- Wiki for this catalog is authored in English (default locale); Japanese skill README remains human-facing for `ja/` installers.

## References

- [conventions.md](../conventions.md)
- [architecture.md](../architecture.md)
- Catalog [README.md](../../../README.md)

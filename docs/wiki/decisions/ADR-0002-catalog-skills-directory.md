# ADR-0002: Skill packages under `skills/`

- **Status:** Accepted
- **Date:** 2026-09-07
- **Deciders:** Catalog maintainers

## Context

This repository is both an Agent Skills catalog and a dogfooding target for zvec-llm-wiki (`docs/wiki/`, `AGENTS.md`, `.zvec-grep/`). With one skill and two locales, packages already mixed with project artifacts at the repo root. Adding more skills would make the root harder to navigate and blur distributable packages vs compiled wiki knowledge.

## Decision

Distributable skill packages live under `skills/<skill-name>/`. Each skill groups its locales:

- Default (English): `skills/<skill-name>/<skill-name>/`
- Japanese: `skills/<skill-name>/<skill-name>-ja/`

The repo root keeps catalog landing pages (`README.md`, `README.ja.md`) and dogfooding artifacts (`docs/wiki/`, `AGENTS.md`). The intermediate `skills/<skill-name>/` folder is grouping only — not a skill package (no `SKILL.md` at that level).

## Why (rationale)

- **Separation**: packages vs wiki/hot memory are visually and structurally distinct.
- **Scale**: new skills add rows under `skills/` instead of cluttering the root.
- **Locale naming**: default locale stays unmarked (same pattern as `README.md` / `README.ja.md`); only variants get a suffix (`-ja`). No `-en` suffix — the parent folder already names the skill.
- **Independence preserved**: each locale folder remains a complete package per [ADR-0001](ADR-0001-locale-independence.md).

## Alternatives considered

- **English at repo root, Japanese under `ja/`** — Rejected: root clutter grows with every skill; dogfooding artifacts stay mixed with packages.
- **`skills/<skill-name>/en/` and `skills/<skill-name>/ja/`** — Rejected: Agent Skills spec requires parent directory name to match `name` in `SKILL.md`; `en/` and `ja/` are not valid skill names.
- **`skills/<skill-name>/<skill-name>-en/` for symmetry** — Rejected: default locale is unmarked; parent folder already identifies the skill; `-en` adds no information.

## Consequences

- All catalog paths, READMEs, and runbooks reference `skills/<skill-name>/...`.
- `install.sh` and `SKILL.md` `name` values are unchanged (`zvec-llm-wiki`, `zvec-llm-wiki-ja`).
- No grouping README under `skills/<skill-name>/` — catalog landing README remains the index.

## References

- [architecture.md](../architecture.md)
- [conventions.md](../conventions.md)
- [decisions/ADR-0001-locale-independence.md](ADR-0001-locale-independence.md)
- Catalog [README.md](../../../README.md) · [README.ja.md](../../../README.ja.md)

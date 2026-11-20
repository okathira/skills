---
type: Decision Record
title: "ADR-0005: Align the LLM wiki with OKF v0.3"
description: The wiki is an OKF v0.3 bundle; zvec-llm-wiki layers Karpathy operations, zg retrieval, and x-zvec extensions on the official okf-generate and okf-consume skills.
x-zvec-aliases:
  - ADR-0005
  - OKF alignment
  - Open Knowledge Format
  - OKF bundle
  - okf-migrate
generated: { by: "cursor/auto", at: "2026-11-20T11:07:00Z" }
verified:
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
sources:
  - id: okf-spec
    resource: https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md
    title: Open Knowledge Format v0.3 specification
  - id: okf-skills
    resource: https://github.com/open-knowledge-format/open-knowledge-format/tree/main/skills
    title: Official okf-generate and okf-consume skills
---

# Context

The wiki already matched most of OKF: a directory of Markdown files with YAML frontmatter, reserved `index.md` and `log.md`, and relative `.md` links.[^okf-spec] It did not declare `type`, so no page was an OKF concept. It also used its own `status` values (`working`, `decided`, ADR `accepted`), a single `source` list, `## [date] kind | title` log headings, and paths outside `docs/wiki/`.

OKF publishes reference skills: `okf-generate` writes and validates bundles with `validate.py`, and `okf-consume` reads them and reports trust, status, and freshness.[^okf-skills]

# Decision

1. `docs/wiki/` is an OKF v0.3 bundle. The root `index.md` carries `okf_version`, `title`, and `description`.
2. The official `okf-generate` and `okf-consume` skills own format, validation, and reading rules. `install.sh` fetches them at a pinned commit. zvec-llm-wiki defers to them instead of restating the spec.
3. zvec-llm-wiki keeps only what OKF leaves open:
   - Karpathy operations and staged zg retrieval ([ADR-0003](ADR-0003-karpathy-alignment-plan.md)).
   - Category directories mapped to `type`: `summaries/` Reference, `entities/` Entity, `concepts/` Concept, `analyses/` Analysis, `decisions/` Decision Record, `runbooks/` Playbook. `sources/` is renamed `summaries/` so it does not collide with the OKF `sources` field.
   - `x-zvec-aliases` as the retrieval-name extension key.
   - Immutable imports live in `docs/raw/`, outside the bundle. Wiki-scoped queries do not see them; widen to `docs/raw/` only when wiki evidence is insufficient.
   - Repository files are cited by paths relative to the page. They resolve outside the bundle, so OKF treats them as external; the skill lint checks that they exist.
   - Every directory has a generated `index.md`, and `llm_wiki.py lint --strict` must pass. It reports every `validate.py` finding, including W120, so broken links and Markdown that is not a concept both fail.
4. Agents set `generated` whenever they change meaning. `verified` is added only when a person confirms the content and states an id such as `human:owner`. ADR `date` and `deciders` become `verified` history.
5. A separate skill, `zvec-llm-wiki-okf-migrate`, converts older wikis and ends with a human review that records verifications. The daily skill stays small.

# Alternatives considered

- **Keep custom `status` values** — rejected: OKF consumers treat unknown values as not current.
- **Merge aliases into `tags`** — rejected: tags are cross-cutting categories, aliases are names for one fact.
- **Unprefixed `aliases`** — rejected: OKF reserves no `x-` keys, so the prefix avoids a future collision.
- **GitHub URLs for repository sources** — rejected: relative paths stay checkable locally and survive forks and branches.
- **Vendor `validate.py` or port it to Node** — rejected: fetching the official skills keeps the spec rules in one place.
- **Hand-maintained index tables** — rejected: OKF indexes copy `description`, so generating them keeps one home.
- **Excuse W120 for imported Markdown inside the bundle** — rejected: OKF keeps that warning for files such as a README. Imports stay outside the bundle, and the validator stays strict.

# Consequences

- Python 3.9+ with PyYAML becomes a prerequisite next to Node.js 22+.
- Migration rewrites every page, so every concept is unverified until the review step records `human:` verifications.
- ADR-0003 still owns the Karpathy and zg design; this ADR layers the OKF format on top.
- Index files are generated; hand edits below the root frontmatter are overwritten.

[^okf-spec]: Open Knowledge Format v0.3 specification
[^okf-skills]: Official okf-generate and okf-consume skills

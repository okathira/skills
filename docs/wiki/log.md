# Wiki log

Append-only timeline for substantial wiki operations. Use `## [YYYY-MM-DD] kind | title`; record ingest, lint, crystallize, and large record operations, not routine queries.

## [2026-09-11] record | Re-dogfood skill install and loop name

- Reinstalled `zvec-llm-wiki` with `--force` and re-ran `zg-bootstrap.sh --target cursor` from the repo root. Existing wiki stayed in place; hot memory unchanged; incremental index.
- Catalog conventions now use the skill loop (**Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg index`**). The older Index → Retrieve slogan is superseded as a second name for the same steps.
- Runbook gained a Verification section; gotchas record that bootstrap does not refresh `~/.agents/skills/`.
- ADR-0003 implementation notes now match frontmatter-only aliases and the runbook template.

## [2026-09-11] record | Say frontmatter, not YAML alone

- Living skill and wiki pages now call the metadata block frontmatter. `YAML` remains only as the syntax (`---` fences, “YAML frontmatter”, “the YAML block between `---`”).
- Left historical `log.md` lines unchanged.

## [2026-09-10] record | Frontmatter is the only metadata home

- Generalized the one-home rule beyond aliases: `source`, `status`, `date`, `deciders`, and `superseded_by` stay in YAML.
- Dropped empty ADR keys, moved README and Karpathy/zg URLs into `source`, and stopped restamping those paths in References/Related.
- Skill lint now rejects body copies of frontmatter keys.

## [2026-09-10] record | Aliases live only in frontmatter

- Dropped the duplicated `## Aliases` body list. zg FTS/rg already hit YAML `aliases` as a chunk; two lists were one-home drift (glossary YAML missed `用語集` until this change).
- Skill, templates, and catalog concept pages now keep retrieval names in frontmatter only. The H2 copy is marked superseded in ADR-0003.

## [2026-09-10] record | Skill encodes alias thickness

- Both `zvec-llm-wiki` locales now require about 3–6 high-signal aliases, glossary-owned definitions, and YAML/`## Aliases` sync as ingest and lint rules.
- Templates show a handful of alias slots instead of a single synonym.

## [2026-09-10] record | English ubiquitous-language aliases

- Glossary now owns term definitions, including ubiquitous language, involved write, coding overlay, raw, install vs bootstrap, dogfood, and one home.
- Conventions records the alias policy: English high-signal names, YAML and `## Aliases` in sync, Japanese only for exact rg.
- Thickened aliases on concept, decision, and runbook pages without duplicating definitions.

## [2026-09-10] record | Overlay pages adopt the frontmatter contract

- Extended the page contract so `decisions/` and `runbooks/` also carry frontmatter.
- Moved the ADR lifecycle out of the body bullets into `status` / `superseded_by` / `date` / `deciders`, keeping one home per fact.
- Added `templates/runbook.md` in both locales and migrated the three ADRs plus the setup runbook.

## [2026-09-10] record | Dogfood bootstrap of this catalog

- Reinstalled `zvec-llm-wiki` with `--force` and ran `zg-bootstrap.sh --target cursor` from the repo root.
- Existing wiki was left in place (already Karpathy-grouped); no root-level `glossary.md` / `architecture.md` leftovers.
- Created empty `sources/`, `entities/`, and `analyses/` directories without heading-only stubs.
- Upserted `AGENTS.md` hot memory to the involved query/write block; incremental index stayed ready.

## [2026-09-08] record | Karpathy-aligned first rewrite

- Confirmed zg as the single engine.
- Adopted index-first staged retrieval and involved writes without a strict page lock.
- Reorganized living catalog knowledge into content-oriented wiki categories.
- Added deferred tooling as a separate working concept.

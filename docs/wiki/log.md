# Wiki log

Newest date first. Each entry starts with the operation in bold, such as **Ingest**, **Record**, **Crystallize**, or **Lint**, and links the pages it changed.

## 2026-11-21

* **Record**: Updated the [development toolchain](runbooks/skill-setup.md) to npm 12.2.3 with Node.js 26.13.1 LTS. CI installs the pinned npm in a temporary prefix.

* **Record**: Pinned development to Node.js 26.13.1 LTS and bundled npm 11.20.0, and checked the npm pin in CI. Documented the development toolchain in [skill setup](runbooks/skill-setup.md).

* **Record**: Updated [skill setup](runbooks/skill-setup.md) and [MCP gotchas](concepts/gotchas.md) for the pinned zg launcher, npm script permission, and version checks. Queued publish jobs so an older validation cannot replace the latest waiting job.

* **Record**: Added [CI validation and Git publication](concepts/catalog-layout.md) for generated plugins. The build validates package formats without installing a client.

* **Record**: Centralized the zvec-grep pin, documented both GPU-capable model choices, and prepared the [plugin distribution branch](concepts/catalog-layout.md).

* **Record**: Broadened the catalog to Agent Tools.
  - Updated the [catalog layout](concepts/catalog-layout.md) with the GitHub rename, MIT distribution, and generated local plugin marketplace.
  - Kept project MCP for dogfooding and added a bootstrap option for plugin-managed MCP. Updated [skill setup](runbooks/skill-setup.md) and [gotchas](concepts/gotchas.md) for the pinned zvec-grep 0.3.1 launcher and CLI syntax.

## 2026-11-20

* **Record**: Migrated the wiki to OKF v0.3
  - Decided in [ADR-0005](decisions/ADR-0005-okf-alignment.md): OKF frontmatter (`type`, `title`, `description`, `generated`, `sources`), `x-zvec-aliases`, generated directory indexes, and the OKF log format.
  - Converted every page with `zvec-llm-wiki-okf-migrate`; former ADR `date` and `deciders` became historical `verified` events.
  - Updated [Conventions](concepts/conventions.md), [Glossary](concepts/glossary.md), [Catalog layout](concepts/catalog-layout.md), [Gotchas](concepts/gotchas.md), [Deferred wiki tooling](concepts/deferred-wiki-tooling.md), and [skill-setup](runbooks/skill-setup.md) for the new skills and scripts.

* **Record**: Leave tooling outside OKF unimplemented
  - [Deferred wiki tooling](concepts/deferred-wiki-tooling.md): no bundled PDF converter, no symbol check against code, and no log-append script. `validate.py` remains the log check.

* **Record**: Close wikilinks and file-hash freshness
  - [Deferred wiki tooling](concepts/deferred-wiki-tooling.md) and [ADR-0003](decisions/ADR-0003-karpathy-alignment-plan.md): no `[[wikilinks]]`, and no hash of `docs/raw/`. Lint's OKF change report counts `I204` and `I201`.

* **Record**: Make ADR-0003 follow ADR-0005 for page format
  - [ADR-0003](decisions/ADR-0003-karpathy-alignment-plan.md) keeps the zg and Karpathy decisions. `working`/`decided`, `aliases`, `source`, root `raw/`, and the old log heading are marked as the first rewrite, and the current contract is [ADR-0005](decisions/ADR-0005-okf-alignment.md).

* **Record**: Verified the wiki as human:owner
  - Recorded a current `verified` event by `human:owner` on every concept.

* **Record**: Keep imported Markdown outside the bundle
  - [ADR-0005](decisions/ADR-0005-okf-alignment.md) no longer excuses validator warning W120. Immutable imports go in `docs/raw/`, which OKF treats as external.
  - The migration script leaves an opening in the body unless it is a single sentence with no links, and that sentence is the page's `description`.

## 2026-10-09

* **Record**: Bootstrap MCP merge and persistent zg
  - Project MCP upsert keeps compatible `zvec_grep` fields such as `env` and refuses an existing HTTP transport. Noted in [gotchas](concepts/gotchas.md), [skill-setup](runbooks/skill-setup.md), and [ADR-0004](decisions/ADR-0004-project-skill-install.md).
  - User-level `--target` installs `@zvec/zvec-grep` globally when `zg` is not on PATH, then checks that `zg` launches before `zg install`.

## 2026-10-08

* **Record**: Project skill install and committed MCP
  - Default `install.sh` targets `.agents/skills/`; `--user` keeps the old home-directory install. Documented in [ADR-0004](decisions/ADR-0004-project-skill-install.md), [skill-setup](runbooks/skill-setup.md), and both skill locales.
  - `zg-bootstrap.sh` upserts `.cursor/mcp.json` and `.mcp.json` with `npx @zvec/zvec-grep` stdio; CLI may use `npx` when `zg` is absent. User-level `zg install` is optional via `--target` (cursor/claude use project files).
  - Dogfood: committed `.agents/skills/zvec-llm-wiki/`, `.cursor/mcp.json`, `.mcp.json`.

## 2026-10-07

* **Record**: deciders shapes and Node pin
  - Documented ADR `deciders` identifier shape rules in both skill `wiki-workflow` page contracts; [Conventions](concepts/conventions.md) links there; added **Deciders** and **Owner** to [Glossary](concepts/glossary.md).
  - Pinned repo-root `.node-version` to current Node LTS `24.21.0`; noted it in [skill-setup](runbooks/skill-setup.md).

## 2026-10-06

* **Record**: deciders identifier notation
  - ADR `deciders` is a YAML list of `@handle`, email, `owner`, or `agent:<name>` only; free-form display names are superseded.
  - Updated [Conventions](concepts/conventions.md), both skill locales (`wiki-workflow`, `adr` template, `SKILL.md`), and normalized ADR-0001–0003 to `owner`.

## 2026-09-11

* **Record**: Re-dogfood skill install and loop name
  - Reinstalled `zvec-llm-wiki` with `--force` and re-ran `zg-bootstrap.sh --target cursor` from the repo root. Existing wiki stayed in place; hot memory unchanged; incremental index.
  - Catalog conventions now use the skill loop (**Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg index`**). The older Index → Retrieve slogan is superseded as a second name for the same steps.
  - Runbook gained a Verification section; gotchas record that bootstrap does not refresh `~/.agents/skills/`.
  - ADR-0003 implementation notes now match frontmatter-only aliases and the runbook template.
* **Record**: Say frontmatter, not YAML alone
  - Living skill and wiki pages now call the metadata block frontmatter. `YAML` remains only as the syntax (`---` fences, “YAML frontmatter”, “the YAML block between `---`”).
  - Left historical `log.md` lines unchanged.

## 2026-09-10

* **Record**: Frontmatter is the only metadata home
  - Generalized the one-home rule beyond aliases: `source`, `status`, `date`, `deciders`, and `superseded_by` stay in YAML.
  - Dropped empty ADR keys, moved README and Karpathy/zg URLs into `source`, and stopped restamping those paths in References/Related.
  - Skill lint now rejects body copies of frontmatter keys.
* **Record**: Aliases live only in frontmatter
  - Dropped the duplicated `## Aliases` body list. zg FTS/rg already hit YAML `aliases` as a chunk; two lists were one-home drift (glossary YAML missed `用語集` until this change).
  - Skill, templates, and catalog concept pages now keep retrieval names in frontmatter only. The H2 copy is marked superseded in ADR-0003.
* **Record**: Skill encodes alias thickness
  - Both `zvec-llm-wiki` locales now require about 3–6 high-signal aliases, glossary-owned definitions, and YAML/`## Aliases` sync as ingest and lint rules.
  - Templates show a handful of alias slots instead of a single synonym.
* **Record**: English ubiquitous-language aliases
  - Glossary now owns term definitions, including ubiquitous language, involved write, coding overlay, raw, install vs bootstrap, dogfood, and one home.
  - Conventions records the alias policy: English high-signal names, YAML and `## Aliases` in sync, Japanese only for exact rg.
  - Thickened aliases on concept, decision, and runbook pages without duplicating definitions.
* **Record**: Overlay pages adopt the frontmatter contract
  - Extended the page contract so `decisions/` and `runbooks/` also carry frontmatter.
  - Moved the ADR lifecycle out of the body bullets into `status` / `superseded_by` / `date` / `deciders`, keeping one home per fact.
  - Added `templates/runbook.md` in both locales and migrated the three ADRs plus the setup runbook.
* **Record**: Dogfood bootstrap of this catalog
  - Reinstalled `zvec-llm-wiki` with `--force` and ran `zg-bootstrap.sh --target cursor` from the repo root.
  - Existing wiki was left in place (already Karpathy-grouped); no root-level `glossary.md` / `architecture.md` leftovers.
  - Created empty `sources/`, `entities/`, and `analyses/` directories without heading-only stubs.
  - Upserted `AGENTS.md` hot memory to the involved query/write block; incremental index stayed ready.

## 2026-09-08

* **Record**: Karpathy-aligned first rewrite
  - Confirmed zg as the single engine.
  - Adopted index-first staged retrieval and involved writes without a strict page lock.
  - Reorganized living catalog knowledge into content-oriented wiki categories.
  - Added deferred tooling as a separate working concept.

# LLM wiki workflow & governance

Detailed reference for ingest, query, lint, record, and crystallize. The format is OKF v0.3; the
official `okf-generate` skill owns field rules. This file lists only what llm-wiki adds or decides.

## Karpathy alignment

| Karpathy layer/op | This skill |
| --- | --- |
| Raw sources (immutable) | Optional `docs/raw/` imported Markdown, outside the bundle; executable code remains raw evidence |
| Wiki (compiled, compounding) | `summaries/`, `entities/`, `concepts/`, `analyses/` |
| Optional coding overlay | `decisions/`, `runbooks/` |
| Schema | OKF frontmatter, generated `index.md` files, and the `AGENTS.md` hot block |
| Ingest | Deep-compile documents; shallow-index code; log and regenerate indexes |
| Query | indexes → wiki-scoped zg hybrid → rg for names → widen |
| Lint | `llm_wiki.py lint --strict` (runs `validate.py`), then judgment checks |
| Record | Show intended pages, then write unless interrupted (involved) |
| Crystallize | Preserve a durable query synthesis in `analyses/` |
| Log | Newest-first OKF `log.md` |

zg is the only search engine. There is no qmd integration, second index, or strict wiki write-lock.

## Invariants

1. `docs/wiki/` is the bundle root and the home for living knowledge; mirrors are not authoritative.
2. One fact has one home. Use relative `.md` links, never copied prose or `[[wikilinks]]`.
3. Every directory with content has a generated `index.md`; do not hand-edit below the root
   frontmatter.
4. Writes are involved: show the page plan and evidence, then edit unless the user stops.
5. Contradictions stay visible and isolated; replaced pages stay as `deprecated` with `superseded_by`.
6. Incremental `zg index` is routine. `--rebuild`, `--drop`, and `--reset-paths` require explicit
   approval.

## Page contract (llm-wiki additions to OKF)

```yaml
---
type: Concept                     # from the directory map below
title: Involved writes
description: One sentence; directory indexes copy it.
x-zvec-aliases:
  - involved write
  - write plan
  - edit unless stopped
generated: { by: "cursor/<model>", at: "2026-11-20T10:00:00Z" }
sources:
  - id: readme
    resource: ../../README.md     # repository file: relative to this page, external to OKF
    title: Project README
---

# What
Body text with a claim.[^readme]

[^readme]: Project README
```

| Directory | `type` |
| --- | --- |
| `summaries/` | `Reference` |
| `entities/` | `Entity` |
| `concepts/` | `Concept` |
| `analyses/` | `Analysis` |
| `decisions/` | `Decision Record` |
| `runbooks/` | `Playbook` |

- The body starts with content or H1 sections. `title` and `description` replace an H1 title and a
  lead line; do not repeat them.
- Omit `status` for stable pages. Use `draft` for work in progress and `deprecated` plus
  `superseded_by` (a `/`-rooted path) for replaced pages.
- `generated.by` is the writing agent, `<tool>/<model>`. Update `generated.at` only when meaning
  changes.
- `verified` events need a person who confirmed the content and stated an id. Accepted forms:
  `human:owner` (personal project role), `human:@handle`, `human:user@example.com`. Agents may
  record `agent:<name>` events; they never give the human-reviewed tier.
- ADR acceptance is a `verified` event; there is no `date` or `deciders` key.
- `sources[].resource` is a URL, a `/`-rooted bundle path, or a repository path relative to the page.
  Cite specific claims with `[^id]` footnotes. `Related` lists are wiki graph only; they do not
  restamp `sources`.

Use `templates/wiki-page.md`, `templates/adr.md`, and `templates/runbook.md` as starting points.

## Ubiquitous language and aliases

`x-zvec-aliases` are retrieval names for the fact a page owns, not extra prose and not a second
glossary. OKF `tags` are cross-cutting categories; do not put aliases there.

- Target **about 3–6** high-signal phrases people and agents actually type (`involved write`,
  `hot memory`, `zg-bootstrap`). One synonym is too thin; a thesaurus is too thick.
- Write them in the **wiki's authoring language**. Add Kanji, Kana, or English (or another
  script) only when that exact string is expected in rg.
- A glossary (or one `concepts/` page) owns shared term definitions. Other pages list names for
  their own fact; they do not copy definitions.
- Do not add a `# Aliases` or `# Sources` section that copies frontmatter.

## Staged query

1. Read `docs/wiki/index.md`, then the directory indexes that relate to the task.
2. Use zg hybrid search scoped to `docs/wiki/**` when the indexes are insufficient.
3. Use zg managed rg (or native rg) for known names, aliases, paths, and Japanese proper nouns.
4. Widen to `docs/raw/**` or code only after wiki evidence is insufficient.
5. Stop when evidence is enough. Apply `okf-consume` trust, status, freshness, and conflict rules.

Use `zg help query` for current syntax. One workspace index serves all scopes.

## Ingest depths

- **Documents:** convert PDF/Office to Markdown first. Keep the import in `docs/raw/` and leave it
  unchanged. Find homes with hybrid plus alias rg, and compile claims into a few short concepts
  that cite the file in `sources`.
- **Code:** index and query it as raw evidence. Do not compile the repository tree into wiki pages.
- **Living Markdown:** move it into the wiki rather than keeping a second copy.

Every ingest appends `log.md`, regenerates indexes, then runs incremental `zg index` and checks
freshness before the next query.

## Log contract

OKF log format: `## YYYY-MM-DD` headings, newest first, entries that start with the operation in
bold (`**Ingest**`, `**Record**`, `**Crystallize**`, `**Lint**`). Add entries under today's heading.

```md
## 2026-11-20

* **Ingest**: Product brief
  - Added [Product](entities/product.md) and updated [Pricing](concepts/pricing.md).
```

## Lint

`scripts/llm_wiki.py lint --strict` runs both layers:

- `okf-generate/scripts/validate.py` — OKF conformance, frontmatter shape, actors, timestamps,
  footnote ids, and links inside the bundle (broken links fail under `--strict`). Every finding is
  reported; Markdown that is not a concept belongs in `docs/raw/`, not in the bundle. The OKF change
  report at the end counts `I204` (a change in meaning left the concept unverified) and `I201`
  (`stale_after` has passed). Those are info findings. Do not hash source files to detect drift.
- llm-wiki checks — directory/type map, `x-zvec-aliases` count, leftover pre-OKF
  keys, repository paths outside the bundle that do not exist, wikilinks, body restamps, missing
  `generated` or `description`, and stale generated indexes.

Judgment:

- Use hybrid search to find semantic conflicts; isolate competing claims instead of merging them.
- Check pages compiled from `docs/raw/` against their source.
- Split pages that outgrow one fact or useful heading-sized sections.
- Use rg for stale names after renames.
- Preserve dead ends and deprecated claims.
- Reject title-only or heading-only stubs because they pollute retrieval without answering.
- Report pages whose trust tier dropped because `generated.at` moved past their `verified` events.

## Hot memory and embedding

The hot block says: the wiki is an OKF bundle; read indexes first; then use wiki-scoped zg; follow
`okf-generate` for writes and `okf-consume` for trust; show the write plan and proceed unless
stopped; regenerate indexes, lint, and run incremental `zg index` after edits.

The default remains `local/potion-multilingual-128m`. A higher-quality same-engine option is
`local/qwen3-embedding-0.6b`; switching requires a rebuild and explicit approval. Use `zg help
models` for the installed catalog.

---
type: Decision Record
title: "ADR-0003: Karpathy alignment with a single zg engine"
description: zg is the only search engine, and the wiki adopts Karpathy's operations and page kinds with involved writes.
x-zvec-aliases:
  - Karpathy alignment
  - ADR-0003
  - zg only
  - staged retrieval
  - involved writes
generated: { by: "cursor/auto", at: "2026-11-20T17:55:00Z" }
verified:
  - { by: "human:owner", at: "2026-09-08T00:00:00Z" }
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
  - { by: "human:owner", at: "2026-11-20T15:51:00Z" }
  - { by: "human:owner", at: "2026-11-20T17:56:00Z" }
sources:
  - id: karpathy-llm-wiki
    resource: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
    title: Karpathy LLM Wiki
  - id: zvec-grep-open-source
    resource: https://zvec.org/en/blog/2026-08-28-zvec-grep-open-source/
    title: zvec-grep open-source announcement
  - id: adr-0005
    resource: /decisions/ADR-0005-okf-alignment.md
    title: "ADR-0005: Align the LLM wiki with OKF v0.3"
---

# Context

The skill was adapted from [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) but shipped a coding-doc skeleton, a strict propose-then-edit checkpoint, no `log.md`, and zg-first query. Intended use is broader: design docs, game design, idea wikis — and Japanese sources — not only code.

Search-engine candidates were qmd (gist-named, Markdown RAG) vs zg (this skill's existing layer). Dual engines were rejected. [zg's open-source post](https://zvec.org/en/blog/2026-08-28-zvec-grep-open-source/) describes zg as **one entry point** across semantic discovery, BM25/hybrid focusing, and rg verification — for code *and* documents — with compact, source-linked evidence.

# Decision

1. **Search engine: zg only.** Not provisional. qmd is not a skill feature (see Alternatives).
2. **Align wiki operations and default page kinds with Karpathy** (ingest / query / lint / log / sources-entities-concepts-analyses). Coding folders are an overlay.
3. **Shape those operations around zg's retrieval journey**, instead of treating zg as a drop-in qmd.
4. **Layers:** executable **code is raw** (do not compile the tree into wiki). **Living documents live in the wiki** (one home). Imported dumps (transcripts, third-party specs, PDF→md) may sit in `docs/raw/`, outside the bundle, and are ingested; they are not a second copy of the same fact. Existing living `.md` in the repo **moves** into `docs/wiki/` (re-filed by kind), it is not duplicated. Human landing pages (this catalog's README.md / README.ja.md) may stay outside as installer UI. The page format for these layers is [ADR-0005](ADR-0005-okf-alignment.md).[^adr-0005]
5. **Dogfood:** this catalog wiki migrates with the skill rewrite. Change size is acceptable (personal project).
6. **No strict write-lock.** Wiki writes are **involved** only: show the plan, then edit in the same turn unless the user stops. Quality is ingest-small + lint + git, not a mutex. `--rebuild` / `--drop` / `--reset-paths` on the zg index stay confirmation-gated (index lifecycle, not wiki text).

# Why zg (including the 2026-08-28 post)

Karpathy's wiki already compiles synthesis. The engine's job is **find the right page/span**, not rerank a RAG corpus. The post's design matches that:

- **End-to-end one entry**: explore (vector) → focus (BM25/hybrid) → verify (rg). Query rewriting and model reranking are explicitly **not** in zg yet (`❌*` on the comparison table). We will not wait for them; ingest + `index.md` cover synthesis and synonymy.
- **Documents are a first-class extract**: Markdown by heading/section, not file blobs. Wiki pages with real headings become addressable units.
- **Context efficiency**: ranked snippets with path/location; stop when evidence is enough. Matches involved review (cite spans, do not paste whole pages).
- **Same index for wiki and raw/code**: glob/scope at query time, not a second product. BrowseComp-Plus is document Q&A, not only SWE.
- **Local incremental index**: CLI+MCP share `.zvec-grep/`; remote embeddings stay opt-in. Fits a git wiki of unpublished design notes.
- **Japanese**: rg verifies 固有名詞 without a tokenizer. Bootstrap keeps `local/potion-multilingual-128m` (not zg's product default `potion-code-16m-v2`). Upgrade path is `local/qwen3-embedding-0.6b` inside zg, not a second engine.

qmd still has a thicker rerank pipeline. That optimizes the wrong layer for this wiki (query-time RAG vs compile-once pages) and its defaults are a CJK footgun.

# Alternatives considered

- **Default to qmd because wiki is Markdown** — rejected: both index Markdown; zg already extracts MD by heading; qmd defaults fail Japanese FTS/embeddings.
- **Ship qmd + zg** — rejected: two indexes, two freshness clocks, extra routing. The post argues for **one** entry with multiple *modes*.
- **Keep coding skeleton as the only scaffold** — rejected: fights design/game/idea use.
- **Wait for zg query rewrite / rerank** — rejected: those are roadmap. Ingest is the compile step.

# Japanese (engine locked)

`index.md` + `x-zvec-aliases` (漢字 / カナ / English) remain the primary Japanese strategy. zg backup: hybrid for related pages, **rg for exact names**. Do not assume BM25/jieba is good Japanese. Do not switch engines to fix CJK; fix aliases and, if needed, the zg embedding model.

# zg-shaped architecture (adjustments to the earlier plan)

These are the deltas that appear once zg is not "any search box" but the post's product.

## Retrieval is staged, but `index.md` is still first

Karpathy query ≠ "open with zg". Order:

1. Read `index.md` (cheap, language-agnostic).
2. If the catalog is not enough or the wiki is large: **zg hybrid** scoped to `docs/wiki/**` (explore+focus).
3. If a name/path/alias is known: **zg rg** (verify). Japanese proper nouns skip to this step.
4. Widen globs to `docs/raw/` or code **only after** wiki evidence is insufficient.

Hot memory must list this order. Today's "search wiki via zg first" is the bug.

Do not invent zg flags in SKILL.md. Teach **when** (index / hybrid / rg / widen). `zg help query` owns **how**.

## One workspace index, query-time scope

zg's unit is the **workspace**, not a qmd collection. Bootstrap keeps one index (default discovery). Ingest/query/lint pass globs:

| Intent | Scope |
| --- | --- |
| Wiki query / related-page ingest | `docs/wiki/**` |
| Confirm a source claim | `docs/raw/**` (once that tree exists) |
| Implementation leftover / rename lint | code + docs, then rg |

Do not run two indexers. If `docs/raw/` is huge, **propose** narrower stored paths (`--reset-paths` needs confirmation) rather than adding qmd.

## Wiki files must be zg-extractable

Markdown is split **by heading**, and YAML frontmatter is its own chunk. Body sections use H1 so zg can return them. `title` and `description` replace the H1 title and the lead line. Stubs with only a title still rank and still answer nothing — keep that warning.

Put retrieval names in frontmatter `x-zvec-aliases` on the owning page (not only the glossary) so rg/fts can hit カナ and English from that file. Do not copy them into an aliases heading.[^adr-0005]

## Ops mapped to zg modes

| Op | zg-shaped behavior |
| --- | --- |
| **Query** | index.md → wiki-scoped hybrid → rg for names → widen |
| **Ingest** | Read raw (immutable). Find homes with wiki-scoped hybrid **and** rg on aliases. Compile into few pages. Update `index.md` + `log.md`. Incremental `zg index`. Do not compile a whole codebase into wiki. PDF/Office: convert to Markdown first (zg does not extract them; post marks this `❌*`) |
| **Lint** | Orphans = files vs `index.md`. Renames = rg. Semantic staleness = wiki-scoped hybrid vs code/raw. Show findings, then edit (involved) |
| **Log** | OKF `## YYYY-MM-DD`, newest first, with the operation in bold. Complementary to zg (timeline vs retrieval). The first rewrite used `## [YYYY-MM-DD] kind \| title`; [ADR-0005](ADR-0005-okf-alignment.md) replaced it.[^adr-0005] |
| **Checkpoint** | **Involved only.** No page-kind write-lock |
| **Stop** | Same as the post: stop searching once ranked evidence is enough |

## Index lifecycle stays CLI-owned

Unchanged guardrail: incremental `zg index` after wiki edits is routine. `--rebuild` / `--drop` / `--reset-paths` need confirmation. Skill does not assume MCP index tools exist.

After ingest, prefer waiting for a fresh index before the next query (`zg status` / freshness) so the agent does not search the pre-ingest snapshot.

## Embedding default for this skill

Product default in the post is `local/potion-code-16m-v2`. **This skill keeps `local/potion-multilingual-128m`** for Japanese/docs. Document `qwen3-embedding-0.6b` as a same-engine quality upgrade (rebuild, user-confirmed).

## What we will not architect for

- Query-time LLM rerank or HyDE (qmd; zg roadmap).
- Native PDF ingest.
- Dual MCP search tools.
- Copying zg CLI into SKILL.md.

# Implemented first rewrite

Target packages: `skills/zvec-llm-wiki/zvec-llm-wiki/` and `zvec-llm-wiki-ja/`, updated in lockstep.

1. **Scaffold** — `index.md` (grouped by kind), `log.md`, `sources/`, `entities/`, `concepts/`, `analyses/`. Optional overlay: `decisions/`, `runbooks/`. Optional `raw/` convention in the schema (immutable; not created full of binaries).
2. **Hot memory** — wiki path, **read index first**, then wiki-scoped zg; involved writes (plan then edit); incremental `zg index`.
3. **SKILL.md** — ingest / query / lint / record / crystallize; staged zg routing; involved only (no strict); stop rule; PDF caveat; multilingual default.
4. **Templates** — headingful pages with frontmatter `aliases` (no body alias list); log prefix; ADR and runbook templates for the coding overlay.
5. **references/wiki-workflow.md** — replace "optional qmd-style search" with the staged table above; coding overlay documented separately.
6. **This catalog's wiki** — migrate to Karpathy kinds in the same change as the skill rewrite (glossary/architecture/gotchas/runbooks re-filed; ADRs can remain `decisions/` as the coding overlay).

That list is the 2026-09 rewrite. `sources/`, frontmatter `aliases`, and the old log heading named there are not the current contract. [ADR-0005](ADR-0005-okf-alignment.md) replaced them with `summaries/`, `x-zvec-aliases`, and the OKF log.[^adr-0005]

# Ideas from [awesome-llm-wiki](https://github.com/gavischneider/awesome-llm-wiki) (filter)

Reviewed against this ADR. **Take** (skill/schema, no new engine). **Later** (optional). **Skip** (conflicts).

## Take into the rewrite

- **One-line lead + headings** — indexes stay short because `description` is one sentence, and body sections are H1 so zg can extract them. The first rewrite put the lead in the body and used H2; [ADR-0005](ADR-0005-okf-alignment.md) moved the lead into frontmatter.[^adr-0005]
- **Relative `.md` links + link lint** — relative links work in GitHub and local viewers. Lint: every wiki file is in `index.md` and every link resolves. `[[wikilinks]]` are rejected; OKF uses Markdown links.
- **Thin frontmatter** — retrieval names stay out of the body. The first rewrite used `status` (`working`|`decided`), `aliases`, and `source` (root `raw/`). [ADR-0005](ADR-0005-okf-alignment.md) replaces those keys. A duplicated aliases heading was tried for heading extract and superseded 2026-09-10: zg already chunks frontmatter, and the second list drifted.[^adr-0005]
- **Contradiction isolation** — Hermes: conflicting claims get a visible conflict note (or `analyses/` page), not a silent merge. Lint owns this.
- **Split oversized pages** — Hermes file-size threshold. Keeps zg chunks addressable.
- **Crystallize** — file a good query answer into `analyses/` (Karpathy query-can-be-filed; vanillaflava crystallize).
- **Source freshness** — a concept records the path in `sources`. Do not hash the codebase or a `docs/raw/` dump. A change in the concept's meaning is `I204` (verification older than `generated.at`); a known review cycle is `stale_after` (`I201` once it passes). Lint prints both as the OKF change report.[^adr-0005]
- **Two ingest depths (Wiki v3 “open stacks vs restricted”)** — already our layer rule, name it: living docs = deep compile; code = zg without compiling.
- **Preserve dead ends** — research “append-only convention”: rejected ideas stay, marked superseded. Don’t delete history to look consistent.
- **Skill description verbs** — ingest / query / lint / crystallize as natural-language triggers (FelipeOFF-style), still one skill.

## Later (not in the first rewrite)

[Deferred wiki tooling](../concepts/deferred-wiki-tooling.md) records the outcome. Wikilinks, a bundled PDF converter, symbol-level code checks, a log-append script, and hashing `docs/raw/` are not scheduled. OKF already checks log headings, links, and the change report (`I204`, `I201`).

## Skip

- qmd or a second search MCP.
- Write-gates / Review Autopilot / SHA write-lock on wiki text (strict).
- Dream-cycle daemons, cron gardeners, Neo4j, compiling the repo into wiki pages, FSRS/quizzes, Slack/Notion sync platforms.

"OKF-as-required" was on this skip list for the first rewrite. [ADR-0005](ADR-0005-okf-alignment.md) withdraws that skip: the wiki is an OKF v0.3 bundle.[^adr-0005]

# Checkpoint (no strict write-lock)

Karpathy: the LLM writes the wiki; the human sources, reads summaries, and steers. There is no approve-before-write mutex. Hallucinated "rules" are handled by small ingest, lint, git, and OKF `status` (`draft` or `deprecated`), not a second skill mode.[^adr-0005]

**involved:** show pages (and zg spans when useful), then write unless the user interrupts.

**Not a wiki lock:** zg `--rebuild` / `--drop` / `--reset-paths` still need explicit confirmation.

# Consequences

- Skill identity stays `zvec-llm-wiki`: wiki governance + **when** to use zg.
- Japanese quality work happens in aliases, headings, and embedding choice — not a second engine.
- Agents that ignore index.md and dump zg hits will still waste tokens; the skill must make the stop/stage rules short enough to be followed.
- Revisit this ADR only if a large Japanese-only vault shows multilingual potion + rg + aliases failing synonym query that a configured Qwen rerank stack would catch **after ingest is already healthy**.

# References

- [Conventions](../concepts/conventions.md)
- [Catalog layout](../concepts/catalog-layout.md)
- [Deferred wiki tooling](../concepts/deferred-wiki-tooling.md)
- zg embeddings: https://zvec.org/en/docs/zvec-grep/embedding-models/
- qmd CJK FTS (why not default qmd): https://github.com/tobi/qmd/issues/617

[^adr-0005]: ADR-0005: Align the LLM wiki with OKF v0.3

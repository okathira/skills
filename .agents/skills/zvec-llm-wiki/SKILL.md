---
name: zvec-llm-wiki
description: Ingests, queries, lints, records, and crystallizes a project's LLM wiki (docs/wiki/), an Open Knowledge Format (OKF) v0.3 bundle, with zvec-grep (zg). Use for LLM wiki, living docs, knowledge bases, wiki maintenance, summaries, entities, concepts, analyses, ADRs, or runbooks. Not for web search or non-wiki Markdown.
license: MIT
---

# Maintaining an OKF LLM wiki with zvec-grep

## Overview

Run `docs/wiki/` as a living, compounding knowledge system shared by people and agents. The wiki
is an [OKF v0.3](https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md)
bundle. `zg` (zvec-grep) is the single retrieval engine. The loop is:

> **Query → Work → Ingest/Record/Crystallize → Lint → incremental `zg --index`**

This skill owns the loop and the llm-wiki extensions. The official sibling skills own the format:

- **`okf-generate`** — how to write concepts, frontmatter, `sources` footnotes, lifecycle, index
  and log files, and `scripts/validate.py`. Follow it for every write.
- **`okf-consume`** — how to judge trust tier, status, freshness, and conflicts when answering.

Wiki writes are **involved**: show the pages and intended changes, then edit in the same turn
unless the user stops you. Keep changes small and evidence-linked. Only destructive index
operations require prior approval.

## Wiki structure

Principle: **one home per fact; link instead of copying.** Each directory maps to one `type`:

```
docs/wiki/                # bundle root; index.md carries okf_version, title, description
  index.md  log.md        # generated directory index; newest-first log
  summaries/   Reference        # source summaries and provenance
  entities/    Entity           # people, systems, projects, products
  concepts/    Concept          # terms, patterns, rules, ideas
  analyses/    Analysis         # syntheses and crystallized answers
  decisions/   Decision Record  # optional coding overlay: ADRs
  runbooks/    Playbook         # optional coding overlay: procedures
docs/raw/                     # optional immutable imports; outside the bundle, so not concepts
```

Executable code is raw evidence: index and query it, but do not compile the codebase into pages.
Convert PDF/Office to Markdown before ingest and keep that Markdown in `docs/raw/`. Cite repository
files with paths relative to the page; they resolve outside the bundle, so OKF treats them as
external. Never use `[[wikilinks]]`.

## Operations

### Query

1. Read `docs/wiki/index.md`, then only the directory indexes the task needs.
2. If indexes are insufficient, use zg hybrid search scoped to `docs/wiki/**`.
3. For a known name, path, alias, or Japanese proper noun, use zg managed rg (or native `rg`).
4. Widen to `docs/raw/**` or code only when wiki evidence is insufficient.
5. Stop when ranked evidence is enough. Report trust, status, and staleness as `okf-consume` says;
   follow `superseded_by` instead of answering from a deprecated page.

### Ingest and record

- Show the page plan, then proceed unless interrupted.
- Find existing homes using wiki-scoped hybrid plus rg on exact aliases.
- Deep-compile documents into a few short concepts; shallow-index code without compiling it.
- Write per `okf-generate`, plus the llm-wiki keys in `references/wiki-workflow.md`: `type` from the
  directory, `x-zvec-aliases`, and `generated` on every change in meaning.
- Add `verified` only when a person confirmed the content and stated an id such as `human:owner`.
- Append `log.md`, then run `python3 <skills-dir>/zvec-llm-wiki/scripts/llm_wiki.py index` to
  regenerate indexes.
- Preserve rejected approaches: mark replaced pages `status: deprecated` with `superseded_by`.

### Crystallize

File a durable, well-supported query result as an Analysis under `analyses/`, without duplicating
its facts into other pages. Log the operation.

### Lint

Run lint from the project root and fix findings before relying on the wiki. It runs `okf-generate`'s
`validate.py` (installed next to this skill, for example `.agents/skills/`) for OKF conformance and
links, then adds the llm-wiki checks and index freshness:

```bash
python3 <skills-dir>/zvec-llm-wiki/scripts/llm_wiki.py lint --strict
```

Lint reports every `validate.py` finding. A Markdown file inside the bundle without `type` is W120;
OKF keeps that warning for files such as a README, so immutable imports stay in `docs/raw/`.

Then judge what scripts cannot: contradictions isolated rather than merged, oversized pages split,
stale names after renames (rg), superseded claims still visible, and aliases that name only this
page's fact. Details are in `references/wiki-workflow.md`.

After wiki edits, run incremental `zg --index`, then `zg --status`/freshness before relying on a new
query.

## zg usage

This skill defines **when**, not CLI syntax. Run `zg --help search`, `zg --help index`, `zg --help
install`, or `zg --help models`; do not invent flags. One workspace index serves wiki, references, and
code through query-time scopes. Keep the multilingual default `local/potion-multilingual-128m`;
Compare `local/embeddinggemma-300m` and `local/qwen3-embedding-0.6b` when evaluating retrieval quality.
A supported CUDA or Metal runtime can accelerate either model. Switching an existing index requires
an explicit rebuild and user approval. Do not add qmd or a second indexer.

## Bootstrap and migration

```bash
bash scripts/zg-bootstrap.sh                          # auto-detect agents
bash scripts/zg-bootstrap.sh --target cursor codex    # explicit targets; see zg --help install
bash scripts/zg-bootstrap.sh --embedding <model>      # override default wiki embedding (list: zg --help models)
```

Requires Node.js 22+ and Python 3.9+ with PyYAML. The script scaffolds an OKF bundle only when
`docs/wiki/` is absent, upserts the `AGENTS.md` hot block, configures zg, and builds or incrementally
updates one index. An existing wiki is untouched. A wiki without `type` frontmatter predates OKF:
use the `zvec-llm-wiki-okf-migrate` skill.

Never run `--rebuild`, `--drop`, or `--reset-paths` without explicit user approval.

For a plugin install, pass `--skip-mcp` from the target project's root so the plugin owns the
MCP connection. Pass the target project's absolute path as `root` when using MCP search.

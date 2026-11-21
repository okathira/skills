---
type: Concept
title: Deferred wiki tooling
description: Ideas once deferred for the wiki loop, now closed because OKF already covers them or they sit outside OKF.
x-zvec-aliases:
  - closed tooling
  - deferred ideas
  - optional wiki tooling
  - Obsidian wikilinks
  - markitdown
generated: { by: "cursor/auto", at: "2026-11-20T17:55:00Z" }
verified:
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
  - { by: "human:owner", at: "2026-11-20T15:51:00Z" }
  - { by: "human:owner", at: "2026-11-20T17:56:00Z" }
sources:
  - id: adr-0003-karpathy-alignment-plan
    resource: /decisions/ADR-0003-karpathy-alignment-plan.md
    title: "ADR-0003: Karpathy alignment with a single zg engine"
---

# Obsidian and wikilinks

`[[wikilinks]]` will not be supported. OKF links are standard Markdown links, and this catalog uses paths relative to the page because they also render on GitHub. `llm_wiki.py lint` already rejects a wikilink.

# PDF and Office conversion

This skill will not bundle a converter. OKF has no conversion step. zg still cannot read PDF or Office files, so an ingest of those formats starts from Markdown the author already produced.

# Code claim verification

This skill will not check that a function or symbol still matches a wiki sentence. OKF's mechanical check of an executable definition is an Attested Computation, which this wiki does not use. Cite code with a `sources` path.

# Deterministic maintenance helpers

[ADR-0005](../decisions/ADR-0005-okf-alignment.md) shipped `llm_wiki.py index` and uses `okf-generate`'s `validate.py` for links and for the `log.md` date headings (`E005`, `E006`, `W118`). This skill will not add a script that appends log entries. `validate.py` is the check OKF defines.

Detecting a changed file in `docs/raw/` by hashing it is not an OKF mechanism, and this wiki will not add that lint. OKF records a source's `last_modified` only when the author knows it, and sets `stale_after` only for a known review cycle.

# OKF change report

`validate.py` already detects the two changes OKF defines, and `llm_wiki.py lint` prints them as the OKF change report. They are info findings, so `--strict` does not fail on them:

- `I204`: every `verified` event is older than `generated.at`, so the concept is unverified after a change in meaning.
- `I201`: the current time is at or after `stale_after`.

`okf-consume`'s `scan.py` lists the same facts with `--unverified` and `--stale` when answering a question.

# Related

- [Conventions](conventions.md)
- [ADR-0005](../decisions/ADR-0005-okf-alignment.md)

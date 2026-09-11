---
status: proposed # proposed (working) | accepted (decided) | superseded
date: YYYY-MM-DD
deciders: <names>
aliases:
  - ADR-NNNN
  - <high-signal name for this decision>
  - <short form agents type>
source: <path, URL, or omit this key>
---

# ADR-NNNN: <short decision title>

One-line statement of the decision this page owns.

## Context
What problem/force required a decision? Link to code or issues. Keep to the facts.

## Decision
What we chose, stated in one or two sentences.

## Why (rationale)
The reasoning a code scan cannot recover: trade-offs, constraints, assumptions.

## Alternatives considered
- **Option A** — rejected because ...
- **Option B** — rejected because ...

## Consequences
Positive, negative, and follow-ups. What becomes easier/harder. What to watch for (gotchas).

## References
Wiki graph only. Do not restamp `source` URLs or paths here.

<!-- Register this ADR with a one-line summary in docs/wiki/index.md, append log.md, then run
incremental `zg index`. Keep status, date, deciders, superseded_by, aliases, and source only in
frontmatter. Omit empty keys; add superseded_by only when replaced. -->

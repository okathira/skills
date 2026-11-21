---
type: Decision Record
title: "ADR-NNNN: <short decision title>"
description: <One sentence stating the decision this page owns.>
status: draft
x-zvec-aliases:
  - ADR-NNNN
  - <high-signal name for this decision>
  - <short form agents type>
generated: { by: "<tool>/<model>", at: "<YYYY-MM-DDTHH:MM:SSZ>" }
sources:
  - id: <source-id>
    resource: <URL or repository path relative to this page>
    title: <Source title>
---

# Context
What problem/force required a decision? Link to code or issues. Keep to the facts.[^<source-id>]

# Decision
What we chose, stated in one or two sentences.

# Why (rationale)
The reasoning a code scan cannot recover: trade-offs, constraints, assumptions.

# Alternatives considered
- **Option A** — rejected because ...
- **Option B** — rejected because ...

# Consequences
Positive, negative, and follow-ups. What becomes easier/harder. What to watch for (gotchas).

# References
Wiki graph only. Do not restamp `sources` here.

[^<source-id>]: <Source title>

<!-- Proposed = status: draft. On acceptance, remove status and record the acceptance as a
verified event only when the decider confirms and states an id, for example
verified: [{ by: "human:owner", at: "<now>" }]. When replaced, set status: deprecated and
superseded_by: /decisions/ADR-MMMM-....md. Append log.md, run llm_wiki.py index, then `zg.sh --index`. -->

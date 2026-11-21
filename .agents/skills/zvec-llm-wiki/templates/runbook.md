---
type: Playbook
title: "Runbook: <task this procedure completes>"
description: <One sentence stating what this procedure achieves and when to run it.>
x-zvec-aliases:
  - <procedure short name>
  - <command or script agents type>
  - <when-to-run phrase>
generated: { by: "<tool>/<model>", at: "<YYYY-MM-DDTHH:MM:SSZ>" }
sources:
  - id: <source-id>
    resource: <script path relative to this page, or URL>
    title: <Source title>
---

# Prerequisites
Tools, versions, access, and the directory the steps assume.

# Steps
Numbered, copy-pasteable commands with the expected result of each stage.[^<source-id>]

# Verification
How to confirm success, including the command whose output proves it.

# Troubleshooting
| Issue | Action |
|-------|--------|
| <observed failure> | <fix, or the page that owns it> |

# Related
Cross-links to the concepts, entities, or decisions this procedure depends on.

[^<source-id>]: <Source title>

<!-- Record verified facts on their owning page instead of duplicating them here. Append log.md,
run llm_wiki.py index, lint, then incremental `zg.sh --index`. -->

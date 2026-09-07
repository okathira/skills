---
name: zvec-llm-wiki
description: Maintains a project's LLM wiki (docs/wiki/) with zvec-grep (zg) so agents read knowledge before acting and record after verification. Use for LLM wiki, living docs, zvec-grep, zg, ナレッジベース, wiki整備, conventions, ADRs, or gotchas. Not for web search or non-wiki Markdown.
license: Proprietary. Internal use.
---

# Maintaining an LLM wiki with zvec-grep

## Overview

Run the project's documentation as a **living system** that both humans and agents share.
`zg` (zvec-grep) is the retrieval layer; `docs/wiki/` is the source of truth. The loop is:

> **Read (zg) → Work → Verify with the human → Record (edit wiki) → Re-index (zg index)**

Two non-negotiable rules keep this trustworthy:

1. **Human is the checkpoint.** After work is verified, **propose** wiki updates (what page, what
   to add). Record only when the user approves. Never silently write docs — a wrong result would
   become a "rule" the next session trusts. Structural changes should include wiki/ADR updates in
   the **same PR** once approved.
2. **The agent never mutates the index lifecycle on its own.** You MAY run `zg index`
   (incremental update) *after wiki edits* as a routine refresh, but you MUST NOT run
   `--rebuild`, `--drop`, or `--reset-paths` without explicit user confirmation.

If `zg` is not installed or no index exists, follow **Bootstrap** below. Until bootstrap succeeds,
use normal search tools to read code — but do **not** update the wiki from unverified guesses.

## Wiki structure (docs/wiki/)

Principle: **one home per fact, cross-reference instead of copy.** Separate *what* (auto-derivable
from code) from *why* (human intent).

```
docs/wiki/
  index.md          # entry map: what lives where (the registry)
  glossary.md       # domain terms, acronyms, one-line definitions
  architecture.md   # components, boundaries, data flow (the "what")
  decisions/        # ADRs: one file per decision, the "why" (ADR-0001-*.md)
  conventions.md    # naming, patterns, do/don't
  gotchas.md        # sharp edges: "we don't touch X because ..."
  runbooks/         # how to build, test, deploy, release
```

Use `templates/adr.md` and `templates/wiki-page.md` as starting points. Keep each page short;
link, don't duplicate. Governance details: `references/wiki-workflow.md`.

## When to use zg (and when not to)

This skill defines **when and why** to search. For flags, models, MCP setup, and transport, run
`zg help`, `zg help query`, `zg help index`, `zg help install`, or `zg help models` — do not copy
or invent zg syntax from this skill.

### Retrieval routing

| Situation | Route |
|---|---|
| Meaning, cross-file context, or location unknown | zg indexed search (MCP tool from `zg install` if available; tool name varies by client) |
| Exact identifier, path, regex, or rename leftovers | Native grep/rg, or zg managed rg — see `zg help query` |
| Task starts | Scope to `docs/wiki/**` first; widen to code only when wiki evidence is not enough |
| Checking whether related material exists locally | One focused semantic probe; stop when results are enough or irrelevant |

**Wiki scope is a skill contract:** when reading the wiki first, always pass `docs/wiki/**` as the
search scope (MCP or CLI). How to pass scope depends on the installed zg — ask `zg help query`, do
not guess flags from this skill.

Index lifecycle (`zg index`, `zg status`) stays on the CLI. Do not assume optional MCP index or
managed-rg tools exist unless the installed zg exposes them.

Stop searching once ranked evidence is enough — do not read whole files "just in case".

### Index scope (project judgment)

Bootstrap uses zg's default file discovery for the first index — this skill does not assume a
`src/` layout. After inspecting the repository, **propose** narrower or wider index paths when the
defaults miss important code or index too much noise. Changing stored paths requires
`--reset-paths` or `--rebuild`; both need explicit user confirmation.

## Record after verifying

When the user confirms the work is correct:

1. **Propose** what to record: which page owns the fact, whether an ADR is needed, and a short
   draft. Wait for approval before editing.
2. **Find the single home** — search scoped to `docs/wiki/**` for the topic. Update that page;
   if none exists, create one under the right section and add it to `index.md`.
3. **Write the *why*, not just the *what*.** For structural/architectural decisions, add or
   update an ADR in `decisions/` (use `templates/adr.md`).
4. **Cross-reference** related pages instead of copying prose.
5. **Re-index** after edits: incremental `zg index`, then `zg status` to confirm readiness.

Keep diffs small and reviewable — the user reviews wiki changes like code.

## Bootstrap (first time in a repo)

Run `scripts/zg-bootstrap.sh` from this skill package. It is idempotent and non-destructive:

```bash
bash scripts/zg-bootstrap.sh                          # auto-detect agents
bash scripts/zg-bootstrap.sh --target cursor codex    # explicit targets; see zg help install
bash scripts/zg-bootstrap.sh --embedding <model>      # override default wiki embedding (list: zg help models)
```

Requires Node.js 22+. The script puts `zg` on PATH (`npm install -g` if missing — required because
`zg install` writes MCP `command: zg` and does not install the package), scaffolds `docs/wiki/`,
upserts `AGENTS.md` hot memory, runs `zg install`, and builds the first index with zg default
discovery. Restart the agent after MCP configuration.

For manual setup or troubleshooting, follow `zg help` and `zg help install`.

## Guardrails

- Do **not** run `--rebuild`, `--drop`, `--reset-paths` without explicit confirmation.
- Do **not** update the wiki from unverified work, or copy the same fact into two files.
- Do **not** flood context: prefer ranked zg evidence over opening full files.
- Do **not** duplicate zg documentation here — the installed CLI is the source of truth.

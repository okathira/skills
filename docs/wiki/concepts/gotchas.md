---
type: Concept
title: Gotchas
description: Sharp edges observed while dogfooding zvec-llm-wiki in this catalog.
x-zvec-aliases:
  - sharp edges
  - pitfalls
  - dogfooding pitfalls
  - heading-only stubs
  - MCP zg PATH
  - stale skill install
generated: { by: "codex/gpt-6.2-sol", at: "2026-11-21T10:56:45Z" }
verified:
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
sources:
  - id: zg-bootstrap-sh
    resource: ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
    title: zvec-llm-wiki bootstrap script
  - id: llm-wiki-py
    resource: ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/llm_wiki.py
    title: zvec-llm-wiki index and lint script
---

# Do not commit `.zvec-grep/`

The bootstrap creates a local index under `.zvec-grep/`. It is not source of truth and must remain gitignored.

# Install and bootstrap are separate

- `install.sh` copies a skill package into an agent skill directory (default: `.agents/skills/` in the repo — commit it).
- `zg-bootstrap.sh` configures a target project wiki, hot memory, **project MCP**, and the index.

Running bootstrap from inside the skill package wires the wrong workspace.[^zg-bootstrap-sh]

Bootstrap does not copy `SKILL.md`. After catalog updates to the package, re-run `install.sh --force` and commit `.agents/skills/`, or the agent keeps a stale runtime copy.

# Do commit project skills and MCP

- `.agents/skills/<name>/` — runtime skill the agent loads (default install).
- `.cursor/mcp.json` — Cursor project MCP ([Cursor MCP](https://cursor.com/docs/mcp)).
- `.mcp.json` — Claude Code project MCP (repo root).

User-level `~/.agents/skills/` and `~/.cursor/mcp.json` are not shared with Cloud Agents or teammates.

# User-level `zg --install` vs project MCP

`zg --install --target cursor` writes `~/.cursor/mcp.json` with `command: zg` and does not install the npm package. Prefer committed project MCP with an `npx` launcher for the pinned zvec-grep package from bootstrap. Re-running that upsert keeps compatible fields such as `env` and refuses to merge an existing HTTP `zvec_grep` entry into the stdio command. Use `zg --install --target codex` (etc.) only when you need that agent's **user-level** config. Bootstrap's `--target` does the same install, and when `zg` is not already on PATH it installs `@zvec/zvec-grep` globally and checks that `zg` launches first. A one-shot `npx` install does not leave a `zg` binary for those user-level entries.

# Do not create heading-only stubs

Heading-only pages rank in semantic search but provide no evidence. The scaffold creates category directories plus useful `index.md` and `log.md`, not empty topic pages. `llm_wiki.py index` writes no index for an empty directory for the same reason.[^llm-wiki-py]

# Index files are generated

`llm_wiki.py index` rewrites every `index.md` below the root frontmatter from page `title` and `description`. Hand edits to entries are lost; fix the page frontmatter instead. Section headings and directory descriptions already in an index are kept.[^llm-wiki-py]

# Markdown without type does not belong in the bundle

`validate.py` warns W120 for a Markdown file that is not a concept, and `--strict` fails on that warning. OKF keeps this for files such as a README. An immutable import is not a README: put it in `docs/raw/`, outside `docs/wiki/`, and cite it with a path relative to the page. Do not special-case the validator.

# Python and PyYAML are prerequisites

`llm_wiki.py`, the migration script, and `okf-generate`'s `validate.py` need Python 3.9+ with PyYAML. macOS system Python ships without PyYAML; run `pip3 install --user pyyaml`. In a sandboxed agent shell, that install needs network access to PyPI.

# Japanese retrieval needs aliases

Do not assume BM25 tokenization handles Japanese proper nouns. On a Japanese wiki, keep Kanji, Kana, and English names in frontmatter `x-zvec-aliases` on the owning page and use exact rg when a name is known.

This catalog wiki is English. Prefer English ubiquitous-language aliases; see [Conventions](conventions.md).

# Related

- [Skill setup runbook](../runbooks/skill-setup.md)
- [ADR-0004](../decisions/ADR-0004-project-skill-install.md)
- [Conventions](conventions.md)

[^zg-bootstrap-sh]: zvec-llm-wiki bootstrap script
[^llm-wiki-py]: zvec-llm-wiki index and lint script

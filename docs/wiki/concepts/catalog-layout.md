---
type: Concept
title: Agent Skills catalog layout
description: Repository layout and the boundary between distributable skills, raw code, and compiled wiki knowledge.
x-zvec-aliases:
  - repository layout
  - catalog architecture
  - layer boundaries
  - raw vs wiki
  - skills directory
generated: { by: "cursor/auto", at: "2026-11-20T11:07:00Z" }
verified:
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
sources:
  - id: readme
    resource: ../../../README.md
    title: Agent Skills catalog
  - id: readme-ja
    resource: ../../../README.ja.md
    title: Agent Skills catalog (Japanese)
---

# Layout

```text
skills/
  README.md
  README.ja.md
  skills/
    zvec-llm-wiki/
      zvec-llm-wiki/
      zvec-llm-wiki-ja/
    zvec-llm-wiki-okf-migrate/
      zvec-llm-wiki-okf-migrate/
      zvec-llm-wiki-okf-migrate-ja/
  docs/raw/                # optional immutable imports; outside the OKF bundle
  docs/wiki/               # OKF bundle root
    index.md               # okf_version, title, description; generated entries
    log.md
    summaries/             # empty until a source is ingested
    entities/
    concepts/
    analyses/
    decisions/
    runbooks/
  AGENTS.md
  .agents/skills/          # committed runtime installs: zvec-llm-wiki, okf-generate, okf-consume, migrate
  .cursor/mcp.json         # committed Cursor MCP (bootstrap)
  .mcp.json                # committed Claude Code MCP (bootstrap)
```

Skill packages are self-contained folders with `SKILL.md`, `install/`, `scripts/`, `references/`, and `templates/`. The package under `skills/` is the distributable source; `.agents/skills/` is the agent runtime copy ([ADR-0004](../decisions/ADR-0004-project-skill-install.md)).

# Layer boundaries

- **Raw:** executable code and package files, plus optional imports in `docs/raw/`. The wiki links to them; it does not compile the whole tree into prose.
- **Wiki:** living project knowledge under `docs/wiki/`, an OKF v0.3 bundle ([ADR-0005](../decisions/ADR-0005-okf-alignment.md)).
- **Schema / hot memory:** the marked block in `AGENTS.md` plus the installed skill.
- **Human landing pages:** root `README.md` and `README.ja.md` remain outside the wiki as installer UI.

# Install vs bootstrap

| Step | Script | Result |
|------|--------|--------|
| Install the skill | `skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh` | Copies the package and fetches `okf-generate` / `okf-consume` into `.agents/skills/` (default; commit) or `~/.agents/skills/` with `--user` |
| Bootstrap a project | `skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh` | OKF wiki scaffold, hot memory, committed `.cursor/mcp.json` / `.mcp.json`, and zg index |
| Migrate a pre-OKF wiki | `zvec-llm-wiki-okf-migrate` skill | One-time conversion plus a human review that records `verified` |

The local `.zvec-grep/` index is gitignored and is never the source of truth.

# Related

- [Conventions](conventions.md)
- [Glossary](glossary.md)
- [Skill setup runbook](../runbooks/skill-setup.md)
- [ADR-0001](../decisions/ADR-0001-locale-independence.md)
- [ADR-0002](../decisions/ADR-0002-catalog-skills-directory.md)

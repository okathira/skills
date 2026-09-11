---
status: decided
aliases:
  - repository layout
  - catalog architecture
  - layer boundaries
  - raw vs wiki
  - skills directory
source:
  - ../../../README.md
  - ../../../README.ja.md
---
# Agent Skills catalog layout

> This page owns the repository layout and the boundary between distributable skills, raw code, and compiled wiki knowledge.

## Layout

```text
skills/
  README.md
  README.ja.md
  skills/
    zvec-llm-wiki/
      zvec-llm-wiki/
      zvec-llm-wiki-ja/
  docs/wiki/
    index.md
    log.md
    sources/
    entities/
    concepts/
    analyses/
    decisions/
    runbooks/
  AGENTS.md
```

Skill packages are self-contained folders with `SKILL.md`, `install/`, `scripts/`, `references/`, and `templates/`.

## Layer boundaries

- **Raw:** executable code and package files. The wiki links to them; it does not compile the whole tree into prose.
- **Wiki:** living project knowledge under `docs/wiki/`.
- **Schema / hot memory:** the marked block in `AGENTS.md` plus the installed skill.
- **Human landing pages:** root `README.md` and `README.ja.md` remain outside the wiki as installer UI.

## Install vs bootstrap

| Step | Script | Result |
|------|--------|--------|
| Install the skill | `skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh` | Copies the package into an agent skill directory |
| Bootstrap a project | `skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh` | Creates a new wiki, hot memory, MCP wiring, and one zg workspace index |

The local `.zvec-grep/` index is gitignored and is never the source of truth.

## Related

- [Conventions](conventions.md)
- [Glossary](glossary.md)
- [Skill setup runbook](../runbooks/skill-setup.md)
- [ADR-0001](../decisions/ADR-0001-locale-independence.md)
- [ADR-0002](../decisions/ADR-0002-catalog-skills-directory.md)

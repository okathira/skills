---
status: decided
aliases:
  - sharp edges
  - pitfalls
  - dogfooding pitfalls
  - heading-only stubs
  - MCP zg PATH
source:
  - ../../../skills/zvec-llm-wiki/zvec-llm-wiki/scripts/zg-bootstrap.sh
---
# Gotchas

> Sharp edges observed while dogfooding zvec-llm-wiki in this catalog.

## Do not commit `.zvec-grep/`

The bootstrap creates a local index under `.zvec-grep/`. It is not source of truth and must remain gitignored.

## Install and bootstrap are separate

- `install.sh` copies a skill package into an agent directory.
- `zg-bootstrap.sh` configures a target project wiki, hot memory, MCP, and the index.

Running bootstrap from inside the skill package wires the wrong workspace.

## Do not create heading-only stubs

Heading-only pages rank in semantic search but provide no evidence. The new scaffold creates category directories plus useful `index.md` and `log.md`, not empty topic pages.

## The MCP command needs a global zg

`zg install` configures MCP with `command: zg`; it does not install the npm package. Bootstrap installs `@zvec/zvec-grep` globally if the command is absent.

With nvm, switching Node versions can remove zg from `PATH`; reinstall it globally and restart the agent.

## Japanese retrieval needs aliases

Do not assume BM25 tokenization handles Japanese proper nouns. On a Japanese wiki, keep Kanji, Kana, and English aliases in YAML `aliases` on the owning page and use exact rg when a name is known.

This catalog wiki is English. Prefer English ubiquitous-language aliases; see [Conventions](conventions.md).

## Related

- [Skill setup runbook](../runbooks/skill-setup.md)
- [Conventions](conventions.md)

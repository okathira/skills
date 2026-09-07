# Agent Skills catalog layout

> This page owns the repository layout and how skill packages relate to target projects.

## What

This repository is an [Agent Skills](https://agentskills.io/) catalog. Each skill is a self-contained folder with `SKILL.md`, `install/`, `scripts/`, `references/`, and `templates/`.

```
skills/                          # catalog root (this repo)
  README.md                      # English landing (GitHub default): policy + skill index
  README.ja.md                   # Japanese landing; keep in lockstep with README.md
  zvec-llm-wiki/                 # English skill package (default locale)
  ja/zvec-llm-wiki/              # Japanese locale variant
  docs/wiki/                     # compiled project knowledge (this wiki)
  AGENTS.md                      # hot memory / schema block for agents
```

**Raw sources** (immutable for wiki purposes): skill `SKILL.md`, package `README.md`, `install/install.sh`, and catalog [README.md](../../README.md) / [README.ja.md](../../README.ja.md).

**Retrieval layer**: [zvec-grep](https://github.com/zvec-ai/zvec-grep) (`zg`) indexes the workspace; agents search `docs/wiki/**` first via MCP or CLI.

**Two setup steps** (do not confuse):

| Step | Where | Script | Scope |
|------|-------|--------|-------|
| Install skill | Catalog or any path | `zvec-llm-wiki/install/install.sh` | Once per machine or per repo (`.agents/skills/`) |
| Bootstrap target repo | Project root | `zvec-llm-wiki/scripts/zg-bootstrap.sh` | Once per project (`docs/wiki/`, `AGENTS.md`, `.zvec-grep/`) |

`install.sh` copies only `SKILL.md`, `scripts/`, `references/`, `templates/` — not the catalog README or `install/` folder.

## Why / notes

- English packages live at repo root; Japanese under `ja/<skill-name>/`. See [conventions.md](conventions.md) and [decisions/ADR-0001-locale-independence.md](decisions/ADR-0001-locale-independence.md).
- `.zvec-grep/` is local index storage; gitignored, not source of truth.

## Related

- [conventions.md](conventions.md) — locale and naming rules
- [glossary.md](glossary.md) — terms
- [runbooks/skill-setup.md](runbooks/skill-setup.md) — install and bootstrap commands

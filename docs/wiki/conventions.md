# Catalog and wiki conventions

> This page owns locale policy, install boundaries, and wiki governance for this repo.

## What

### Language policy

- **English** is the default locale at repo root (`zvec-llm-wiki/`). Folder name matches skill `name` in `SKILL.md`.
- **Japanese** variants live under `ja/<skill-name>/` with a distinct `name` (e.g. `zvec-llm-wiki-ja`).
- **Independence**: each locale folder is a complete package. No symlinks or cross-locale runtime dependencies.
- **Skills**: behavior changes must update every locale the same way; pick one locale per install.
- **Catalog landing**: GitHub shows [README.md](../../README.md) (English). [README.ja.md](../../README.ja.md) is the Japanese counterpart. Same sections and facts; only natural language differs. Change both in the same edit. Language switcher and badges stay Markdown-only (no HTML wrappers).

Source: [README.md](../../README.md) and [README.ja.md](../../README.ja.md).

### Install vs bootstrap

| Action | Copies / creates | Does not copy |
|--------|------------------|---------------|
| `install.sh` | `SKILL.md`, `scripts/`, `references/`, `templates/` → `.agents/skills/<name>` | Catalog README, `install/` |
| `zg-bootstrap.sh` | `docs/wiki/` scaffold, `AGENTS.md` block, `.zvec-grep/` index, MCP via `zg install` | Skill files into agent dirs |

### Wiki loop (coding projects)

From the zvec-llm-wiki skill:

> **Read (zg) → Work → Verify with the human → Record (edit wiki) → Re-index (`zg index`)**

- Search scope before acting: `docs/wiki/**`
- Propose wiki edits after verification; record only on approval
- Never run `zg index --rebuild`, `--drop`, or `--reset-paths` without explicit user confirmation

## Why / notes

Adapted from [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): raw sources stay immutable; this wiki is the compiled layer; `AGENTS.md` is hot schema. Human checkpoint is intentional for coding agents (wrong wiki text becomes trusted rules next session).

## Related

- [architecture.md](architecture.md) — repo layout
- [decisions/ADR-0001-locale-independence.md](decisions/ADR-0001-locale-independence.md) — why locales do not symlink

# Gotchas

> Sharp edges observed while dogfooding zvec-llm-wiki in this catalog.

## Do not commit `.zvec-grep/`

Bootstrap creates a local index under `.zvec-grep/`. It is not source of truth. Add to `.gitignore` before the first commit after bootstrap.

## Two setup steps are easy to confuse

- **Install skill** (`install.sh`) → agent skill directory only
- **Bootstrap repo** (`zg-bootstrap.sh`) → `docs/wiki/`, `AGENTS.md`, index, MCP

Running bootstrap from inside `zvec-llm-wiki/` instead of the project root wires the wrong workspace.

## Empty wiki stubs rank in search but answer nothing

Bootstrap creates `# glossary`-style placeholders. Semantic search returns them with high rank until real content is ingested. Fill pages and re-index.

## `zg` via npx in non-interactive sessions

Bootstrap skips global `npm install -g` when stdin is not a TTY. Later `zg index` from an agent may fail unless `zg` is on PATH or invoked via `npx --yes @zvec/zvec-grep`.

## Related

- [runbooks/skill-setup.md](runbooks/skill-setup.md)

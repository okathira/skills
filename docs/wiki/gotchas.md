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

## MCP `command: zg` needs a global CLI

`zg install` writes Cursor MCP as `"command": "zg"` and **does not** install the npm package. An npx-only bootstrap used to leave `zvec_grep` in error (`zsh: command not found: zg`) while the index still existed under `.zvec-grep/`. Bootstrap now runs `npm install -g @zvec/zvec-grep` when `zg` is missing, then fails if `zg` is still not on PATH.

With nvm, the binary lives under the current Node version (`$(npm prefix -g)/bin/zg`). Switching Node versions drops `zg` from PATH — reinstall globally or the MCP server breaks again.

## Related

- [runbooks/skill-setup.md](runbooks/skill-setup.md)

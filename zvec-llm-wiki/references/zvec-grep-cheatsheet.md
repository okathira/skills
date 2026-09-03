# zvec-grep (zg) cheatsheet

Load this only when you need exact flags. The installed CLI is the source of truth:
`zg help`, `zg help query`, `zg help index`.

## Install & connect

```bash
npm install -g @zvec/zvec-grep     # Node.js 22+; no GPU needed with default model
# or without global install:
npx @zvec/zvec-grep help

zg install                          # auto-detect Codex / Claude Code / Cursor / OpenCode
zg install --target claude --yes    # or --target codex | qwen | cursor | opencode | all
```

- Agent-facing MCP: Streamable HTTP on loopback `http://127.0.0.1:7999/mcp`.
- **Default MCP toolset:** `zvec_grep_search` for semantic / hybrid workspace search. Exact
  symbol/path lookup uses the agent's native grep/rg or `zg query --rg`. Index lifecycle is
  CLI-only by design. Optional `full` toolset adds `zvec_grep_rg` via MCP.

### Tool names by agent

| Agent | Indexed search |
|---|---|
| Codex / Claude Code / Cursor | `zvec_grep_search` |
| OpenCode | `zvec_grep_zvec_grep_search` |
| Qwen / Qoder | `mcp__zvec_grep__zvec_grep_search` |

## Index management

```bash
zg index --embedding local/potion-code-16m-v2      # first build (default local model)
zg index -g "src/**" -g "docs/**" -g "!dist/**"    # scope a large repo on first build
zg index                                            # incremental update (reuses model + paths)
zg status                                           # files indexed, failures, next steps
zg status --check-ready                             # verify the index is queryable
zg index --rebuild --embedding <model>             # ONLY when changing embedding model
zg index --reset-paths                             # ONLY when include/exclude rules must change
zg index --drop --yes                              # destructive: delete the index
```

- Index lives in `<workspace>/.zvec-grep/`. `.git` and `.zvec-grep` are always excluded, plus
  dependency/build/cache/log dirs and whatever the repo's ignore rules exclude.
- Changing embedding model requires `--rebuild` (vector spaces are incompatible across models).
- **Agent rule:** never silently create/rebuild/delete a persistent index.

## Search routes (one `zg query` command)

| Route | Command | When |
|---|---|---|
| Hybrid (default) | `zg query "authentication flow"` | meaning, or meaning + keywords |
| BM25 exact terms | `zg query --fts "AuthService"` | rank known terms by relevance |
| Vector only | `zg query --vector "where credentials are validated"` | concept, no keyword |
| Managed ripgrep | `zg query --rg -n -F "AuthService" src` | exact / exhaustive / regex, no index needed |

Fuse intent with exact anchors into one ranked plan:

```bash
zg query --hybrid "authentication flow" --fts "ForbiddenError" --fuse --limit 10
```

## Narrow the workspace

```bash
zg query "plugin lifecycle" -g "src/**" -g "!src/generated/**" -t ts
```

| Option | Use |
|---|---|
| `-g, --glob` / `--iglob` | include/exclude paths (e.g. `-g "docs/wiki/**"`) |
| `-t, --type` / `-T, --type-not` | filter file types (`-t md`, `-t ts`) |
| `--modified-after` / `--modified-before` | filter by modification time |

## Control results & freshness

| Option | Effect |
|---|---|
| `--limit <n>` | max results per query group |
| `--human` | fuller, terminal-friendly previews |
| `--preview none\|short\|full` | indexed source preview size |
| `--refresh background\|wait\|off` | index freshness policy |
| `--debug` / `--trace` | query and per-hit diagnostics |

Indexed results report `fresh` or `possibly_stale`. Use `--refresh wait` only when the latest
file changes must be included.

## Improve weak results

1. `zg status` — confirm workspace root and index state.
2. Restrict to relevant paths / file types.
3. Add one or two concrete anchors with `--fts`.
4. Switch to `--rg` when the exact text is known.

## Notes

- `zg` rejects output-changing ripgrep flags (`--json`, `--count`, `-l`, `--vimgrep`) to keep the
  compact result format.
- Default embedding `local/potion-code-16m-v2` is a static (Model2Vec) model — a GPU does not
  speed it up. Remote embeddings require explicit opt-in (`--allow-remote` or `zg auth grant`).
- Structure-aware extraction covers C/C++/Go/Java/JS/TS/Python/Rust, heading-aware Markdown, and
  JSON/YAML/TOML/CSV/HTML/XML/plain text.

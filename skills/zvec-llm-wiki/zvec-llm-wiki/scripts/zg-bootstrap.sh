#!/usr/bin/env bash
# Bootstrap zvec-grep + an LLM wiki in the current repo.
# Idempotent and non-destructive: it never rebuilds/drops an existing index.
#
# Usage:
#   ./zg-bootstrap.sh [--target <agent>]... [--embedding <model>] [--skip-mcp]
#   ./zg-bootstrap.sh                    # auto-detect agents (zg install)
#
set -euo pipefail

TARGETS=()
EMBEDDING="local/potion-multilingual-128m"
EMBEDDING_EXPLICIT=0
SKIP_MCP=0
# Synced from plugins/zvec-grep.version in the source repository.
ZG_PACKAGE="@zvec/zvec-grep@0.3.1"

usage() {
  cat <<'EOF'
Usage: zg-bootstrap.sh [--target <agent>]... [--embedding <model>] [--skip-mcp]

  --target <agent>     Repeatable; passed to zg install (see: zg --help install)
  --skip-mcp           Prepare the wiki and index without changing MCP configuration
  --embedding <model>  First-index model (default: local/potion-multilingual-128m)
                       List models: zg --help models

With no --target, upserts committed project MCP (.cursor/mcp.json, .mcp.json) only.
Pass --target codex (etc.) for user-level zg install. If zg is not on PATH, this
installs @zvec/zvec-grep globally and checks that zg launches. cursor/claude use
the project files.
Requires Node.js 22+. The wiki scripts need Python 3.9+ with PyYAML.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      shift
      if [[ $# -eq 0 ]]; then
        echo "error: --target requires a value" >&2
        exit 1
      fi
      while [[ $# -gt 0 && "$1" != --* ]]; do
        TARGETS+=("$1")
        shift
      done
      ;;
    --embedding)
      shift
      if [[ $# -eq 0 ]]; then
        echo "error: --embedding requires a value" >&2
        exit 1
      fi
      EMBEDDING="$1"
      EMBEDDING_EXPLICIT=1
      shift
      ;;
    --skip-mcp)
      SKIP_MCP=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if (( SKIP_MCP && ${#TARGETS[@]} )); then
  echo "error: --skip-mcp cannot be combined with --target" >&2
  exit 1
fi

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

ensure_gitignore_zvec() {
  if [[ ! -f .gitignore ]]; then
    printf '# zvec-grep local index (not source of truth)\n.zvec-grep/\n' > .gitignore
    say "Created .gitignore with .zvec-grep/"
  elif ! grep -qE '^\.zvec-grep/?$' .gitignore 2>/dev/null; then
    printf '\n# zvec-grep local index (not source of truth)\n.zvec-grep/\n' >> .gitignore
    say "Appended .zvec-grep/ to .gitignore"
  else
    say ".gitignore already ignores .zvec-grep/"
  fi
}

upsert_agents_md() {
  local block_file agents=AGENTS.md
  block_file="$(mktemp)"
  cat > "$block_file" <<'EOF'
<!-- ZVEC_LLM_WIKI_START -->
## Project knowledge (LLM wiki)

- Living wiki: `docs/wiki/`, an OKF v0.3 bundle (start at `docs/wiki/index.md`, then directory indexes)
- Query order: indexes; then zg hybrid scoped to `docs/wiki/**`; then rg for exact names; widen to docs/raw or code only if needed
- Write with `okf-generate`; report trust and freshness with `okf-consume`; llm-wiki rules live in `zvec-llm-wiki`
- Wiki writes are involved: show the page plan, then edit unless stopped; after edits regenerate indexes, lint, and run incremental `zg index`

<!-- ZVEC_LLM_WIKI_END -->
EOF

  if [[ ! -f "$agents" ]]; then
    cp "$block_file" "$agents"
    say "Created $agents (hot memory for the wiki loop)"
  elif grep -q 'ZVEC_LLM_WIKI_START' "$agents"; then
    awk -v blockfile="$block_file" '
      /ZVEC_LLM_WIKI_START/ {
        if (!done) {
          while ((getline line < blockfile) > 0) print line
          done = 1
        }
        skip = 1
        next
      }
      /ZVEC_LLM_WIKI_END/ { skip = 0; next }
      !skip { print }
    ' "$agents" > "${agents}.tmp"
    mv "${agents}.tmp" "$agents"
    say "Updated $agents wiki block"
  else
    printf '\n' >> "$agents"
    cat "$block_file" >> "$agents"
    say "Appended wiki block to $agents"
  fi
  rm -f "$block_file"
}

# Team-shareable MCP (Cursor + Claude Code). Uses npx so teammates need not install zg globally.
# Re-runs update command/args, keep compatible fields (for example env), and refuse HTTP transports.
upsert_project_mcp() {
  local rel_path="$1"
  mkdir -p "$(dirname "$rel_path")"
  node - "$rel_path" "$ZG_PACKAGE" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
const entry = {
  command: "npx",
  args: ["--yes", process.argv[3], "--server", "--stdio", "--mcp-toolset", "agent"],
};

function isHttpTransport(server) {
  if (typeof server.url === "string" || typeof server.httpUrl === "string") return true;
  const type = typeof server.type === "string" ? server.type.toLowerCase() : "";
  return (
    type === "http" ||
    type === "sse" ||
    type === "streamable-http" ||
    type === "streamable_http" ||
    type === "remote"
  );
}

let root = {};
if (fs.existsSync(path)) {
  try {
    root = JSON.parse(fs.readFileSync(path, "utf8"));
  } catch (error) {
    console.error(`error: invalid JSON in ${path}`);
    process.exit(1);
  }
}
if (!root || typeof root !== "object" || Array.isArray(root)) {
  console.error(`error: ${path} must contain a JSON object`);
  process.exit(1);
}
if (!root.mcpServers || typeof root.mcpServers !== "object" || Array.isArray(root.mcpServers)) {
  root.mcpServers = {};
}
const existing = root.mcpServers.zvec_grep;
if (existing && typeof existing === "object" && !Array.isArray(existing)) {
  if (isHttpTransport(existing)) {
    console.error(
      `error: ${path} mcpServers.zvec_grep uses an HTTP transport. Refusing to merge it into the stdio npx entry; migrate that server explicitly.`,
    );
    process.exit(1);
  }
  root.mcpServers.zvec_grep = {
    ...existing,
    command: entry.command,
    args: entry.args,
  };
} else {
  root.mcpServers.zvec_grep = entry;
}
fs.writeFileSync(path, `${JSON.stringify(root, null, 2)}\n`);
NODE
  say "Updated project MCP: $rel_path (commit for teammates and Cloud Agents)"
}

filter_user_install_targets() {
  FILTERED_TARGETS=()
  local t
  for t in "${TARGETS[@]}"; do
    case "$t" in
      cursor|claude) ;;
      *) FILTERED_TARGETS+=("$t") ;;
    esac
  done
}

# zg install writes command "zg". A one-shot npx invocation does not leave that binary on PATH.
ensure_persistent_zg() {
  if command -v zg >/dev/null 2>&1; then
    ZG=(zg)
    return 0
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "error: user-level targets need zg on PATH, and npm is not available to install it." >&2
    exit 1
  fi
  say "Installing @zvec/zvec-grep globally so user-level agents can launch zg"
  npm install -g "$ZG_PACKAGE"
  hash -r
  if ! command -v zg >/dev/null 2>&1 || ! zg --version >/dev/null 2>&1; then
    local prefix
    prefix="$(npm prefix -g 2>/dev/null || true)"
    echo "error: installed @zvec/zvec-grep, but zg does not launch. Add ${prefix:-the npm global bin directory} to PATH, then rerun." >&2
    exit 1
  fi
  ZG=(zg)
  say "Using zg ($(zg --version 2>/dev/null || echo unknown))"
}

# 1) Node.js 22+ check --------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js 22+ is required to run zvec-grep. Install Node first." >&2
  exit 1
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if (( NODE_MAJOR < 22 )); then
  echo "Node.js 22+ required (found v$(node -v)). Aborting." >&2
  exit 1
fi
if ! python3 -c 'import sys, yaml; sys.exit(sys.version_info < (3, 9))' >/dev/null 2>&1; then
  warn "Python 3.9+ with PyYAML is needed for llm_wiki.py and okf-generate's validate.py (pip install pyyaml)"
fi

# 2) Resolve zg for CLI indexing. Project MCP uses npx; a global zg is optional.
ZG=()
if (( SKIP_MCP )); then
  if ! command -v npx >/dev/null 2>&1; then
    echo "The plugin requires npx from Node.js 22+." >&2
    exit 1
  fi
  ZG=(npx --yes "$ZG_PACKAGE")
elif command -v zg >/dev/null 2>&1; then
  ZG=(zg)
  say "Using zg ($(zg --version 2>/dev/null || echo unknown))"
elif command -v npx >/dev/null 2>&1; then
  ZG=(npx --yes "$ZG_PACKAGE")
  say "Using npx @zvec/zvec-grep for CLI (install zg globally if you prefer a shorter command)"
else
  echo "Neither zg nor npm found. Install Node.js 22+ first." >&2
  exit 1
fi

run_zg() {
  local command="$1"
  shift
  # Native zg uses --index/--status/--install. Older global zg uses subcommands.
  if [[ "${ZG[0]}" == npx ]] || "${ZG[@]}" --help | grep -E '^[[:space:]]+--index[[:space:]]+Build' >/dev/null; then
    command="--$command"
  fi
  if (( SKIP_MCP )); then
    set -- "$@" --mode direct
  fi
  "${ZG[@]}" "$command" "$@"
}

# 3) Project MCP (commit) + optional user-level agent installers ----------------
if (( SKIP_MCP )); then
  say "Skipping MCP configuration (managed by the plugin)"
else
  upsert_project_mcp ".cursor/mcp.json"
  upsert_project_mcp ".mcp.json"

  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    say "Skipping user-level zg install (auto). Use project .cursor/mcp.json and .mcp.json; run zg --install --target <agent> for Codex/OpenCode user config."
  else
    filter_user_install_targets
    if [[ ${#FILTERED_TARGETS[@]} -gt 0 ]]; then
      say "Configuring user-level agent integration: ${FILTERED_TARGETS[*]} (cursor/claude use committed project MCP)"
      ensure_persistent_zg
      INSTALL_CMD=(--yes)
      for target in "${FILTERED_TARGETS[@]}"; do
        INSTALL_CMD+=(--target "$target")
      done
      run_zg install "${INSTALL_CMD[@]}"
    else
      say "Only cursor/claude requested — project MCP files are enough; no user-level zg install"
    fi
  fi
fi

# 4) Scaffold the wiki --------------------------------------------------------
if [[ ! -d docs/wiki ]]; then
  say "Scaffolding docs/wiki/ as an OKF v0.3 bundle"
  mkdir -p docs/wiki/summaries docs/wiki/entities docs/wiki/concepts docs/wiki/analyses
  WIKI_TITLE="$(basename "$PWD") wiki"
  cat > docs/wiki/index.md <<EOF
---
okf_version: "0.3"
title: ${WIKI_TITLE}
description: Living project knowledge for people and agents; read this index, then the directory indexes.
---

# ${WIKI_TITLE}

* [Operation log](log.md) - History of wiki operations, newest date first.
EOF
  cat > docs/wiki/log.md <<EOF
# Wiki log

Newest date first. Each entry starts with the operation in bold, such as **Ingest**, **Record**, **Crystallize**, or **Lint**, and links the pages it changed.

## $(date -u +%Y-%m-%d)

* **Creation**: Scaffolded the OKF wiki bundle.
EOF
elif [[ -f docs/wiki/index.md ]] && ! head -n 1 docs/wiki/index.md | grep -qx -- '---'; then
  warn "docs/wiki/ predates OKF (index.md has no frontmatter). Migrate it with the zvec-llm-wiki-okf-migrate skill."
else
  say "docs/wiki/ already exists — leaving it untouched"
fi

# 5) Hot memory (AGENTS.md) -------------------------------------------------
upsert_agents_md

# 5b) Keep local index out of git ---------------------------------------------
ensure_gitignore_zvec

# 6) Build or update the index ------------------------------------------------
if [[ -d .zvec-grep ]]; then
  say "Existing index found — running incremental update (no rebuild)"
  if (( EMBEDDING_EXPLICIT )); then
    warn "--embedding is ignored for an existing index. To change models, use zg --index --rebuild --embedding <model> with explicit user confirmation."
  fi
  run_zg index
else
  say "Building first index (embedding: ${EMBEDDING}; zg default file discovery)"
  run_zg index --embedding "$EMBEDDING"
fi

run_zg status --check-ready

say "Done. Restart your agent if MCP was just configured."
say "Hot memory: AGENTS.md. Read docs/wiki/index.md first. For zg usage: zg --help"
if [[ ! -d "$(dirname -- "${BASH_SOURCE[0]}")/../../okf-generate" && ! -d .agents/skills/okf-generate && ! -d "${HOME}/.agents/skills/okf-generate" ]]; then
  warn "okf-generate is not installed; run install.sh (without --no-okf) so agents can write and validate OKF"
fi

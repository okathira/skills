#!/usr/bin/env bash
# Bootstrap zvec-grep + an LLM wiki in the current repo.
# Idempotent and non-destructive: it never rebuilds/drops an existing index.
#
# Usage:
#   ./zg-bootstrap.sh [--target <agent>]... [--embedding <model>]
#   ./zg-bootstrap.sh                    # auto-detect agents (zg install)
#
set -euo pipefail

TARGETS=()
EMBEDDING="local/potion-multilingual-128m"
EMBEDDING_EXPLICIT=0

usage() {
  cat <<'EOF'
Usage: zg-bootstrap.sh [--target <agent>]... [--embedding <model>]

  --target <agent>     Repeatable; passed to zg install (see: zg help install)
  --embedding <model>  First-index model (default: local/potion-multilingual-128m)
                       Catalog: zg help models

With no --target, runs: zg install --yes (auto-detect).
Requires Node.js 22+.
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

- Living wiki: `docs/wiki/` (registry: `docs/wiki/index.md`)
- Search wiki before acting (scope: `docs/wiki/**`)
- After verified work: propose wiki updates; on approval, edit the owning page, then incremental `zg index`

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

# 2) Resolve zg: existing → npx → confirmed global install --------------------
ZG=()
ZG_MODE=""

if command -v zg >/dev/null 2>&1; then
  ZG=(zg)
  ZG_MODE="global"
  say "Using zg ($(zg --version 2>/dev/null || echo unknown))"
elif command -v npx >/dev/null 2>&1; then
  ZG=(npx --yes @zvec/zvec-grep)
  ZG_MODE="npx"
  say "Using npx @zvec/zvec-grep (no global install)"
else
  echo "Neither zg nor npx found. Install Node.js npm/npx first." >&2
  exit 1
fi

run_zg() {
  "${ZG[@]}" "$@"
}

if [[ "$ZG_MODE" == "npx" ]] && ! command -v zg >/dev/null 2>&1; then
  if [[ -t 0 ]]; then
    printf 'Install @zvec/zvec-grep globally for faster runs? [y/N] '
    read -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      say "Installing @zvec/zvec-grep globally"
      npm install -g @zvec/zvec-grep
      ZG=(zg)
      ZG_MODE="global"
    fi
  else
    warn "Non-interactive session: continuing with npx (no global install)."
  fi
fi

# 3) Wire the agent MCP integration -------------------------------------------
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  say "Configuring agent integration (auto-detect)"
  run_zg install --yes
else
  say "Configuring agent integration: ${TARGETS[*]}"
  INSTALL_CMD=("${ZG[@]}" install --yes)
  for target in "${TARGETS[@]}"; do
    INSTALL_CMD+=(--target "$target")
  done
  "${INSTALL_CMD[@]}"
fi

# 4) Scaffold the wiki --------------------------------------------------------
if [[ ! -d docs/wiki ]]; then
  say "Scaffolding docs/wiki/"
  mkdir -p docs/wiki/decisions docs/wiki/runbooks
  cat > docs/wiki/index.md <<'EOF'
# Wiki registry

The map of what lives where. Every page must be listed here.

| Page | Owns |
|------|------|
| glossary.md | domain terms & acronyms |
| architecture.md | components, boundaries, data flow (the "what") |
| decisions/ | ADRs — the "why" behind structural choices |
| conventions.md | naming, patterns, do/don't |
| gotchas.md | sharp edges & things not to touch |
| runbooks/ | build, test, deploy, release |
EOF
  for f in glossary architecture conventions gotchas; do
    [[ -f "docs/wiki/$f.md" ]] || echo "# ${f}" > "docs/wiki/$f.md"
  done
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
    warn "--embedding is ignored for an existing index. To change models, use zg index --rebuild --embedding <model> with explicit user confirmation."
  fi
  run_zg index
else
  say "Building first index (embedding: ${EMBEDDING}; zg default file discovery)"
  run_zg index --embedding "$EMBEDDING"
fi

run_zg status --check-ready

if [[ "$ZG_MODE" == "npx" ]]; then
  warn "zg is not on PATH. Later agent runs of 'zg index' may fail unless you install globally: npm install -g @zvec/zvec-grep"
fi

say "Done. Restart your agent if MCP was just configured."
say "Hot memory: AGENTS.md. Search wiki first (scope: docs/wiki/**). For zg usage: zg help"

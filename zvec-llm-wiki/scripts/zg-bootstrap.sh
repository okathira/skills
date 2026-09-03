#!/usr/bin/env bash
# Bootstrap zvec-grep + an LLM wiki in the current repo.
# Idempotent and non-destructive: it never rebuilds/drops an existing index.
#
# Usage:
#   ./zg-bootstrap.sh [--target codex|cursor|opencode|claude|qwen|all]...
#   ./zg-bootstrap.sh                    # auto-detect agents (zg install)
#
set -euo pipefail

TARGETS=()

usage() {
  cat <<'EOF'
Usage: zg-bootstrap.sh [--target <agent>]...

Agents: codex, cursor, opencode, claude, qwen, all
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

# 5) Build or update the index ------------------------------------------------
COMMON_EXCLUDES=(-g "!dist/**" -g "!node_modules/**" -g "!.git/**" -g "!.zvec-grep/**")

if [[ -d .zvec-grep ]]; then
  say "Existing index found — running incremental update (no rebuild)"
  run_zg index
elif [[ -d src ]]; then
  say "Building first index (scoped to src/ and docs/)"
  run_zg index -g "src/**" -g "docs/**" "${COMMON_EXCLUDES[@]}"
else
  say "No src/ — building first index (docs/ + repo root, with exclusions)"
  run_zg index -g "docs/**" -g "**/*" "${COMMON_EXCLUDES[@]}"
fi

run_zg status --check-ready
say "Done. Restart your agent if MCP was just configured."
say "Try:  zg query \"where <thing> is handled\" -g \"docs/wiki/**\""

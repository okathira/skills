#!/bin/sh
# Install the zvec-llm-wiki skill into agent skill directories.
#
# Usage:
#   install.sh              # .agents/skills/ in the current repo (default)
#   install.sh --user       # ~/.agents/skills/zvec-llm-wiki
#   install.sh --project    # same as default (compatibility alias)
#   install.sh --claude     # also copy to .claude/skills/ (Claude Code)
#   install.sh --force      # overwrite an existing install
#   install.sh --no-okf     # skip the official okf-generate and okf-consume skills
#
# The wiki is an OKF v0.3 bundle. Next to this skill, install.sh fetches the official
# okf-generate and okf-consume skills at a pinned commit (Apache-2.0; LICENSE.md is copied).
# Cursor, Codex, and OpenCode read .agents/skills/. Claude Code reads .claude/skills/.
# Commit project installs so Cloud Agents and teammates share the same skill revision.
# On Windows, run from Git Bash or another POSIX shell.
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME=zvec-llm-wiki

OKF_REPO=open-knowledge-format/open-knowledge-format
OKF_COMMIT=527e81aff55992be21507e97004286789126f88c
OKF_SKILLS="okf-generate okf-consume"

USER_SCOPE=0
CLAUDE=0
FORCE=0
PROJECT_EXPLICIT=0
OKF=1

usage() {
  cat <<'EOF'
Usage: install.sh [--user | --project] [--claude] [--force] [--no-okf]

  (default)   Install to .agents/skills/ in the current directory (commit in team repos)
  --user      Install to ~/.agents/skills/ instead
  --project   Same as default (compatibility alias)
  --claude    Also install to .claude/skills/ (same scope as default or --user)
  --force     Overwrite an existing installation (including the OKF skills)
  --no-okf    Do not fetch the official okf-generate and okf-consume skills
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --user) USER_SCOPE=1 ;;
    --project) PROJECT_EXPLICIT=1 ;;
    --claude) CLAUDE=1 ;;
    --force) FORCE=1 ;;
    --no-okf) OKF=0 ;;
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
  shift
done

if [ "$USER_SCOPE" -eq 1 ] && [ "$PROJECT_EXPLICIT" -eq 1 ]; then
  echo "error: --user and --project cannot be used together" >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/SKILL.md" ]; then
  echo "error: skill package not found at $ROOT_DIR" >&2
  exit 1
fi

copy_skill() {
  dest="$1"
  if [ -d "$dest" ] && [ "$FORCE" -eq 0 ]; then
    echo "error: already exists: $dest (use --force to overwrite)" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$ROOT_DIR/SKILL.md" "$ROOT_DIR/LICENSE" "$dest/"
  cp -R "$ROOT_DIR/scripts" "$ROOT_DIR/references" "$ROOT_DIR/templates" "$dest/"
  echo "Installed: $dest"
}

OKF_TMP=""
cleanup() { if [ -n "$OKF_TMP" ]; then rm -rf "$OKF_TMP"; fi; }
trap cleanup EXIT

fetch_okf() {
  [ -n "$OKF_TMP" ] && return 0
  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "warning: curl and tar are required to fetch the OKF skills" >&2
    return 1
  fi
  OKF_TMP=$(mktemp -d)
  if ! curl -fsSL "https://codeload.github.com/$OKF_REPO/tar.gz/$OKF_COMMIT" | tar -xz -C "$OKF_TMP"; then
    echo "warning: could not download $OKF_REPO@$OKF_COMMIT" >&2
    return 1
  fi
}

install_okf() {
  base="$1"
  for name in $OKF_SKILLS; do
    dest="$base/$name"
    if [ -d "$dest" ] && [ "$FORCE" -eq 0 ]; then
      echo "Kept: $dest (use --force to refresh)"
      continue
    fi
    if ! fetch_okf; then
      echo "warning: skipped $name; copy skills/$name from https://github.com/$OKF_REPO by hand" >&2
      continue
    fi
    src="$OKF_TMP/open-knowledge-format-$OKF_COMMIT"
    rm -rf "$dest"
    mkdir -p "$base"
    cp -R "$src/skills/$name" "$dest"
    cp "$src/LICENSE.md" "$dest/LICENSE.md"
    echo "Installed: $dest ($OKF_REPO@$OKF_COMMIT)"
  done
}

install_scope() {
  copy_skill "$1/$SKILL_NAME"
  if [ "$OKF" -eq 1 ]; then
    install_okf "$1"
  fi
}

HOME_DIR=${HOME:-$(cd ~ && pwd)}

if [ "$USER_SCOPE" -eq 1 ]; then
  install_scope "$HOME_DIR/.agents/skills"
  if [ "$CLAUDE" -eq 1 ]; then
    install_scope "$HOME_DIR/.claude/skills"
  fi
else
  install_scope ".agents/skills"
  if [ "$CLAUDE" -eq 1 ]; then
    install_scope ".claude/skills"
  fi
fi

if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "warning: Python 3.9+ with PyYAML is required for the wiki scripts and validate.py (pip install pyyaml)" >&2
fi

echo "Done. Restart your agent to pick up the skill."

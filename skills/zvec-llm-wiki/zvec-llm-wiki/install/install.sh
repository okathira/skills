#!/bin/sh
# Install the zvec-llm-wiki skill into agent skill directories.
#
# Usage:
#   install.sh              # .agents/skills/ in the current repo (default)
#   install.sh --user       # ~/.agents/skills/zvec-llm-wiki
#   install.sh --project    # same as default (compatibility alias)
#   install.sh --claude     # also copy to .claude/skills/ (Claude Code)
#   install.sh --force      # overwrite an existing install
#
# Cursor, Codex, and OpenCode read .agents/skills/. Claude Code reads .claude/skills/.
# Commit project installs so Cloud Agents and teammates share the same skill revision.
# On Windows, run from Git Bash or another POSIX shell.
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME=zvec-llm-wiki

USER_SCOPE=0
CLAUDE=0
FORCE=0
PROJECT_EXPLICIT=0

usage() {
  cat <<'EOF'
Usage: install.sh [--user | --project] [--claude] [--force]

  (default)   Install to .agents/skills/ in the current directory (commit in team repos)
  --user      Install to ~/.agents/skills/ instead
  --project   Same as default (compatibility alias)
  --claude    Also install to .claude/skills/ (same scope as default or --user)
  --force     Overwrite an existing installation
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --user) USER_SCOPE=1 ;;
    --project) PROJECT_EXPLICIT=1 ;;
    --claude) CLAUDE=1 ;;
    --force) FORCE=1 ;;
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
  cp "$ROOT_DIR/SKILL.md" "$dest/"
  cp -R "$ROOT_DIR/scripts" "$ROOT_DIR/references" "$ROOT_DIR/templates" "$dest/"
  echo "Installed: $dest"
}

HOME_DIR=${HOME:-$(cd ~ && pwd)}

if [ "$USER_SCOPE" -eq 1 ]; then
  copy_skill "$HOME_DIR/.agents/skills/$SKILL_NAME"
  if [ "$CLAUDE" -eq 1 ]; then
    copy_skill "$HOME_DIR/.claude/skills/$SKILL_NAME"
  fi
else
  copy_skill ".agents/skills/$SKILL_NAME"
  if [ "$CLAUDE" -eq 1 ]; then
    copy_skill ".claude/skills/$SKILL_NAME"
  fi
fi

echo "Done. Restart your agent to pick up the skill."

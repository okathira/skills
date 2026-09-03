#!/bin/sh
# Install the zvec-llm-wiki skill into agent skill directories.
#
# Usage:
#   install.sh              # ~/.agents/skills/zvec-llm-wiki
#   install.sh --project    # .agents/skills/ in the current repo
#   install.sh --claude     # also copy to .claude/skills/ (Claude Code)
#   install.sh --force      # overwrite an existing install
#
# Cursor, Codex, and OpenCode read .agents/skills/. Claude Code reads .claude/skills/.
# On Windows, run from Git Bash or another POSIX shell.
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME=zvec-llm-wiki

PROJECT=0
CLAUDE=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: install.sh [--project] [--claude] [--force]

  --project   Install to .agents/skills/ in the current directory
  --claude    Also install to .claude/skills/ (same scope as --project or user)
  --force     Overwrite an existing installation
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT=1 ;;
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

if [ "$PROJECT" -eq 1 ]; then
  copy_skill ".agents/skills/$SKILL_NAME"
  if [ "$CLAUDE" -eq 1 ]; then
    copy_skill ".claude/skills/$SKILL_NAME"
  fi
else
  copy_skill "$HOME_DIR/.agents/skills/$SKILL_NAME"
  if [ "$CLAUDE" -eq 1 ]; then
    copy_skill "$HOME_DIR/.claude/skills/$SKILL_NAME"
  fi
fi

echo "Done. Restart your agent to pick up the skill."

#!/bin/sh
# zvec-llm-wiki-ja スキルをエージェントのスキルディレクトリへインストールする。
#
# 使い方:
#   install.sh              # ~/.agents/skills/zvec-llm-wiki-ja
#   install.sh --project    # 現在のリポジトリの .agents/skills/
#   install.sh --claude     # .claude/skills/ にもコピー（Claude Code）
#   install.sh --force      # 既存インストールを上書き
#
# Cursor、Codex、OpenCode は .agents/skills/ を読む。Claude Code は .claude/skills/ を読む。
# Windows では Git Bash など POSIX シェルから実行する。
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME=zvec-llm-wiki-ja

PROJECT=0
CLAUDE=0
FORCE=0

usage() {
  cat <<'EOF'
使い方: install.sh [--project] [--claude] [--force]

  --project   カレントディレクトリの .agents/skills/ へインストール
  --claude    .claude/skills/ にもインストール（--project と同じスコープ、またはユーザー全体）
  --force     既存インストールを上書き
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
      echo "エラー: 不明なオプション: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ ! -f "$ROOT_DIR/SKILL.md" ]; then
  echo "エラー: スキルパッケージが見つかりません: $ROOT_DIR" >&2
  exit 1
fi

copy_skill() {
  dest="$1"
  if [ -d "$dest" ] && [ "$FORCE" -eq 0 ]; then
    echo "エラー: 既に存在します: $dest（上書きするには --force）" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$ROOT_DIR/SKILL.md" "$dest/"
  cp -R "$ROOT_DIR/scripts" "$ROOT_DIR/references" "$ROOT_DIR/templates" "$dest/"
  echo "インストール先: $dest"
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

echo "完了。スキルを読み込むためエージェントを再起動してください。"

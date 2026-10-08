#!/bin/sh
# zvec-llm-wiki-ja スキルをエージェントのスキルディレクトリへインストールする。
#
# 使い方:
#   install.sh              # 現在のリポジトリの .agents/skills/（既定）
#   install.sh --user       # ~/.agents/skills/zvec-llm-wiki-ja
#   install.sh --project    # 既定と同じ（互換用）
#   install.sh --claude     # .claude/skills/ にもコピー（Claude Code）
#   install.sh --force      # 既存インストールを上書き
#
# Cursor、Codex、OpenCode は .agents/skills/ を読む。Claude Code は .claude/skills/ を読む。
# プロジェクトへのインストールはコミットし、Cloud Agents とチームが同じ版を共有する。
# Windows では Git Bash など POSIX シェルから実行する。
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME=zvec-llm-wiki-ja

USER_SCOPE=0
CLAUDE=0
FORCE=0
PROJECT_EXPLICIT=0

usage() {
  cat <<'EOF'
使い方: install.sh [--user | --project] [--claude] [--force]

  （既定）    カレントディレクトリの .agents/skills/ へ（チームリポジトリではコミット）
  --user      ~/.agents/skills/ へ
  --project   既定と同じ（互換用）
  --claude    .claude/skills/ にもインストール（既定または --user と同じスコープ）
  --force     既存インストールを上書き
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
      echo "エラー: 不明なオプション: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "$USER_SCOPE" -eq 1 ] && [ "$PROJECT_EXPLICIT" -eq 1 ]; then
  echo "エラー: --user と --project は同時に指定できません" >&2
  exit 1
fi

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

echo "完了。スキルを読み込むためエージェントを再起動してください。"

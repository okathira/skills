#!/bin/sh
# zvec-llm-wiki-ja スキルをエージェントのスキルディレクトリへインストールする。
#
# 使い方:
#   install.sh              # 現在のリポジトリの .agents/skills/（既定）
#   install.sh --user       # ~/.agents/skills/zvec-llm-wiki-ja
#   install.sh --project    # 既定と同じ（互換用）
#   install.sh --claude     # .claude/skills/ にもコピー（Claude Code）
#   install.sh --force      # 既存インストールを上書き
#   install.sh --no-okf     # 公式の okf-generate と okf-consume スキルを入れない
#
# wiki は OKF v0.3 の bundle。install.sh はこのスキルの隣に、公式の okf-generate と
# okf-consume スキルを固定したコミットから取得する（Apache-2.0。LICENSE.md もコピーする）。
# Cursor、Codex、OpenCode は .agents/skills/ を読む。Claude Code は .claude/skills/ を読む。
# プロジェクトへのインストールはコミットし、Cloud Agents とチームが同じ版を共有する。
# Windows では Git Bash など POSIX シェルから実行する。
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME=zvec-llm-wiki-ja

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
使い方: install.sh [--user | --project] [--claude] [--force] [--no-okf]

  （既定）    カレントディレクトリの .agents/skills/ へ（チームリポジトリではコミット）
  --user      ~/.agents/skills/ へ
  --project   既定と同じ（互換用）
  --claude    .claude/skills/ にもインストール（既定または --user と同じスコープ）
  --force     既存インストールを上書き（OKF スキルも含む）
  --no-okf    公式の okf-generate と okf-consume スキルを取得しない
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
    echo "エラー: 既に存在します: ${dest}（上書きするには --force）" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$ROOT_DIR/SKILL.md" "$ROOT_DIR/LICENSE" "$dest/"
  cp -R "$ROOT_DIR/scripts" "$ROOT_DIR/references" "$ROOT_DIR/templates" "$dest/"
  echo "インストール先: $dest"
}

OKF_TMP=""
cleanup() { if [ -n "$OKF_TMP" ]; then rm -rf "$OKF_TMP"; fi; }
trap cleanup EXIT

fetch_okf() {
  [ -n "$OKF_TMP" ] && return 0
  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "警告: OKF スキルの取得には curl と tar が必要です" >&2
    return 1
  fi
  OKF_TMP=$(mktemp -d)
  if ! curl -fsSL "https://codeload.github.com/$OKF_REPO/tar.gz/$OKF_COMMIT" | tar -xz -C "$OKF_TMP"; then
    echo "警告: $OKF_REPO@$OKF_COMMIT をダウンロードできませんでした" >&2
    return 1
  fi
}

install_okf() {
  base="$1"
  for name in $OKF_SKILLS; do
    dest="$base/$name"
    if [ -d "$dest" ] && [ "$FORCE" -eq 0 ]; then
      echo "維持: ${dest}（更新するには --force）"
      continue
    fi
    if ! fetch_okf; then
      echo "警告: $name を飛ばしました。https://github.com/$OKF_REPO の skills/$name を手でコピーしてください" >&2
      continue
    fi
    src="$OKF_TMP/open-knowledge-format-$OKF_COMMIT"
    rm -rf "$dest"
    mkdir -p "$base"
    cp -R "$src/skills/$name" "$dest"
    cp "$src/LICENSE.md" "$dest/LICENSE.md"
    echo "インストール先: ${dest}（${OKF_REPO}@${OKF_COMMIT}）"
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
  echo "警告: wiki のスクリプトと validate.py には PyYAML 入りの Python 3.9+ が必要です（pip install pyyaml）" >&2
fi

echo "完了。スキルを読み込むためエージェントを再起動してください。"

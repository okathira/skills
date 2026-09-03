#!/usr/bin/env bash
# 現在のリポジトリに zvec-grep と LLM wiki をブートストラップする。
# 冪等で非破壊的: 既存インデックスを rebuild/drop しない。
#
# 使い方:
#   ./zg-bootstrap.sh [--target <agent>]... [--embedding <model>]
#   ./zg-bootstrap.sh                    # エージェント自動検出 (zg install)
#
set -euo pipefail

TARGETS=()
EMBEDDING="local/potion-multilingual-128m"
EMBEDDING_EXPLICIT=0

usage() {
  cat <<'EOF'
使い方: zg-bootstrap.sh [--target <agent>]... [--embedding <model>]

  --target <agent>     繰り返し可; zg install に渡す（参照: zg help install）
  --embedding <model>  初回インデックスのモデル（デフォルト: local/potion-multilingual-128m）
                       カタログ: zg help models

--target なしの場合は zg install --yes（自動検出）を実行する。
Node.js 22+ が必要。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      shift
      if [[ $# -eq 0 ]]; then
        echo "エラー: --target には値が必要です" >&2
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
        echo "エラー: --embedding には値が必要です" >&2
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
      echo "エラー: 不明なオプション: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }

upsert_agents_md() {
  local block_file agents=AGENTS.md
  block_file="$(mktemp)"
  cat > "$block_file" <<'EOF'
<!-- ZVEC_LLM_WIKI_START -->
## プロジェクト知識（LLM wiki）

- 生きた wiki: `docs/wiki/`（レジストリ: `docs/wiki/index.md`）
- 作業前に wiki を検索する（スコープ: `docs/wiki/**`）
- 検証済みの作業のあと: wiki 更新を提案し、承認後にホームのページを編集、続けて増分 `zg index`

<!-- ZVEC_LLM_WIKI_END -->
EOF

  if [[ ! -f "$agents" ]]; then
    cp "$block_file" "$agents"
    say "$agents を作成した（wiki ループ用ホットメモリ）"
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
    say "$agents の wiki ブロックを更新した"
  else
    printf '\n' >> "$agents"
    cat "$block_file" >> "$agents"
    say "$agents に wiki ブロックを追記した"
  fi
  rm -f "$block_file"
}

# 1) Node.js 22+ の確認 -------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  echo "zvec-grep の実行には Node.js 22+ が必要です。先に Node をインストールしてください。" >&2
  exit 1
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if (( NODE_MAJOR < 22 )); then
  echo "Node.js 22+ が必要です（検出: v$(node -v)）。中止します。" >&2
  exit 1
fi

# 2) zg の解決: 既存 → npx → 確認つきグローバルインストール --------------------
ZG=()
ZG_MODE=""

if command -v zg >/dev/null 2>&1; then
  ZG=(zg)
  ZG_MODE="global"
  say "zg を使用 ($(zg --version 2>/dev/null || echo 不明))"
elif command -v npx >/dev/null 2>&1; then
  ZG=(npx --yes @zvec/zvec-grep)
  ZG_MODE="npx"
  say "npx @zvec/zvec-grep を使用（グローバルインストールなし）"
else
  echo "zg も npx も見つかりません。先に Node.js の npm/npx をインストールしてください。" >&2
  exit 1
fi

run_zg() {
  "${ZG[@]}" "$@"
}

if [[ "$ZG_MODE" == "npx" ]] && ! command -v zg >/dev/null 2>&1; then
  if [[ -t 0 ]]; then
    printf '次回以降を速くするため @zvec/zvec-grep をグローバルインストールしますか? [y/N] '
    read -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      say "@zvec/zvec-grep をグローバルインストールします"
      npm install -g @zvec/zvec-grep
      ZG=(zg)
      ZG_MODE="global"
    fi
  else
    warn "非対話セッションのため npx のまま続行します（グローバルインストールなし）。"
  fi
fi

# 3) エージェント MCP 連携 -----------------------------------------------------
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  say "エージェント連携を設定します（自動検出）"
  run_zg install --yes
else
  say "エージェント連携を設定します: ${TARGETS[*]}"
  INSTALL_CMD=("${ZG[@]}" install --yes)
  for target in "${TARGETS[@]}"; do
    INSTALL_CMD+=(--target "$target")
  done
  "${INSTALL_CMD[@]}"
fi

# 4) wiki のひな形 ------------------------------------------------------------
if [[ ! -d docs/wiki ]]; then
  say "docs/wiki/ のひな形を作成します"
  mkdir -p docs/wiki/decisions docs/wiki/runbooks
  cat > docs/wiki/index.md <<'EOF'
# Wiki レジストリ

何がどこにあるかの地図。すべてのページをここに載せる。

| ページ | 所有するもの |
|------|------|
| glossary.md | ドメイン用語と略語 |
| architecture.md | コンポーネント、境界、データフロー（"what"） |
| decisions/ | ADR — 構造的な選択の "why" |
| conventions.md | 命名、パターン、do/don't |
| gotchas.md | 落とし穴と触ってはいけないもの |
| runbooks/ | ビルド、テスト、デプロイ、リリース |
EOF
  for f in glossary architecture conventions gotchas; do
    [[ -f "docs/wiki/$f.md" ]] || echo "# ${f}" > "docs/wiki/$f.md"
  done
else
  say "docs/wiki/ は既に存在するため変更しません"
fi

# 5) ホットメモリ（AGENTS.md） ------------------------------------------------
upsert_agents_md

# 6) インデックスの構築または更新 ---------------------------------------------
if [[ -d .zvec-grep ]]; then
  say "既存インデックスを検出 — 増分更新します（rebuild なし）"
  if (( EMBEDDING_EXPLICIT )); then
    warn "既存インデックスでは --embedding を無視します。モデルを変えるには、ユーザーの明示的な確認のうえ zg index --rebuild --embedding <model> を使ってください。"
  fi
  run_zg index
else
  say "初回インデックスを構築します（埋め込み: ${EMBEDDING}; zg デフォルトファイル探索）"
  run_zg index --embedding "$EMBEDDING"
fi

run_zg status --check-ready

if [[ "$ZG_MODE" == "npx" ]]; then
  warn "zg が PATH にありません。後でエージェントが 'zg index' を実行すると失敗する可能性があります。グローバルインストール: npm install -g @zvec/zvec-grep"
fi

say "完了。MCP を今設定した場合はエージェントを再起動してください。"
say "ホットメモリ: AGENTS.md。まず wiki を検索（スコープ: docs/wiki/**）。zg の使い方: zg help"

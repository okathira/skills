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
                       対応一覧は zg help models
                       （PATH に無いときは npx --yes @zvec/zvec-grep help models）

--target なしの場合はコミット用プロジェクト MCP（.cursor/mcp.json、.mcp.json）のみ更新する。
Codex などユーザー全体設定は --target codex 等を指定。cursor/claude はプロジェクト MCP を使う。
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

ensure_gitignore_zvec() {
  if [[ ! -f .gitignore ]]; then
    printf '# zvec-grep ローカルインデックス（正ではない）\n.zvec-grep/\n' > .gitignore
    say ".gitignore を作成し .zvec-grep/ を追加した"
  elif ! grep -qE '^\.zvec-grep/?$' .gitignore 2>/dev/null; then
    printf '\n# zvec-grep ローカルインデックス（正ではない）\n.zvec-grep/\n' >> .gitignore
    say ".gitignore に .zvec-grep/ を追記した"
  else
    say ".gitignore は既に .zvec-grep/ を無視している"
  fi
}

upsert_agents_md() {
  local block_file agents=AGENTS.md
  block_file="$(mktemp)"
  cat > "$block_file" <<'EOF'
<!-- ZVEC_LLM_WIKI_START -->
## プロジェクト知識（LLM wiki）

- 生きた wiki: `docs/wiki/`（レジストリ: `docs/wiki/index.md`）
- Query 順序: `index.md` を読み、次に `docs/wiki/**` にスコープした zg hybrid、完全一致名は rg、不足時だけ範囲を広げる
- Wiki 書き込みは involved: ページ計画を示し、止められなければ編集する。編集後は増分 `zg index`

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

# チーム共有 MCP（Cursor + Claude Code）。npx 起動のため zg のグローバルインストールは不要。
upsert_project_mcp() {
  local rel_path="$1"
  mkdir -p "$(dirname "$rel_path")"
  node - "$rel_path" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
const entry = {
  command: "npx",
  args: ["--yes", "@zvec/zvec-grep", "server", "--stdio", "--mcp-toolset", "agent"],
};
let root = {};
if (fs.existsSync(path)) {
  try {
    root = JSON.parse(fs.readFileSync(path, "utf8"));
  } catch (error) {
    console.error(`エラー: ${path} の JSON が不正です`);
    process.exit(1);
  }
}
if (!root.mcpServers || typeof root.mcpServers !== "object") {
  root.mcpServers = {};
}
root.mcpServers.zvec_grep = entry;
fs.writeFileSync(path, `${JSON.stringify(root, null, 2)}\n`);
NODE
  say "プロジェクト MCP を更新: $rel_path（チームと Cloud Agents 向けにコミット）"
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

# 2) インデックス用 CLI。プロジェクト MCP は npx 起動。zg のグローバルインストールは任意。
ZG=()
if command -v zg >/dev/null 2>&1; then
  ZG=(zg)
  say "zg を使用 ($(zg --version 2>/dev/null || echo 不明))"
elif command -v npm >/dev/null 2>&1; then
  ZG=(npx --yes @zvec/zvec-grep)
  say "CLI は npx @zvec/zvec-grep を使用（短いコマンドがよければ zg をグローバルインストール）"
else
  echo "zg も npm も見つかりません。先に Node.js 22+ をインストールしてください。" >&2
  exit 1
fi

run_zg() {
  "${ZG[@]}" "$@"
}

# 3) プロジェクト MCP（コミット）+ 任意のユーザー全体インストール ----------------
upsert_project_mcp ".cursor/mcp.json"
upsert_project_mcp ".mcp.json"

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  say "ユーザー全体の zg install はスキップ（自動）。.cursor/mcp.json と .mcp.json を使う。Codex/OpenCode は zg install --target <agent> を別途実行。"
else
  filter_user_install_targets
  if [[ ${#FILTERED_TARGETS[@]} -gt 0 ]]; then
    say "ユーザー全体のエージェント連携: ${FILTERED_TARGETS[*]}（cursor/claude はコミット済みプロジェクト MCP）"
    INSTALL_CMD=("${ZG[@]}" install --yes)
    for target in "${FILTERED_TARGETS[@]}"; do
      INSTALL_CMD+=(--target "$target")
    done
    "${INSTALL_CMD[@]}"
  else
    say "cursor/claude のみ指定 — プロジェクト MCP で十分。ユーザー全体の zg install は不要"
  fi
fi

# 4) wiki のひな形 ------------------------------------------------------------
if [[ ! -d docs/wiki ]]; then
  say "docs/wiki/ のひな形を作成します"
  mkdir -p docs/wiki/sources docs/wiki/entities docs/wiki/concepts docs/wiki/analyses
  cat > docs/wiki/index.md <<'EOF'
# Wiki レジストリ

最初にこのカタログを読む。すべての wiki ページを相対 `.md` リンクと 1 行要約付きで登録する。

## Core

- [操作ログ](log.md) — ingest、lint、crystallize、大きな record の追記履歴。

## Sources

ソース要約と来歴ページは `sources/` に置く。

## Entities

人、システム、プロジェクト、製品は `entities/` に置く。

## Concepts

用語、パターン、ルール、アイデアは `concepts/` に置く。

## Analyses

統合分析と crystallize した query 回答は `analyses/` に置く。

任意の coding overlay として `decisions/` と `runbooks/` を追加できる。任意の不変な
インポート済み Markdown はプロジェクトルートの `raw/`（`docs/` の隣）に置ける。
EOF
  cat > docs/wiki/log.md <<'EOF'
# Wiki 操作ログ

大きな操作を `## [YYYY-MM-DD] kind | title` として追記する。kind は `ingest`、`lint`、
`crystallize`、`record`。変更ページを相対 `.md` リンクで示し、該当時は source path を記録する。
過去の entry は書き換えない。
EOF
else
  say "docs/wiki/ は既に存在するため変更しません"
fi

# 5) ホットメモリ（AGENTS.md） ------------------------------------------------
upsert_agents_md

# 5b) ローカルインデックスを git から除外 ---------------------------------------
ensure_gitignore_zvec

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

say "完了。MCP を今設定した場合はエージェントを再起動してください。"
say "ホットメモリ: AGENTS.md。まず docs/wiki/index.md を読む。zg の使い方: zg help"

#!/usr/bin/env bash
# 現在のリポジトリに zvec-grep と LLM wiki をブートストラップする。
# 冪等で非破壊的: 既存インデックスを rebuild/drop しない。
#
# 使い方:
#   ./zg-bootstrap.sh [--target <agent>]... [--embedding <model>] [--skip-mcp]
#   ./zg-bootstrap.sh                    # エージェント自動検出 (zg install)
#
set -euo pipefail

TARGETS=()
EMBEDDING="local/potion-multilingual-128m"
EMBEDDING_EXPLICIT=0
SKIP_MCP=0
SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/zg.sh"

usage() {
  cat <<'EOF'
使い方: zg-bootstrap.sh [--target <agent>]... [--embedding <model>] [--skip-mcp]

  --target <agent>     繰り返し可; zg install に渡す（参照: zg --help install）
  --skip-mcp           MCP 設定を変更せずに Wiki とインデックスを準備する
  --embedding <model>  初回インデックスのモデル（デフォルト: local/potion-multilingual-128m）
                       対応一覧は同梱の zg.sh --help models

--target なしの場合はコミット用プロジェクト MCP（.cursor/mcp.json、.mcp.json）のみ更新する。
Codex などユーザー全体設定は --target codex 等を指定。zg が PATH に無いときは
@zvec/zvec-grep をグローバルインストールし、zg が起動することを確認する。
cursor/claude はプロジェクト MCP を使う。
Node.js 22+ が必要。wiki のスクリプトには PyYAML 入りの Python 3.9+ が必要。
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
    --skip-mcp)
      SKIP_MCP=1
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

if (( SKIP_MCP && ${#TARGETS[@]} )); then
  echo "エラー: --skip-mcp と --target は併用できません" >&2
  exit 1
fi

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

- 生きた wiki: `docs/wiki/`、OKF v0.3 の bundle（`docs/wiki/index.md` から始め、次にディレクトリの index）
- Query 順序: index 群、次に `docs/wiki/**` にスコープした zg hybrid、完全一致名は rg、不足時だけ docs/raw かコードへ広げる
- 書き込みは `okf-generate`、信頼度と鮮度の報告は `okf-consume`、llm-wiki の規則は `zvec-llm-wiki-ja` に従う
- Wiki 書き込みは involved: ページ計画を示し、止められなければ編集する。編集後は index 再生成、lint、zvec-llm-wiki-ja に同梱の `bash /path/to/installed-skill/scripts/zg.sh --index` で増分更新

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
# 再実行時は command/args を更新し、env など互換フィールドは残す。HTTP トランスポートは拒否する。
upsert_project_mcp() {
  local rel_path="$1"
  mkdir -p "$(dirname "$rel_path")"
  node - "$rel_path" "$ZG_PACKAGE" "$ZG_ALLOW_SCRIPTS" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
const entry = {
  command: "npx",
  args: ["--yes", process.argv[4], process.argv[3], "--server", "--stdio", "--mcp-toolset", "agent"],
};

function isHttpTransport(server) {
  if (typeof server.url === "string" || typeof server.httpUrl === "string") return true;
  const type = typeof server.type === "string" ? server.type.toLowerCase() : "";
  return (
    type === "http" ||
    type === "sse" ||
    type === "streamable-http" ||
    type === "streamable_http" ||
    type === "remote"
  );
}

let root = {};
if (fs.existsSync(path)) {
  try {
    root = JSON.parse(fs.readFileSync(path, "utf8"));
  } catch (error) {
    console.error(`エラー: ${path} の JSON が不正です`);
    process.exit(1);
  }
}
if (!root || typeof root !== "object" || Array.isArray(root)) {
  console.error(`エラー: ${path} は JSON オブジェクトである必要があります`);
  process.exit(1);
}
if (!root.mcpServers || typeof root.mcpServers !== "object" || Array.isArray(root.mcpServers)) {
  root.mcpServers = {};
}
const existing = root.mcpServers.zvec_grep;
if (existing && typeof existing === "object" && !Array.isArray(existing)) {
  if (isHttpTransport(existing)) {
    console.error(
      `エラー: ${path} の mcpServers.zvec_grep は HTTP トランスポートです。stdio の npx エントリへは結合しません。明示的に移行してください。`,
    );
    process.exit(1);
  }
  root.mcpServers.zvec_grep = {
    ...existing,
    command: entry.command,
    args: entry.args,
  };
} else {
  root.mcpServers.zvec_grep = entry;
}
fs.writeFileSync(path, `${JSON.stringify(root, null, 2)}\n`);
NODE
  say "プロジェクト MCP を更新: ${rel_path}（チームと Cloud Agents 向けにコミット）"
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

# zg install は command に "zg" を書く。一時的な npx 実行ではその実行ファイルは PATH に残らない。
ensure_persistent_zg() {
  if command -v zg >/dev/null 2>&1; then
    if ! zg_has_pinned_version; then
      echo "ユーザー全体の MCP 設定には PATH 上の zg ${ZG_PACKAGE##*@} が必要です。既存の zg を更新するか、--target を外してください。" >&2
      return 1
    fi
    return
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "ユーザー全体の MCP 設定には zg ${ZG_PACKAGE##*@} または npm が必要です。" >&2
    return 1
  fi
  say "ユーザー全体の MCP 用に $ZG_PACKAGE をインストールする"
  npm install -g "$ZG_ALLOW_SCRIPTS" "$ZG_PACKAGE"
  hash -r
  if ! zg_has_pinned_version; then
    echo "zg ${ZG_PACKAGE##*@} が PATH から起動できません。npm のグローバル bin ディレクトリを PATH に追加して再実行してください。" >&2
    return 1
  fi
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
if ! python3 -c 'import sys, yaml; sys.exit(sys.version_info < (3, 9))' >/dev/null 2>&1; then
  warn "llm_wiki.py と okf-generate の validate.py には PyYAML 入りの Python 3.9+ が必要です（pip install pyyaml）"
fi

# 2) Check the CLI before making project changes.
if [[ ${#TARGETS[@]} -gt 0 ]]; then
  filter_user_install_targets
  if [[ ${#FILTERED_TARGETS[@]} -gt 0 ]]; then
    ensure_persistent_zg
  fi
fi
if ! zg_has_pinned_version && ! command -v npx >/dev/null 2>&1; then
  echo "Node.js の npx を導入するか、zg ${ZG_PACKAGE##*@} を PATH に追加してください。" >&2
  exit 1
fi

run_zg() {
  if (( SKIP_MCP )); then
    set -- "$@" --mode direct
  fi
  zg_run "$@"
}

# 3) プロジェクト MCP（コミット）+ 任意のユーザー全体インストール ----------------
if (( SKIP_MCP )); then
  say "MCP 設定の変更を省略（プラグイン側で管理）"
else
  upsert_project_mcp ".cursor/mcp.json"
  upsert_project_mcp ".mcp.json"

  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    say "ユーザー全体の zg install はスキップ（自動）。.cursor/mcp.json と .mcp.json を使う。Codex/OpenCode は zg install --target <agent> を別途実行。"
  else
    if [[ ${#FILTERED_TARGETS[@]} -gt 0 ]]; then
      say "ユーザー全体のエージェント連携: ${FILTERED_TARGETS[*]}（cursor/claude はコミット済みプロジェクト MCP）"
      INSTALL_CMD=(--yes)
      for target in "${FILTERED_TARGETS[@]}"; do
        INSTALL_CMD+=(--target "$target")
      done
      zg --install "${INSTALL_CMD[@]}"
    else
      say "cursor/claude のみ指定 — プロジェクト MCP で十分。ユーザー全体の zg install は不要"
    fi
  fi
fi

# 4) wiki のひな形 ------------------------------------------------------------
if [[ ! -d docs/wiki ]]; then
  say "docs/wiki/ を OKF v0.3 の bundle としてひな形作成します"
  mkdir -p docs/wiki/summaries docs/wiki/entities docs/wiki/concepts docs/wiki/analyses
  WIKI_TITLE="$(basename "$PWD") wiki"
  cat > docs/wiki/index.md <<EOF
---
okf_version: "0.3"
title: ${WIKI_TITLE}
description: 人とエージェントが共有する生きたプロジェクト知識。この index を読み、次にディレクトリの index を読む。
---

# ${WIKI_TITLE}

* [操作ログ](log.md) - wiki 操作の履歴。新しい日付が上。
EOF
  cat > docs/wiki/log.md <<EOF
# Wiki 操作ログ

新しい日付が上。各 entry は **Ingest**、**Record**、**Crystallize**、**Lint** などの操作名の太字で始め、変更したページへリンクする。

## $(date -u +%Y-%m-%d)

* **Creation**: OKF の wiki bundle をひな形作成した。
EOF
elif [[ -f docs/wiki/index.md ]] && ! head -n 1 docs/wiki/index.md | grep -qx -- '---'; then
  warn "docs/wiki/ は OKF 以前の形式です（index.md に frontmatter がない）。zvec-llm-wiki-okf-migrate-ja スキルで移行してください。"
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
    warn "既存インデックスでは --embedding を無視します。モデルを変えるには、ユーザーの明示的な確認のうえ zg.sh --index --rebuild --embedding <model> を使ってください。"
  fi
  run_zg --index
else
  say "初回インデックスを構築します（埋め込み: ${EMBEDDING}; zg デフォルトファイル探索）"
  run_zg --index --embedding "$EMBEDDING"
fi

run_zg --status --check-ready

say "完了。MCP を今設定した場合はエージェントを再起動してください。"
say "ホットメモリ: AGENTS.md。まず docs/wiki/index.md を読む。zg の使い方: 同梱の scripts/zg.sh --help"
if [[ ! -d "$(dirname -- "${BASH_SOURCE[0]}")/../../okf-generate" && ! -d .agents/skills/okf-generate && ! -d "${HOME}/.agents/skills/okf-generate" ]]; then
  warn "okf-generate が未インストールです。エージェントが OKF を書いて検証できるよう install.sh（--no-okf なし）を実行してください"
fi

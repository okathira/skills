# zvec-llm-wiki（日本語版）

[Agent Skill](https://agentskills.io/) で、**zvec-grep（`zg`）** を使ってプロジェクトの
**LLM 向け wiki**（`docs/wiki/`）を ingest、query、lint、record、crystallize する。

コアループ: **Query → Work → Ingest/Record/Crystallize → Lint → 増分 `zg index`**。
書き込みは involved: ページ計画を示し、ユーザーが止めなければ編集する。破壊的な index 操作は
引き続き承認必須。

Karpathy 型の既定 wiki は `index.md`、`log.md`、`sources/`、`entities/`、`concepts/`、
`analyses/`。`decisions/` と `runbooks/` は任意の coding overlay、プロジェクトルートの
`raw/` は任意かつ不変。
Query は index、wiki スコープ zg hybrid、完全一致名の rg、不足時だけ raw/code へ拡大、の順。
qmd は使わない。

## レイアウト

```
skills/zvec-llm-wiki/zvec-llm-wiki-ja/
  README.md                       # このファイル（カタログ / 人間向け）
  install/install.sh              # スキルをエージェントのスキルディレクトリへコピー
  SKILL.md                        # エージェント向けエントリポイント
  scripts/zg-bootstrap.sh         # 対象リポジトリで zg + docs/wiki をブートストラップ
  references/
  templates/
```

スキル `name` は `zvec-llm-wiki-ja` で、このフォルダに対応する。`install.sh` は `SKILL.md`、`scripts/`、`references/`、`templates/` だけをコピーする — この README と `install/` はコピーしない。このフォルダは単体で完結し、英語版へ依存しない。

2 つのセットアップ手順 — 混同しないこと:

1. **スキルのインストール**（マシンまたはリポジトリごとに 1 回）— `install/install.sh`
2. **対象リポジトリのブートストラップ**（プロジェクトごとに 1 回）— `scripts/zg-bootstrap.sh`

## 1. スキルのインストール

`.agents/skills/zvec-llm-wiki-ja`（Cursor、Codex、OpenCode）または任意で `.claude/skills/`（Claude Code）へコピーする。

```bash
# ユーザー全体（デフォルト）— Cursor / Codex / OpenCode
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh

# プロジェクトスコープ — チームリポジトリ、Cloud Agents
cd your-repo
sh /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --project

# Claude Code 向けにもインストール
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --claude
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --project --claude
```

既存インストールを上書きするには `--force` を使う。カタログ更新後は `--force` で再実行し、`~/.agents/skills/`（またはプロジェクト内の `.agents/skills/`）に変更を反映する。

Windows では Git Bash など POSIX シェルから実行する。

インストール後にエージェントを再起動する。

## 2. 対象リポジトリのブートストラップ

作業中の **プロジェクト** から実行する（このカタログからではない）。**Node.js 22+** が必要 — zvec-grep にスタンドアロンバイナリはない。

```bash
cd your-repo

# インストール済みエージェントを自動検出（Codex、Cursor、OpenCode、Claude、…）
bash /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki-ja/scripts/zg-bootstrap.sh

# またはエージェントを明示的に指定（参照: zg help install）
bash /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki-ja/scripts/zg-bootstrap.sh --target cursor codex opencode

# デフォルト wiki 埋め込みを上書き
bash /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki-ja/scripts/zg-bootstrap.sh --embedding local/potion-multilingual-128m
```

使える埋め込みモデルはインストール済み zg のカタログが正。一覧は次で確認する（この README にはモデル表を置かない）。

```bash
zg help models
# PATH に zg が無いとき:
npx --yes @zvec/zvec-grep help models
```

`zg` が無いときは、`zg install` の前に `npm install -g @zvec/zvec-grep` を実行する。MCP の stdio 設定は常に `zg` バイナリを起動し（`zg install` は npm パッケージを入れない）、npx だけのブートストラップだとエージェントが `command not found: zg` になる。新規 wiki には空 stub なしで有用なレジストリ、操作ログ、種別ディレクトリを作り、既存 wiki には触れない。その後 `AGENTS.md` ホットメモリを upsert し、zg デフォルト探索で最初のインデックスを構築する。MCP 設定後にエージェントを再起動する。

## スキルパッケージの内容

| パス | 目的 |
|------|------|
| `SKILL.md` | エントリポイント: 操作、wiki レイヤー、段階的 zg ルーティング |
| `references/wiki-workflow.md` | ページ/ログ契約、ingest 深度、lint ルール、埋め込み |
| `scripts/zg-bootstrap.sh` | 冪等で非破壊的なリポジトリセットアップ |
| `templates/wiki-page.md` | source / entity / concept / analysis ページのテンプレート |
| `templates/adr.md` | Architecture Decision Record テンプレート（coding overlay） |
| `templates/runbook.md` | 手順テンプレート（coding overlay） |

## 設計の出典

- [zvec-grep](https://github.com/zvec-ai/zvec-grep) — zg の挙動と CLI リファレンス（`zg help`）
- [Karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 永続的な編纂 wiki、種別、操作、index 先読み、log
- [zvec-grep オープンソース記事](https://zvec.org/en/blog/2026-08-28-zvec-grep-open-source/) — semantic/hybrid discovery と rg verification を段階化した 1 エンジン
- [Agent Skills](https://agentskills.io/specification) 執筆（簡潔な SKILL.md、段階的開示）

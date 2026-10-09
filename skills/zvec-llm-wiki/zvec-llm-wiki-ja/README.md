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

1. **スキルのインストール**（リポジトリごと; `.agents/skills/` をコミット）— `install/install.sh`
2. **対象リポジトリのブートストラップ**（プロジェクトごとに 1 回）— `scripts/zg-bootstrap.sh`

## 1. スキルのインストール

既定で `.agents/skills/zvec-llm-wiki-ja`（Cursor、Codex、OpenCode）へコピーする。任意で `.claude/skills/`（Claude Code）。**プロジェクトへのインストールはコミット**し、チームと Cloud Agents が同じ版を共有する。

```bash
cd your-repo

# プロジェクト（既定）— チーム、Cloud Agents
sh /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh

# マシン全体
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --user

# Claude Code 向けにもインストール
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --claude
sh skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh --user --claude
```

既存インストールを上書きするには `--force` を使う。カタログ更新後は `--force` で再実行し、`.agents/skills/` をコミットする（`--user` のときは `~/.agents/skills/`）。

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

ブートストラップは **コミットする** `.cursor/mcp.json` と `.mcp.json` を `npx @zvec/zvec-grep server --stdio` で upsert するため、エージェントにグローバル `zg` は不要。再実行時はそのサーバーの command と args を更新し、`env` など互換フィールドは残す。既存の HTTP トランスポートは結合せず拒否する。CLI は PATH の `zg` または `npx @zvec/zvec-grep`。ユーザー全体の `zg install` は `--target codex` 等で任意。`zg` が PATH に無いときは `@zvec/zvec-grep` をグローバルインストールし、設定を書く前に `zg` が起動することを確認する。Cursor/Claude はプロジェクト MCP を使う。新規 wiki には空 stub なしで有用なレジストリ、操作ログ、種別ディレクトリを作り、既存 wiki には触れない。その後 `AGENTS.md` ホットメモリを upsert し、zg デフォルト探索で最初のインデックスを構築する。MCP 設定後にエージェントを再起動する。

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

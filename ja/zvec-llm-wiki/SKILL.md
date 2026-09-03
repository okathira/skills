---
name: zvec-llm-wiki-ja
description: >-
  zvec-grep (zg) でプロジェクトの LLM wiki (docs/wiki/) を維持し、作業前に知識を読み、検証後に記録する。
  LLM wiki、living docs、zvec-grep、zg、ナレッジベース、wiki整備、conventions、ADR、gotchas で使う。
  Web 検索や wiki 以外の Markdown には使わない。
license: Proprietary. Internal use.
---

# zvec-grep による LLM wiki の維持

## 概要

プロジェクトのドキュメントを、人間とエージェントが共有する **生きたシステム** として運用する。
`zg`（zvec-grep）が検索レイヤー、`docs/wiki/` が正（source of truth）。ループは次のとおり:

> **Read (zg) → Work → Verify with the human → Record (edit wiki) → Re-index (zg index)**

信頼性を保つための 2 つの必須ルール:

1. **人間がチェックポイント。** 作業が検証されたら、wiki 更新を **提案** する（どのページに、何を追記するか）。ユーザーが承認したときだけ記録する。ドキュメントを黙って書かない — 誤った結果が次のセッションで「ルール」として信頼されてしまう。構造的な変更は、承認後 **同じ PR** に wiki/ADR 更新を含める。
2. **エージェントはインデックスのライフサイクルを独断で変更しない。** wiki 編集 *後* のルーティン更新として `zg index`（増分更新）を実行してよいが、`--rebuild`、`--drop`、`--reset-paths` はユーザーの明示的な確認なしに実行してはならない。

`zg` が未インストール、またはインデックスがない場合は、下記の **ブートストラップ** に従う。ブートストラップが成功するまでは、通常の検索ツールでコードを読む — ただし、未検証の推測から wiki を更新してはならない。

## Wiki 構造（`docs/wiki/`）

原則: **1 事実 1 ホーム、コピーではなく相互参照。** *what*（コードから自動導出可能）と *why*（人間の意図）を分ける。

```
docs/wiki/
  index.md          # エントリマップ: 何がどこにあるか（レジストリ）
  glossary.md       # ドメイン用語、略語、1 行定義
  architecture.md   # コンポーネント、境界、データフロー（"what"）
  decisions/        # ADR: 1 決定 1 ファイル（"why"）（ADR-0001-*.md）
  conventions.md    # 命名、パターン、do/don't
  gotchas.md        # 落とし穴: "X は触らない、なぜなら ..."
  runbooks/         # ビルド、テスト、デプロイ、リリースの手順
```

出発点として `templates/adr.md` と `templates/wiki-page.md` を使う。各ページは短く保ち、
重複ではなくリンクする。ガバナンスの詳細: `references/wiki-workflow.md`。

## zg を使うとき（使わないとき）

このスキルは検索の **いつ・なぜ** を定義する。フラグ、モデル、MCP 設定、トランスポートについては、
`zg help`、`zg help query`、`zg help index`、`zg help install`、`zg help models` を実行する — このスキルから zg の構文をコピーしたり推測したりしない。

### 検索ルーティング

| 状況 | ルート |
|---|---|
| 意味、ファイル横断の文脈、場所が不明 | zg インデックス検索（`zg install` の MCP ツールがあれば利用; ツール名はクライアントにより異なる） |
| 正確な識別子、パス、正規表現、リネーム漏れ | ネイティブ grep/rg、または zg managed rg — `zg help query` を参照 |
| タスク開始時 | まず `docs/wiki/**` にスコープ; wiki の証拠が足りないときだけコードへ広げる |
| 関連資料がローカルに存在するか確認 | 1 回の焦点を絞ったセマンティック検索; 結果が十分または無関係なら停止 |

**Wiki スコープはスキル契約:** wiki を先に読むときは、常に `docs/wiki/**` を検索スコープとして渡す（MCP または CLI）。スコープの渡し方はインストール済み zg による — `zg help query` を確認し、このスキルからフラグを推測しない。

インデックスライフサイクル（`zg index`、`zg status`）は CLI 上で行う。インストール済み zg がそれらを提供していない限り、オプションの MCP インデックスや managed-rg ツールの存在を前提にしない。

ランク付けされた証拠が十分になったら検索を止める — 「念のため」にファイル全体を読まない。

### インデックススコープ（プロジェクト判断）

ブートストラップは最初のインデックスに zg のデフォルトファイル探索を使う — このスキルは `src/` レイアウトを前提にしない。リポジトリを調査した後、デフォルトが重要なコードを見逃す、またはノイズが多すぎる場合は、より狭い/広いインデックスパスを **提案** する。保存パスの変更には `--reset-paths` または `--rebuild` が必要; どちらもユーザーの明示的な確認が必要。

## 検証後に記録する

ユーザーが作業が正しいと確認したら:

1. **記録内容を提案** — どのページがその事実のホームか、ADR が必要か、短いドラフト。編集前に承認を待つ。
2. **単一ホームを見つける** — トピックを `docs/wiki/**` にスコープして検索。そのページを更新; なければ適切なセクション下に作成し `index.md` に追加。
3. ***what* だけでなく *why* を書く。** 構造的/アーキテクチャ上の決定には `decisions/` に ADR を追加または更新（`templates/adr.md` を使用）。
4. **相互参照** — 文章をコピーせず、関連ページへリンク。
5. **編集後に再インデックス** — 増分 `zg index`、続けて `zg status` で準備完了を確認。

差分は小さくレビュー可能に保つ — ユーザーは wiki の変更をコードと同様にレビューする。

## ブートストラップ（リポジトリ初回）

このスキルパッケージから `scripts/zg-bootstrap.sh` を実行する。冪等で非破壊的:

```bash
bash scripts/zg-bootstrap.sh                          # エージェント自動検出
bash scripts/zg-bootstrap.sh --target cursor codex    # 明示的ターゲット; zg help install を参照
bash scripts/zg-bootstrap.sh --embedding <model>      # デフォルト wiki 埋め込みを上書き
```

Node.js 22+ が必要。スクリプトは `zg` を解決し、`docs/wiki/` のひな形を生成し、`AGENTS.md` ホットメモリを upsert し、`zg install` を実行し、zg デフォルト探索で最初のインデックスを構築する。MCP 設定後にエージェントを再起動する。

手動セットアップやトラブルシューティングは `zg help` と `zg help install` に従う。

## ガードレール

- 明示的な確認なしに `--rebuild`、`--drop`、`--reset-paths` を実行 **しない**。
- 未検証の作業から wiki を更新したり、同じ事実を 2 ファイルにコピーしたり **しない**。
- コンテキストを肥大化させ **ない**: ファイル全体を開くよりランク付けされた zg 証拠を優先する。
- ここに zg ドキュメントを重複させ **ない** — インストール済み CLI が正。

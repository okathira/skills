---
name: zvec-llm-wiki-ja
description: >-
  zvec-grep (zg) でプロジェクトの LLM wiki (docs/wiki/) を ingest、query、lint、record、crystallize する。
  LLM wiki、living docs、ナレッジベース、wiki 整備、sources、entities、concepts、analyses、ADR、runbooks で使う。
  Web 検索や wiki 以外の Markdown には使わない。
license: Proprietary. Internal use.
---

# zvec-grep による LLM wiki の維持

## 概要

`docs/wiki/` を、人間とエージェントが共有する、生きて複利的に育つ知識システムとして運用する。
`zg`（zvec-grep）が唯一の検索エンジン。ループは次のとおり:

> **Query → Work → Ingest/Record/Crystallize → Lint → 増分 `zg index`**

Wiki の書き込みは strict ではなく **involved**: ページと変更予定を示し、ユーザーが止めなければ
同じターンで編集する。変更は小さく、根拠へのリンクを保つ。事前承認が必要なのは破壊的な
インデックス操作だけ。

## Wiki 構造（`docs/wiki/`）

原則: **1 事実 1 ホーム、コピーではなくリンク。**

```
docs/wiki/
  index.md          # 種別ごとのレジストリ、リンクと 1 行要約
  log.md            # 操作の追記タイムライン
  sources/          # ソース要約と来歴
  entities/         # 人、システム、プロジェクト、製品
  concepts/         # 用語、パターン、ルール、アイデア
  analyses/         # 統合分析と crystallize した回答
  decisions/        # 任意の coding overlay: ADR
  runbooks/         # 任意の coding overlay: 手順
raw/                # 任意のプロジェクトルートの不変なインポート済み Markdown
```

生きた文書は wiki に置く。インポートしたダンプは `raw/` に置いて不変にできる。実行コードは
raw な証拠として索引・検索するが、コードベース全体を wiki ページへ編纂しない。PDF/Office は
ingest 前に Markdown へ変換すること。PDF のネイティブ ingest は非対応。リンクは相対 `.md`
を使い、`[[wikilinks]]` は使わない。

## 操作

### Query

1. `docs/wiki/index.md` を読む。
2. レジストリで足りなければ、`docs/wiki/**` にスコープした zg hybrid 検索を使う。
3. 既知の名前、パス、完全一致 alias、日本語の固有名詞には zg managed rg（必要なら native
   `rg`）を使う。
4. wiki の証拠が不足するときだけ `raw/**` またはコードへ広げる。
5. ランク付けされた証拠が十分なら止める。「念のため」にファイル全体を開かない。

### Ingest と record

- ページ計画を示し、止められなければ続行する。
- wiki スコープの hybrid と完全一致 alias の rg で既存ホームを探す。
- 文書は少数の短いページへ深く編纂し、コードは編纂せず浅く索引する。
- 各ページ先頭の frontmatter（`---` で囲む YAML）に `status` と `aliases` を置く。来歴があれば
  `source` も置く。ADR なら `date` と `deciders` もここ。同じキーを見出しや本文へ写さない
  （`## Aliases` や、`source` を繰り返す Source 節は置かない）。値のないキーは書かない
  （`superseded_by` は置き換え時だけ）。
- aliases はユビキタス言語: そのページが所有する事実の高シグナルな名前をおおよそ 3–6 個、
  wiki の執筆言語で。1 個の同義語でもシソーラスでもない。共有定義は glossary（または
  concepts の 1 ページ）に置き、他ページは alias するだけで再定義しない。別言語・別表記は
  rg でその完全一致が必要なときだけ足す。
- ingest または大きな record では `index.md` を更新し `log.md` に追記する。
- 却下案と行き止まりを保持し、履歴を削除せず superseded として印を付ける。

### Crystallize

十分な根拠を持つ query 結果を `analyses/` に永続化する。事実を他ページへ複製せず、登録して
操作ログを残す。

### Lint

- wiki の全 `.md` ページが `index.md` に登録済みで、全相対 `.md` リンクが解決する。
- 矛盾は節または `analyses/` ページへ明示的に隔離し、黙って統合しない。
- `raw/` を source とするページが source path と任意の raw ダンプ hash に追随している。
- 過大ページが 1 事実または有用な見出し単位でなくなったら分割する。
- リネームと古い完全一致参照を rg で確認する。
- superseded な主張と行き止まりが残っている。
- 内容ページが自分の事実の高シグナルな frontmatter `aliases` を複数持ち、frontmatter を本文へ
  再掲せず、共有用語の定義は glossary ページに 1 箇所だけある。

wiki 編集後は増分 `zg index` を実行し、新しい query に依存する前に `zg status`/freshness を
確認する。詳細なガバナンスとログ形式は `references/wiki-workflow.md` を読む。

## zg の使い方

このスキルが定義するのは CLI 構文ではなく **いつ** 使うか。`zg help query`、`zg help
index`、`zg help install`、`zg help models` を実行し、フラグを推測しない。1 つの
workspace index を query 時の scope で wiki、raw、code に使う。多言語デフォルト
`local/potion-multilingual-128m` を維持する。`local/qwen3-embedding-0.6b` は同じ
エンジン内の品質向上策だが rebuild が必要なため承認必須。qmd や第 2 の indexer は追加しない。

## ブートストラップ

```bash
bash scripts/zg-bootstrap.sh                          # エージェント自動検出
bash scripts/zg-bootstrap.sh --target cursor codex    # 明示的ターゲット; zg help install を参照
bash scripts/zg-bootstrap.sh --embedding <model>      # デフォルト wiki 埋め込みを上書き（一覧: zg help models）
```

Node.js 22+ が必要。`docs/wiki/` がないときだけ有用なひな形を作り、`AGENTS.md` の
ホットブロックを upsert し、zg を設定して 1 つの index を構築または増分更新する。既存 wiki
には触れない。

ユーザーの明示的な承認なしに `--rebuild`、`--drop`、`--reset-paths` を実行しない。

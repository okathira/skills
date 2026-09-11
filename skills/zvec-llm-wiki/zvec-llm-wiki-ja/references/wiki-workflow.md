# LLM wiki ワークフローとガバナンス

ingest、query、lint、record、crystallize の詳細リファレンス。

## Karpathy との対応

| Karpathy の層/操作 | このスキル |
| --- | --- |
| Raw sources（不変） | 任意の `raw/` インポート済み Markdown。実行コードは raw な証拠のまま |
| Wiki（編纂・複利） | `sources/`、`entities/`、`concepts/`、`analyses/` |
| 任意の coding overlay | `decisions/`、`runbooks/` |
| Schema | `index.md`、ページの frontmatter/見出し、`AGENTS.md` ホットブロック |
| Ingest | 文書を深く編纂、コードを浅く索引、レジストリとログを更新 |
| Query | index → wiki スコープ zg hybrid → 名前は rg → widen |
| Lint | 登録、リンク、矛盾、鮮度、サイズ、リネーム、履歴 |
| Record | 予定ページを示し、止められなければ書く（involved） |
| Crystallize | 永続化すべき query の統合結果を `analyses/` に保存 |
| Log | 追記専用の `log.md` タイムライン |

検索エンジンは zg だけ。qmd 連携、第 2 の index、strict な wiki 書き込みロックはない。

## 不変条件

1. `docs/wiki/` が生きた知識のホーム。ミラーは正ではない。
2. 1 事実 1 ホーム。相対 `.md` リンクを使い、文章コピーや `[[wikilinks]]` は使わない。
3. 全ページを 1 行要約付きで `index.md` からリンクし、zg で索引する。
4. 書き込みは involved: ページ計画と根拠を示し、ユーザーが止めなければ編集する。
5. 矛盾は見える形で隔離し、却下した経路は `superseded` として保持する。
6. 増分 `zg index` は通常操作。`--rebuild`、`--drop`、`--reset-paths` は明示的な承認必須。

## ページ契約

ページは薄い YAML frontmatter を使う:

```yaml
---
status: working # working | decided
aliases:
  - 完全一致させる別名
source: raw/example.md # プロジェクトルートの raw path、リポジトリ path、または URL
---
```

この frontmatter は coding overlay を含むすべての内容ページに置く。`index.md` と `log.md` は
schema とタイムラインなので素のままにする。zg は frontmatter を独立チャンクとして索引し、rg は
ファイル全体を読むので、frontmatter のキーを本文へ複製しない。続けて 1 行リードと `What`、
`Why`、`Related` などの有用な H2 節を置く。外部 source がなければ `source` は省略する。hash は
任意で、不変の `raw/` ダンプだけに使い、コードベースには使わない。`Related` と ADR の
`References` は wiki グラフであり、`source` に既にある URL や path を再掲しない。

`decisions/` のページは enum を ADR ライフサイクルに置き換え、決定のメタデータを加える。
本文の行と frontmatter がずれないよう、ライフサイクルのホームは 1 つだけにする:

```yaml
---
status: accepted # proposed は working、accepted と superseded は decided
date: 2026-09-08
deciders: 名前
---
```

置き換える ADR ができるまで `superseded_by` は書かない。外部の来歴がなければ `source` は
省略する。空キーは残さない。

出発点として `templates/wiki-page.md`、`templates/adr.md`、`templates/runbook.md` を使う。

## ユビキタス言語と aliases

aliases はそのページが所有する事実の検索用の名前であり、追加の本文でも第 2 の glossary でもない。

- 人が実際に打つ高シグナルな句を **おおよそ 3–6 個**（`involved write`、`hot memory`、
  `zg-bootstrap` など）。同義語 1 個は薄すぎ、シソーラスは厚すぎ。
- **wiki の執筆言語**で書く。漢字・カナ・英語（または別表記）は、rg でその完全一致が必要な
  ときだけ足す。
- glossary（または `concepts/` の 1 ページ）が共有用語の定義を所有する。他ページは自分の
  事実の名前だけを列挙し、定義をコピーしない。
- ホームは 1 つ: `aliases`、`source`、`status`、ADR の `date` / `deciders` /
  `superseded_by` は frontmatter だけ。frontmatter を写す `## Aliases` や Source 見出しは置かない。見出し
  抽出のための H2 複製は試して superseded。

ingest や record の同じ編集で aliases を足す。薄い alias リストは frontmatter 欠けと同じ lint
対象。

## 段階的 query

1. `docs/wiki/index.md` を読む。
2. カタログで足りなければ `docs/wiki/**` にスコープした zg hybrid 検索を使う。
3. 既知の名前、alias、path、日本語固有名詞には zg managed rg（または native rg）を使う。
4. wiki の証拠が不足した後だけ `raw/**` またはコードへ広げる。
5. 証拠が十分なら止める。

現在の構文は `zg help query` を使う。1 つの workspace index がすべての scope を担う。

## Ingest の深さ

- **文書:** PDF/Office はまず Markdown に変換する。インポートした `raw/` は不変として扱い、
  hybrid と alias rg でホームを探し、主張を少数の短い wiki ページへ編纂する。
- **コード:** raw な証拠として索引・検索する。リポジトリツリーを wiki ページへ編纂しない。
- **生きた Markdown:** 2 つ目のコピーを維持せず wiki へ移動する。

各 ingest で `index.md` を更新し、`log.md` に追記し、増分 `zg index` を実行する。次の query
前に freshness を確認する。

## ログ契約

`## [YYYY-MM-DD] kind | title` を使う。kind は `ingest`、`lint`、`crystallize`、`record`。

```md
## [2026-09-08] ingest | 製品概要

- [製品](entities/product.md) を追加し、[価格](concepts/pricing.md) を更新。
- Source: `raw/product-brief.md`
```

## Lint

- wiki の `.md` ファイルと `index.md` を比較し孤児を見つける。
- 全相対 `.md` リンクを解決し、wikilink を許可しない。
- hybrid 検索で意味的な矛盾を探し、競合する主張を統合せず隔離する。
- `raw/` から編纂したページの source path と任意 hash を確認する。
- 1 事実または有用な見出し単位を超えたページを分割する。
- リネーム後の古い名前を rg で探す。
- 行き止まりと superseded な主張を保持する。
- 検索を汚して答えを持たない、タイトルだけ・見出しだけの stub を拒否する。
- 内容ページの `aliases` が空または同義語 1 個なら拒否する。高シグナルな frontmatter 名が複数、
  frontmatter の本文再掲なし、共有定義は glossary 1 ページ、を期待する。

## ホットメモリと埋め込み

ホットブロックは、まず `index.md`、次に wiki スコープの zg、書き込み計画を示して止められなければ
続行、編集後に増分 `zg index`、という順序を示す。

デフォルトは `local/potion-multilingual-128m` のまま。より高品質な同一エンジンの選択肢は
`local/qwen3-embedding-0.6b`。切り替えには rebuild と明示的な承認が必要。インストール済み
カタログは `zg help models` を使う。

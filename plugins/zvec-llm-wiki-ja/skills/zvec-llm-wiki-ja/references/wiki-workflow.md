# LLM wiki ワークフローとガバナンス

ingest、query、lint、record、crystallize の詳細リファレンス。書式は OKF v0.3 で、フィールドの規則は
公式の `okf-generate` スキルが担う。このファイルには llm-wiki が加えるもの・決めたものだけを書く。

## Karpathy との対応

| Karpathy の層/操作 | このスキル |
| --- | --- |
| Raw sources（不変） | bundle 外の任意の `docs/raw/` インポート済み Markdown。実行コードは raw な証拠のまま |
| Wiki（編纂・複利） | `summaries/`、`entities/`、`concepts/`、`analyses/` |
| 任意の coding overlay | `decisions/`、`runbooks/` |
| Schema | OKF frontmatter、生成される `index.md`、`AGENTS.md` ホットブロック |
| Ingest | 文書を深く編纂、コードを浅く索引、log 追記と index 再生成 |
| Query | index 群 → wiki スコープ zg hybrid → 名前は rg → widen |
| Lint | `llm_wiki.py lint --strict`（`validate.py` も実行）、その後に判断が要る確認 |
| Record | 予定ページを示し、止められなければ書く（involved） |
| Crystallize | 永続化すべき query の統合結果を `analyses/` に保存 |
| Log | 新しい日付が上の OKF `log.md` |

検索エンジンは zg だけ。qmd 連携、第 2 の index、strict な wiki 書き込みロックはない。

## 不変条件

1. `docs/wiki/` が bundle root であり、生きた知識のホーム。ミラーは正ではない。
2. 1 事実 1 ホーム。相対 `.md` リンクを使い、文章コピーや `[[wikilinks]]` は使わない。
3. 中身のあるディレクトリにはすべて生成された `index.md` がある。ルートの frontmatter より下は
   手で編集しない。
4. 書き込みは involved: ページ計画と根拠を示し、ユーザーが止めなければ編集する。
5. 矛盾は見える形で隔離し、置き換えたページは `deprecated` と `superseded_by` で残す。
6. 増分 `zg.sh --index` は通常操作。`--rebuild`、`--drop`、`--reset-paths` は明示的な承認必須。

## ページ契約（OKF への llm-wiki の追加）

```yaml
---
type: Concept                     # 下のディレクトリ対応表から
title: Involved な書き込み
description: 1 文。ディレクトリ index がこれを写す。
x-zvec-aliases:
  - involved write
  - 書き込み計画
  - 止められなければ編集
generated: { by: "cursor/<model>", at: "2026-11-20T10:00:00Z" }
sources:
  - id: readme
    resource: ../../README.md     # リポジトリ内ファイル: このページからの相対パス、OKF では外部
    title: プロジェクト README
---

# What
主張を含む本文。[^readme]

[^readme]: プロジェクト README
```

| ディレクトリ | `type` |
| --- | --- |
| `summaries/` | `Reference` |
| `entities/` | `Entity` |
| `concepts/` | `Concept` |
| `analyses/` | `Analysis` |
| `decisions/` | `Decision Record` |
| `runbooks/` | `Playbook` |

- 本文は内容か H1 の節から始める。H1 タイトルとリード行の代わりに `title` と `description` を使い、
  本文で繰り返さない。
- stable なページは `status` を書かない。作業中は `draft`、置き換えたページは `deprecated` と
  `superseded_by`（`/` 始まりのパス）。
- `generated.by` は書いたエージェント（`<tool>/<model>`）。`generated.at` は意味が変わったときだけ更新する。
- `verified` には、内容を確認し ID を明示した人が必要。使える形は `human:owner`（個人プロジェクトの
  役割名）、`human:@handle`、`human:user@example.com`。エージェントは `agent:<name>` の記録を付けられるが、
  人間レビュー済みの信頼度にはならない。
- ADR の承認は `verified` の記録で表す。`date` や `deciders` キーは使わない。
- `sources[].resource` は URL、`/` 始まりの bundle 内パス、またはページからの相対パスで書いたリポジトリ
  内ファイル。個々の主張は `[^id]` 脚注で引用する。`Related` は wiki グラフであり `sources` を再掲しない。

出発点として `templates/wiki-page.md`、`templates/adr.md`、`templates/runbook.md` を使う。

## ユビキタス言語と aliases

`x-zvec-aliases` はそのページが所有する事実の検索用の名前であり、追加の本文でも第 2 の glossary でもない。
OKF の `tags` は横断的な分類なので、alias を入れない。

- 人が実際に打つ高シグナルな句を **おおよそ 3–6 個**（`involved write`、`hot memory`、
  `zg-bootstrap` など）。同義語 1 個は薄すぎ、シソーラスは厚すぎ。
- **wiki の執筆言語**で書く。漢字・カナ・英語（または別表記）は、rg でその完全一致が必要な
  ときだけ足す。
- glossary（または `concepts/` の 1 ページ）が共有用語の定義を所有する。他ページは自分の
  事実の名前だけを列挙し、定義をコピーしない。
- frontmatter を写す `# Aliases` や `# Sources` 節は置かない。

## 段階的 query

1. `docs/wiki/index.md` を読み、タスクに関係するディレクトリの index を読む。
2. index で足りなければ、`docs/wiki/**` にスコープした zg hybrid 検索を使う。
3. 既知の名前、alias、path、日本語固有名詞には zg managed rg（または native rg）を使う。
4. wiki の証拠が不足した後だけ `docs/raw/**` またはコードへ広げる。
5. 証拠が十分なら止める。`okf-consume` の信頼度、status、鮮度、矛盾の規則を適用する。

現在の構文は `zg.sh --help search` を使う。1 つの workspace index がすべての scope を担う。

## Ingest の深さ

- **文書:** PDF/Office はまず Markdown に変換する。インポートは `docs/raw/` に置き、変更しない。
  hybrid と alias rg でホームを探し、主張を少数の短い concept へ編纂して `sources` で引用する。
- **コード:** raw な証拠として索引・検索する。リポジトリツリーを wiki ページへ編纂しない。
- **生きた Markdown:** 2 つ目のコピーを維持せず wiki へ移動する。

各 ingest で `log.md` に追記し、index を再生成し、増分 `zg.sh --index` を実行する。次の query 前に
freshness を確認する。

## ログ契約

OKF の log 形式: `## YYYY-MM-DD` 見出しを新しい順に並べ、各 entry は操作名の太字
（`**Ingest**`、`**Record**`、`**Crystallize**`、`**Lint**`）で始める。今日の見出しの下に追記する。

```md
## 2026-11-20

* **Ingest**: 製品概要
  - [製品](entities/product.md) を追加し、[価格](concepts/pricing.md) を更新。
```

## Lint

`scripts/llm_wiki.py lint --strict` が両方の層を確認する:

- `okf-generate/scripts/validate.py` — OKF 準拠、frontmatter の形、actor、タイムスタンプ、脚注 ID、
  bundle 内のリンク（`--strict` ではリンク切れで失敗）。指摘はすべて報告する。concept ではない
  Markdown は bundle ではなく `docs/raw/` に置く。末尾の OKF change report は `I204`（意味の変更で
  未検証になった）と `I201`（`stale_after` を過ぎた）の件数を出す。これらは info である。ずれの検出に
  ソースファイルのハッシュは使わない。
- llm-wiki の確認 — ディレクトリと type の対応、`x-zvec-aliases` の数、OKF 以前の
  キーの残り、bundle 外を指すリポジトリパスの実在、wikilink、本文での frontmatter 再掲、`generated` や
  `description` の欠け、生成 index の古さ。

判断が要る確認:

- hybrid 検索で意味的な矛盾を探し、競合する主張を統合せず隔離する。
- `docs/raw/` から編纂したページをソースと照合する。
- 1 事実または有用な見出し単位を超えたページを分割する。
- リネーム後の古い名前を rg で探す。
- 行き止まりと deprecated な主張を保持する。
- 検索を汚して答えを持たない、タイトルだけ・見出しだけの stub を拒否する。
- `generated.at` が `verified` の記録より新しくなって信頼度が下がったページを報告する。

## ホットメモリと埋め込み

ホットブロックは、wiki が OKF bundle であること、まず index 群、次に wiki スコープの zg、書き込みは
`okf-generate`、信頼度は `okf-consume`、書き込み計画を示して止められなければ続行、編集後に index
再生成・lint・増分 `zg.sh --index`、という順序を示す。

デフォルトは `local/potion-multilingual-128m` のまま。検索品質を比較する候補は `local/embeddinggemma-300m` と
`local/qwen3-embedding-0.6b`。対応する GPU ランタイムで高速化できる。切り替えには rebuild と明示的な承認が必要。インストール済み
カタログは `zg.sh --help models` を使う。

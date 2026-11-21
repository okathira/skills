---
name: zvec-llm-wiki-ja
description: >-
  zvec-grep (zg) でプロジェクトの LLM wiki (docs/wiki/、Open Knowledge Format (OKF) v0.3 の bundle) を
  ingest、query、lint、record、crystallize する。LLM wiki、living docs、ナレッジベース、wiki 整備、
  summaries、entities、concepts、analyses、ADR、runbooks で使う。Web 検索や wiki 以外の Markdown には使わない。
license: MIT
---

# zvec-grep による OKF LLM wiki の維持

## 概要

`docs/wiki/` を、人間とエージェントが共有する、生きて複利的に育つ知識システムとして運用する。
wiki は [OKF v0.3](https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md)
の bundle。`zg`（zvec-grep）が唯一の検索エンジン。ループは次のとおり:

> **Query → Work → Ingest/Record/Crystallize → Lint → 増分 `zg --index`**

このスキルはループと llm-wiki 固有の拡張を担う。書式は公式の兄弟スキルが担う:

- **`okf-generate`** — concept、frontmatter、`sources` の脚注、ライフサイクル、index と log の書き方、
  `scripts/validate.py`。書き込みのたびに従う。
- **`okf-consume`** — 回答時の信頼度（trust tier）、status、鮮度、矛盾の判断。

Wiki の書き込みは **involved**: ページと変更予定を示し、ユーザーが止めなければ同じターンで
編集する。変更は小さく、根拠へのリンクを保つ。事前承認が必要なのは破壊的なインデックス操作だけ。

## Wiki 構造

原則: **1 事実 1 ホーム、コピーではなくリンク。** 各ディレクトリは 1 つの `type` に対応する:

```
docs/wiki/                # bundle root。index.md に okf_version、title、description
  index.md  log.md        # 生成されるディレクトリ index。新しい日付が上の log
  summaries/   Reference        # ソース要約と来歴
  entities/    Entity           # 人、システム、プロジェクト、製品
  concepts/    Concept          # 用語、パターン、ルール、アイデア
  analyses/    Analysis         # 統合分析と crystallize した回答
  decisions/   Decision Record  # 任意の coding overlay: ADR
  runbooks/    Playbook         # 任意の coding overlay: 手順
docs/raw/                     # 任意の不変なインポート。bundle の外なので concept ではない
```

実行コードは raw な証拠として索引・検索するが、コードベースをページへ編纂しない。PDF/Office は
ingest 前に Markdown へ変換し、その Markdown は `docs/raw/` に置く。リポジトリ内のファイルは
ページからの相対パスで出典にする。bundle の外に解決されるので OKF では外部扱いになる。
`[[wikilinks]]` は使わない。

## 操作

### Query

1. `docs/wiki/index.md` を読み、タスクに関係するディレクトリの index だけを読む。
2. index で足りなければ、`docs/wiki/**` にスコープした zg hybrid 検索を使う。
3. 既知の名前、パス、alias、日本語の固有名詞には zg managed rg（または native `rg`）を使う。
4. wiki の証拠が不足するときだけ `docs/raw/**` またはコードへ広げる。
5. ランク付けされた証拠が十分なら止める。`okf-consume` に従い信頼度、status、鮮度を報告し、
   deprecated のページからは答えず `superseded_by` を辿る。

### Ingest と record

- ページ計画を示し、止められなければ続行する。
- wiki スコープの hybrid と完全一致 alias の rg で既存ホームを探す。
- 文書は少数の短い concept へ深く編纂し、コードは編纂せず浅く索引する。
- `okf-generate` に従って書き、`references/wiki-workflow.md` の llm-wiki キーを加える:
  ディレクトリから決まる `type`、`x-zvec-aliases`、意味を変えるたびの `generated`。
- `verified` は、人が内容を確認し `human:owner` のような ID を明示したときだけ足す。
- `log.md` に追記し、`python3 <skills-dir>/zvec-llm-wiki-ja/scripts/llm_wiki.py index` で index を
  再生成する。
- 却下案を保持する: 置き換えたページは `status: deprecated` と `superseded_by` を付けて残す。

### Crystallize

十分な根拠を持つ query 結果を `analyses/` に Analysis として永続化する。事実を他ページへ複製せず、
操作ログを残す。

### Lint

プロジェクトルートで lint を実行し、指摘を直してから wiki に依拠する。lint はこのスキルと同じ
ディレクトリ（例: `.agents/skills/`）にある `okf-generate` の `validate.py` で OKF 準拠とリンクを
確認し、続けて llm-wiki 層の確認と index の鮮度を確認する:

```bash
python3 <skills-dir>/zvec-llm-wiki-ja/scripts/llm_wiki.py lint --strict
```

lint は `validate.py` の指摘をすべて報告する。bundle 内で `type` の無い Markdown は W120 になる。
OKF ではこの警告は README のようなファイルのためのものなので、不変なインポートは `docs/raw/` に置く。

続けてスクリプトでは判断できないことを確認する: 矛盾が統合されず隔離されている、過大ページが
分割されている、リネーム後の古い名前（rg）、deprecated な主張が残っている、alias がそのページの
事実だけを指している。詳細は `references/wiki-workflow.md`。

wiki 編集後は増分 `zg --index` を実行し、新しい query に依存する前に `zg --status`/freshness を確認する。

## zg の使い方

このスキルが定義するのは CLI 構文ではなく **いつ** 使うか。`zg --help search`、`zg --help
index`、`zg --help install`、`zg --help models` を実行し、フラグを推測しない。1 つの workspace index を
query 時の scope で wiki、references、code に使う。多言語デフォルト `local/potion-multilingual-128m`
を維持する。`local/qwen3-embedding-0.6b` は同じエンジン内の品質向上策だが rebuild が必要なため
承認必須。qmd や第 2 の indexer は追加しない。

## ブートストラップと移行

```bash
bash scripts/zg-bootstrap.sh                          # エージェント自動検出
bash scripts/zg-bootstrap.sh --target cursor codex    # 明示的ターゲット; zg --help install を参照
bash scripts/zg-bootstrap.sh --embedding <model>      # デフォルト wiki 埋め込みを上書き（一覧: zg --help models）
```

Node.js 22+ と、PyYAML 入りの Python 3.9+ が必要。`docs/wiki/` がないときだけ OKF bundle のひな形を
作り、`AGENTS.md` のホットブロックを upsert し、zg を設定して 1 つの index を構築または増分更新する。
既存 wiki には触れない。`type` frontmatter の無い wiki は OKF 以前の形式なので、
`zvec-llm-wiki-okf-migrate-ja` スキルで移行する。

ユーザーの明示的な承認なしに `--rebuild`、`--drop`、`--reset-paths` を実行しない。

プラグイン経由で導入した場合は、対象プロジェクトのルートでこのスクリプトに
`--skip-mcp` を渡す。MCP の検索では対象プロジェクトの絶対パスを `root` に指定する。

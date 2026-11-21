---
name: zvec-llm-wiki-okf-migrate-ja
description: >-
  OKF 以前の zvec-llm-wiki の wiki（type キーの無い docs/wiki/ のページ、status の working/decided、aliases、
  source、ADR の date/deciders、`## [date] kind | title` 形式の log）を Open Knowledge Format v0.3 の bundle へ
  一度だけ移行し、最後に人のレビューで承認を記録する。LLM wiki を OKF へ移行・変換・更新するよう頼まれたとき、
  または zvec-llm-wiki-ja の lint が OKF 以前のキーを報告したときに使う。日常の wiki 編集には使わない。
license: MIT
---

# LLM wiki を OKF v0.3 へ移行する

このスキルは、旧来の zvec-llm-wiki のページ契約で書かれた wiki を、`zvec-llm-wiki-ja` が今維持している
OKF bundle へ変換する。同じスキルディレクトリに次の兄弟スキルが必要: `zvec-llm-wiki-ja`
（`llm_wiki.py` 用）、`okf-generate`（`validate.py` と書き方の規則）。PyYAML 入りの Python 3.9+ も必要。

移行は全ページを書き換えるので、`generated.at` が移行時刻になり、すべての concept が未検証になる。
これは想定どおりで、移行が OKF の信頼度の起点になる。最後の手順で人に結果を確認してもらい、
その承認を記録する。

## 変換スクリプトがすること

`scripts/okf_migrate.py convert` は冪等で、`type` を既に持つページは飛ばす。

| 変換前 | 変換後 |
| --- | --- |
| `type` なし | ディレクトリから `type`（`summaries/` Reference、`entities/` Entity、`concepts/` Concept、`analyses/` Analysis、`decisions/` Decision Record、`runbooks/` Playbook） |
| H1 タイトルと 1 文のリード（`> ...` またはリンクのない 1 行） | `title` と `description`。それより長い書き出しは本文に残し、残りの見出しは 1 段上げる |
| `status: working` / `proposed` | `status: draft` |
| `status: decided` / `accepted` | `status` なし（stable） |
| `status: superseded`、`superseded_by` | `status: deprecated`、`/` 始まりの `superseded_by` |
| `aliases` | `x-zvec-aliases` |
| `source`（パスまたは URL のリスト） | `id`、`resource`、対象ファイルに H1 があれば `title` を持つ `sources` |
| ADR の `date` + `deciders` | 過去の `verified` 記録（`owner` は `human:owner`、`@h` は `human:@h`） |
| `sources/` ディレクトリ | `summaries/`。リンクを書き換え、旧パスに deprecated のスタブを残す（不要なら `--no-stubs`） |
| プロジェクト直下の `raw/` または `docs/wiki/references/` | bundle 外の `docs/raw/` |
| `## [YYYY-MM-DD] kind \| title` の log | 新しい順の `## YYYY-MM-DD` ごとに `* **Kind**: title` と入れ子の詳細 |
| frontmatter の無いルート `index.md` | `okf_version: "0.3"`、`title`、`description`（`license` は指定時だけ） |

知らないキーは残す。変換したページにはすべて `generated: { by: <actor>, at: <now> }` を付ける。

## 手順

プロジェクトルートで実行する。`<skills>` はこれらのスキルがあるディレクトリ（例: `.agents/skills`）。

1. **開始状態を確認する。** git の作業ツリーがクリーンで、`<skills>/okf-generate` と
   `<skills>/zvec-llm-wiki-ja` があり、`python3 -c 'import yaml'` が通る。OKF スキルが無ければ
   `zvec-llm-wiki-ja` の `install.sh` を `--no-okf` なしで再実行する。
2. **ドライランと計画。** ユーザーにページ計画を示す:

   ```bash
   python3 <skills>/zvec-llm-wiki-okf-migrate-ja/scripts/okf_migrate.py convert --dry-run --actor "<tool>/<model>"
   ```

   bundle の `title` と 1 文の `description` をユーザーから得ていなければ尋ねる。`--license` は
   プロジェクトがライセンスを明示しているときだけ渡し、推測しない。
3. **変換と index 生成。**

   ```bash
   python3 <skills>/zvec-llm-wiki-okf-migrate-ja/scripts/okf_migrate.py convert --actor "<tool>/<model>" \
     --title "<bundle のタイトル>" --description "<1 文>"
   python3 <skills>/zvec-llm-wiki-ja/scripts/llm_wiki.py index
   ```

4. **note を解消する。** `note:` 行ごとに、`okf-generate` に従ってページを手で直す: description を
   1 文にする、`sources` の各項目に `title` を付ける、対応表に無いディレクトリに `type` を決める。
   続けてスクリプトでは判断できないことを確認する: frontmatter を本文で繰り返している箇所（alias や
   出典の一覧）、リンクがあるか 1 文より長いために本文に残ったリード文、旧ページ契約を説明したままの wiki ページ。
5. **検証する。** エラーと警告をすべて直す。lint は `okf-generate` の `validate.py` と llm-wiki の
   確認をまとめて実行する:

   ```bash
   python3 <skills>/zvec-llm-wiki-ja/scripts/llm_wiki.py lint --strict
   ```

   旧 ADR の `I204`（info）はレビュー手順までは想定どおり。
6. **log と index。** `log.md` の今日の日付に `* **Record**: wiki を OKF v0.3 へ移行した` を足し、
   index を再生成し、導入済みの `zvec-llm-wiki-ja` スキルに同梱の `scripts/zg.sh --index` で増分更新する。
7. **確認と承認。** 移行したページをディレクトリごとにユーザーへ示す: frontmatter、description、
   手順 4 で判断して直した箇所。ページまたはグループごとに確認してもらい、記録する ID を明示して
   もらう。個人プロジェクトなら `human:owner` でよい。ID を git の設定やマシンから推測しない。
   確認されたページだけを記録する:

   ```bash
   python3 <skills>/zvec-llm-wiki-okf-migrate-ja/scripts/okf_migrate.py verify --actor "human:<id>" <page.md>...
   ```

   確認されなかったページは未検証のまま残す。`llm_wiki.py lint --strict` を再実行してからコミットする。
8. **報告する。** 変換したページ、解消した note、人間レビュー済みになったページ、未検証のまま
   残ったページ、検証結果。

承認を記録した後にページの意味を変えない。後から意味を変えたら `generated.at` を更新し、改めて
レビューを受ける。

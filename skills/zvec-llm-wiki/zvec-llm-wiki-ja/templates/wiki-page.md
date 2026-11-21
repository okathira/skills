---
type: <Reference | Entity | Concept | Analysis — ディレクトリから>
title: <このページが所有する 1 事実>
description: <1 文。ディレクトリ index がこれを写す。>
x-zvec-aliases:
  - <エージェントが打つ高シグナルな名前>
  - <会話で使う同義語>
  - <短い形またはコード名>
generated: { by: "<tool>/<model>", at: "<YYYY-MM-DDTHH:MM:SSZ>" }
sources:
  - id: <source-id>
    resource: <URL、bundle 内の /path.md、または ../../raw/file.md のようなこのページからの相対パス>
    title: <ソースのタイトル>
---

# What

現状。焦点を保ち、根拠をコピーせずリンクする。[^<source-id>]

# Why

source だけでは説明できない意図、制約、矛盾、保持すべき行き止まり。

# Related

- [関連ページ](../concepts/related-page.md) — wikilink ではなく相対 `.md` リンクを使う。

[^<source-id>]: <ソースのタイトル>

<!-- ソースで埋められないキーは消す。stable なページは status を書かず、draft か
deprecated + superseded_by を使う。log.md に追記し、llm_wiki.py index、lint、増分 `zg --index` を実行する。 -->

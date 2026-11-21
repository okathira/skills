---
type: Decision Record
title: "ADR-NNNN: <短い決定タイトル>"
description: <このページが所有する決定を 1 文で。>
status: draft
x-zvec-aliases:
  - ADR-NNNN
  - <この決定の高シグナルな名前>
  - <エージェントが打つ短い形>
generated: { by: "<tool>/<model>", at: "<YYYY-MM-DDTHH:MM:SSZ>" }
sources:
  - id: <source-id>
    resource: <URL、またはこのページからの相対パスで書いたリポジトリ内ファイル>
    title: <ソースのタイトル>
---

# Context（背景）
どのような問題や要因が決定を必要としたか? コードや issue へリンク。事実に留める。[^<source-id>]

# Decision（決定）
選んだ内容を 1〜2 文で述べる。

# Why (rationale)（理由）
コードスキャンでは復元できない推論: トレードオフ、制約、前提。

# Alternatives considered（検討した代替案）
- **Option A** — 却下理由: ...
- **Option B** — 却下理由: ...

# Consequences（影響）
ポジティブ、ネガティブ、フォローアップ。何が楽/難しくなるか。注意すべき落とし穴。

# References（参照）
wiki グラフのみ。`sources` をここに再掲しない。

[^<source-id>]: <ソースのタイトル>

<!-- 提案中は status: draft。承認されたら status を消し、決定者が確認して ID を明示したときだけ
承認を verified の記録として残す。例: verified: [{ by: "human:owner", at: "<now>" }]。
置き換えられたら status: deprecated と superseded_by: /decisions/ADR-MMMM-....md を付ける。
log.md に追記し、llm_wiki.py index、増分 `zg index` を実行する。 -->

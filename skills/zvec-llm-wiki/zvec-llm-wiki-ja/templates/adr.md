---
status: proposed # proposed (working) | accepted (decided) | superseded
date: YYYY-MM-DD
deciders: <名前>
aliases:
  - ADR-NNNN
  - <この決定の高シグナルな名前>
  - <エージェントが打つ短い形>
source: <path、URL、またはこのキーを省略>
---

# ADR-NNNN: <短い決定タイトル>

このページが所有する決定の 1 行要約。

## Context（背景）
どのような問題や要因が決定を必要としたか? コードや issue へリンク。事実に留める。

## Decision（決定）
選んだ内容を 1〜2 文で述べる。

## Why (rationale)（理由）
コードスキャンでは復元できない推論: トレードオフ、制約、前提。

## Alternatives considered（検討した代替案）
- **Option A** — 却下理由: ...
- **Option B** — 却下理由: ...

## Consequences（影響）
ポジティブ、ネガティブ、フォローアップ。何が楽/難しくなるか。注意すべき落とし穴。

## References（参照）
wiki グラフのみ。`source` の URL や path はここに再掲しない。

<!-- この ADR を 1 行要約付きで docs/wiki/index.md に登録し、log.md に追記後、増分 `zg index` を
実行する。status、date、deciders、superseded_by、aliases、source は frontmatter だけ。空キーは
省略し、superseded_by は置き換え時だけ足す。 -->

---
type: Playbook
title: "Runbook: <この手順が完了させる作業>"
description: <この手順が達成することと、いつ実行するかを 1 文で。>
x-zvec-aliases:
  - <手順の短い名前>
  - <エージェントが打つコマンドまたはスクリプト>
  - <いつ実行するかの句>
generated: { by: "<tool>/<model>", at: "<YYYY-MM-DDTHH:MM:SSZ>" }
sources:
  - id: <source-id>
    resource: <このページからの相対パスで書いたスクリプト、または URL>
    title: <ソースのタイトル>
---

# Prerequisites（前提）
ツール、バージョン、権限、手順が前提とする実行ディレクトリ。

# Steps（手順）
番号付きでコピペ可能なコマンドと、各段階の期待結果。[^<source-id>]

# Verification（確認）
成功の確認方法。成功を示す出力を返すコマンドを含める。

# Troubleshooting（切り分け）
| 症状 | 対処 |
|------|------|
| <観測した失敗> | <対処、またはそれを所有するページ> |

# Related（関連）
この手順が依存する concept、entity、decision への相互リンク。

[^<source-id>]: <ソースのタイトル>

<!-- 検証済みの事実はここに複製せず、所有するページに記録する。log.md に追記し、llm_wiki.py index、
lint、増分 `zg.sh --index` を実行する。 -->

---
status: decided # working | decided
aliases:
  - <手順の短い名前>
  - <エージェントが打つコマンドまたはスクリプト>
  - <いつ実行するかの句>
source: <path、URL、またはこのキーを省略>
---

# Runbook: <この手順が完了させる作業>

この手順が達成することと、いつ実行するかの 1 行要約。

## Prerequisites（前提）
ツール、バージョン、権限、手順が前提とする実行ディレクトリ。

## Steps（手順）
番号付きでコピペ可能なコマンドと、各段階の期待結果。

## Verification（確認）
成功の確認方法。成功を示す出力を返すコマンドを含める。

## Troubleshooting（切り分け）
| 症状 | 対処 |
|------|------|
| <観測した失敗> | <対処、またはそれを所有するページ> |

## Related（関連）
この手順が依存する concept、entity、decision への相互リンク。

<!-- この runbook を 1 行要約付きで docs/wiki/index.md に登録し、増分 `zg index` を実行する。
検証済みの事実はここに複製せず、所有するページに記録する。 -->

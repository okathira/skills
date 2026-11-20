# zvec-llm-wiki-okf-migrate（日本語版）

旧来の [`zvec-llm-wiki-ja`](../../zvec-llm-wiki/zvec-llm-wiki-ja/) のページ契約で書かれた wiki を
[Open Knowledge Format（OKF）v0.3](https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md)
の bundle へ移行し、人による確認を経て承認を記録する [Agent Skill](https://agentskills.io/)。

一度だけ使う道具なので、日常の `zvec-llm-wiki-ja` スキルを小さく保つために分けている。

## レイアウト

```
skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate-ja/
  README.md                 # このファイル（カタログ / 人間向け）
  install/install.sh        # スキルをエージェントのスキルディレクトリへコピー
  SKILL.md                  # エージェント向けエントリポイント: 移行手順
  scripts/okf_migrate.py    # ページ、log、ルート index の変換と、承認の記録
```

## インストール

先に `zvec-llm-wiki-ja` を入れ（その `install.sh` が `okf-generate` と `okf-consume` も取得する）、
同じスコープにこのスキルを入れる:

```bash
cd your-repo
sh /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki-ja/install/install.sh
sh /path/to/skills/skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate-ja/install/install.sh
```

`--user`、`--claude`、`--force` も同じように使える。PyYAML 入りの Python 3.9+ が必要。エージェントを
再起動し、wiki を OKF へ移行するよう頼む。移行をコミットした後は、このスキルを削除してよい。

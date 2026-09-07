# Agent Skills catalog

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-spec-111827?style=flat-square)](https://agentskills.io/) [![zvec-grep](https://img.shields.io/badge/search-zvec--grep-4f46e5?style=flat-square)](https://github.com/zvec-ai/zvec-grep)

コーディングエージェント向けスキル — [Cursor](https://cursor.com/)、Codex、OpenCode、Claude Code。

[English](README.md) · [日本語](README.ja.md)

各スキルは独立したフォルダです。インストールすると、エージェントは作業中に `SKILL.md` に従います。

## スキル

| スキル | できること | English |
|--------|------------|---------|
| [ja/zvec-llm-wiki](ja/zvec-llm-wiki/) | LLM 向け wiki（`docs/wiki/`）を同期し、検索レイヤーに [zvec-grep](https://github.com/zvec-ai/zvec-grep) を使う | [zvec-llm-wiki](zvec-llm-wiki/) |

## クイックスタート

```bash
# 英語ロケール（デフォルト）
sh zvec-llm-wiki/install/install.sh

# 日本語ロケール
sh ja/zvec-llm-wiki/install/install.sh
```

カタログを pull したあとは `--force` で再実行する。インストール後はエージェントを再起動する。

インストールはスキルファイルをエージェント用ディレクトリへコピーする（このカタログ README はコピーしない）。続けて、対象プロジェクトで `scripts/zg-bootstrap.sh` を実行する。手順の全体: [日本語 README](ja/zvec-llm-wiki/README.md) · [English](zvec-llm-wiki/README.md)。

## 言語ポリシー

デフォルトは英語（エージェントのトークン負荷を抑えるため）。日本語はオプトイン。

| | 英語 | 日本語 |
|---|------|--------|
| **スキル** | リポジトリ直下。例: `zvec-llm-wiki/` — フォルダ名は `SKILL.md` の `name` と一致 | `ja/<skill-name>/`。例: `ja/zvec-llm-wiki/` — 別の `name`（`zvec-llm-wiki-ja`） |
| **このトップページ** | [`README.md`](README.md)（GitHub の既定表示） | [`README.ja.md`](README.ja.md) |

- **独立性:** 各ロケールのスキルフォルダは単体で完結する。そのフォルダだけ取り出せばインストールと実行ができる。ファイル構成は 1 対 1（`SKILL.md`、`install/`、`scripts/`、`references/`、`templates/`）。シンボリックリンクや実行時の他ロケール参照はしない。挙動とフラグは揃え、自然言語と `name` だけ変える。
- **メンテナンス:** 挙動を変えるときは全ロケールを同じ変更で直す。カタログのトップ説明を変えるときは `README.md` と `README.ja.md` を同時に直す（同じ見出し、同じ事実）。インストールはロケールを 1 つ選ぶ。

## 関連

- [Agent Skills 仕様](https://agentskills.io/specification)
- [zvec-grep](https://github.com/zvec-ai/zvec-grep)
- [Karpathy — LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)

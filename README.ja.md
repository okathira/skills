# Agent Skills catalog

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-spec-111827?style=flat-square)](https://agentskills.io/)

コーディングエージェント向けスキル — [Cursor](https://cursor.com/)、Codex、OpenCode、Claude Code。

[English](README.md) · [日本語](README.ja.md)

**独立した** Agent Skill を集めたカタログです。スキルごとにパッケージを足し、エージェントへ入れて、このリポジトリでもドックフーディングしていきます。インストール後、エージェントはそのスキルの `SKILL.md` に従います。

## スキル

| スキル | できること | English |
|--------|------------|---------|
| [zvec-llm-wiki-ja](skills/zvec-llm-wiki/zvec-llm-wiki-ja/) | LLM 向け wiki（`docs/wiki/`）を同期し、検索レイヤーに [zvec-grep](https://github.com/zvec-ai/zvec-grep) を使う | [zvec-llm-wiki](skills/zvec-llm-wiki/zvec-llm-wiki/) |

## スキルの使い方

スキルのフォルダを開き、**そのスキルの** README に従ってください。最初の一歩はだいたい `install/install.sh` で、そのあとエージェントを再起動します。カタログを pull したあとの `--force` 再実行は、各スキルの README の指示に従います。

インストールはスキルファイルをエージェント用ディレクトリへコピーします（このカタログ README はコピーしません）。ブートストラップや追加ツール、プロジェクトへの配線など、スキル固有の手順はそのスキル側にあります。

## 言語ポリシー

デフォルトは英語（エージェントのトークン負荷を抑えるため）。日本語はオプトイン。

| | 英語 | 日本語 |
|---|------|--------|
| **スキル** | `skills/<skill-name>/<skill-name>/` — フォルダ名は `SKILL.md` の `name` と一致 | `skills/<skill-name>/<skill-name>-ja/` — 別の `name`（接尾辞 `-ja`） |
| **このトップページ** | [`README.md`](README.md)（GitHub の既定表示） | [`README.ja.md`](README.ja.md) |

- **独立性:** 各スキル・各ロケールのフォルダは単体で完結する。そのフォルダだけ取り出せばインストールと実行ができる。同じスキルのロケール同士は 1 対 1。シンボリックリンクや実行時の他ロケール参照はしない。挙動とフラグは揃え、自然言語と `name` だけ変える。
- **メンテナンス:** スキルの挙動を変えるときは、そのスキルの全ロケールを同じ変更で直す。カタログのトップ説明を変えるときは `README.md` と `README.ja.md` を同時に直す（同じ見出し、同じ事実）。インストールはロケールを 1 つ選ぶ。

## 関連

- [Agent Skills 仕様](https://agentskills.io/specification)

# Agent Tools

[English](README.md) · [日本語](README.ja.md)

Codex、Claude Code、Cursor、OpenCode 向けのスキルと、Wiki の検索・メンテナンス用プラグインをまとめたカタログです。

## スキル

| スキル | できること | English |
|--------|------------|---------|
| [zvec-llm-wiki-ja](skills/zvec-llm-wiki/zvec-llm-wiki-ja/) | ソース・設計知識・プロジェクト文脈を生きた [OKF](https://github.com/open-knowledge-format/open-knowledge-format) の wiki に編纂し、段階的検索に [zvec-grep](https://github.com/zvec-ai/zvec-grep) を使う | [zvec-llm-wiki](skills/zvec-llm-wiki/zvec-llm-wiki/) |
| [zvec-llm-wiki-okf-migrate-ja](skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate-ja/) | OKF 以前の zvec-llm-wiki の wiki を OKF v0.3 へ一度だけ移行し、最後に人がレビューする | [zvec-llm-wiki-okf-migrate](skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate/) |

## スキルの使い方

スキルのフォルダを開き、各 README の導入手順に従ってください。既定のインストール先は対象リポジトリの `.agents/skills/` です。ユーザー全体に入れる場合は `install.sh --user` を使います。

## プラグイン

`zvec-llm-wiki` は Wiki スキルと OKF の補助スキル、zvec-grep MCP をまとめたプラグインです。Codex、Claude Code、Cursor 向けのローカル導入を準備しています。[ビルドと導入テストの手順](plugins/README.ja.md)を参照してください。

## MCP

プラグインは [zvec-grep](https://github.com/zvec-ai/zvec-grep) のローカル stdio MCP を使います。MCP を単体で使う場合は [zvec-grep の公式手順](https://zvec.org/en/docs/zvec-grep/agents/)を参照してください。

## 言語ポリシー

デフォルトは英語（エージェントのトークン負荷を抑えるため）。日本語はオプトイン。

| | 英語 | 日本語 |
|---|------|--------|
| **スキル** | `skills/<skill-name>/<skill-name>/` — フォルダ名は `SKILL.md` の `name` と一致 | `skills/<skill-name>/<skill-name>-ja/` — 別の `name`（接尾辞 `-ja`） |
| **このトップページ** | [`README.md`](README.md)（GitHub の既定表示） | [`README.ja.md`](README.ja.md) |

- **独立性:** 各スキル・各ロケールのフォルダは単体で完結する。そのフォルダだけ取り出せばインストールと実行ができる。同じスキルのロケール同士は 1 対 1。シンボリックリンクや実行時の他ロケール参照はしない。挙動とフラグは揃え、自然言語と `name` だけ変える。
- **メンテナンス:** スキルの挙動を変えるときは、そのスキルの全ロケールを同じ変更で直す。カタログのトップ説明を変えるときは `README.md` と `README.ja.md` を同時に直す（同じ見出し、同じ事実）。インストールはロケールを 1 つ選ぶ。

## ライセンス

自作のスキルとプラグインは [MIT](LICENSE) です。同梱する第三者のファイルには、それぞれのライセンスが適用されます。

## 関連

- [Agent Skills 仕様](https://agentskills.io/specification)

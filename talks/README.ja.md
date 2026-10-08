# talks（dek）

このカタログのプレゼン用 [dek](https://github.com/hajimism/dek) プロジェクト（`@hajimism/dek@0.3.1`、Bun 1.4+、`dekc`）。

| デッキ | ロケール |
|--------|----------|
| [decks/zvec-llm-wiki/](decks/zvec-llm-wiki/) | 英語 |
| [decks/zvec-llm-wiki-ja/](decks/zvec-llm-wiki-ja/) | 日本語 |

スライド構成とビート id は 1 対 1。デッキフォルダはそれぞれ完結（ロケール間でテーマを共有しない）。トークが述べるカタログの事実が変わったときは、スキル全ロケールと README 対と同じ変更で **両方** のデッキを直し、`talks/` で `bunx dekc lint` を実行する（スライドを触ったら `--visual` も）。

## セットアップ

```bash
cd talks
bun install
bunx playwright install chromium   # 初回のみ（lint --visual 用）
```

## 日常

```bash
cd talks
bunx dekc lint --visual    # 全デッキ
bunx dekc build            # デッキごとに dist/*.html

cd decks/zvec-llm-wiki-ja   # または zvec-llm-wiki
bunx dekc                  # 1 デッキの開発サーバ
```

各デッキの `script.md` が親。保存で sync と lint が走る。

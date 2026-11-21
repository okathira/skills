# zvec-llm-wiki プラグイン

[English](README.md) · [Agent Tools](../README.ja.md)

Python 3.9 以上でローカル導入テスト用の配布物をビルドします。単体インストーラーと同じ固定リビジョンから OKF のスキルを2つ取得します。英語版と日本語版が生成されるので、1プロファイルにどちらか一方を入れてください。

```sh
python plugins/build.py
```

出力先は `dist/agent-tools/` です。別の出力を作る場合は `--output` で新しいパスを指定します。更新テスト用には `--version` で新しい版を指定できます。生成先には両クライアント用のマーケットプレイス定義と、単体で導入できるプラグインが入ります。Git 経由で配布するには、マーケットプレイス定義がルートにあるこの生成ツリーを Git の ref として公開します。

## ローカル導入テスト

クリーンなプロファイルと別のテスト用リポジトリを使い、クライアントのバージョンと OS を記録します。Node.js 22 以上、npm/npx、Bash、PyYAML 入りの Python 3.9 以上を用意します。Windows では Git Bash から Bash スクリプトを実行してください。以下の `<marketplace-root>` は生成先の絶対パスです。

| クライアント | テストする導入方法 |
| --- | --- |
| Codex | `codex plugin marketplace add <marketplace-root>` を実行します。ChatGPT デスクトップアプリで Plugins の **Agent Tools** を開き、`zvec-llm-wiki` または `zvec-llm-wiki-ja` を導入します。 |
| Claude Code | `/plugin marketplace add <marketplace-root>` と `/plugin install zvec-llm-wiki-ja@agent-tools` を実行します。英語版は `zvec-llm-wiki@agent-tools` です。 |
| Cursor | 生成先の `plugins/<plugin-name>/` を `~/.cursor/plugins/local/` にコピーします。ウィンドウを再読み込みし、Customize で確認します。 |

対象はローカル導入です。公式ディレクトリへの申請と OpenAI のウェブ環境での実行は別工程です。

プラグインの zvec-grep は 0.3.1 に固定しています。旧バージョンの zvec-grep デーモンが動いていない環境でテストしてください。同時に動かす場合は別の OS 環境を使います。クライアントのプロファイルを分けてもデーモンは共有されます。

## 対象リポジトリの準備

対象リポジトリのルートで、同梱の bootstrap を明示的に実行します。`--skip-mcp` を指定すると、MCP 接続をプラグイン側に任せたまま Wiki とインデックスを準備できます。

```sh
bash /path/to/plugin/skills/zvec-llm-wiki-ja/scripts/zg-bootstrap.sh --skip-mcp
```

英語版の場合はパスの `zvec-llm-wiki-ja` を `zvec-llm-wiki` に置き換えます。初回テストは CPU で動く多言語の既定モデル `local/potion-multilingual-128m` を使います。新しいインデックスでは `--embedding local/embeddinggemma-300m` または `--embedding local/qwen3-embedding-0.6b` も選べます。対応する CUDA または Metal ランタイムがあれば GPU で実行できます。既存インデックスのモデル変更には明示的な再構築が必要です。

## 合格条件

1. 生成した配布物を導入し、Wiki スキル1つ、OKF スキル2つ、zvec-grep MCP 接続1つを確認します。導入先の `llm_wiki.py lint --strict` を実行し、同梱の validator を使って対象 Wiki を検査できることを確かめます。
2. 内容が異なる2つのテスト用リポジトリをインデックス化します。`zvec_grep_search` の `root` に各リポジトリの絶対パス、`globs` に `["docs/wiki/**"]` を指定し、指定先の結果が返ることを確認します。
3. 単体インストール済みの環境と、プロジェクト MCP 設定済みの環境でも確認します。テスト用プロファイルで切り替える際は、重複するスキルと `zvec_grep` 接続を無効化します。どのコピーが読み込まれるかを調べ、各コンポーネントの有効なコピーが1つであることを確認します。
4. 新しいテスト用バージョンに更新し、重複せずに新しい版が読み込まれることを確認します。取り外した後も対象リポジトリとローカルインデックスが残ることを確認し、切り替え時に無効化した項目を戻します。
5. 対応を明記する前に、英日両版をテストし、既存の単体導入とドッグフーディングの回帰も確認します。

[Codex のパッケージ仕様](https://developers.openai.com/plugins/build/plugins) · [Claude Code の配布仕様](https://code.claude.com/docs/en/plugin-marketplaces) · [Cursor のプラグイン仕様](https://cursor.com/docs/plugins) · [zvec-grep MCP の入力](https://github.com/zvec-ai/zvec-grep/blob/main/docs/03-mcp.md) · [埋め込みモデルのデバイス対応](https://zvec.org/en/docs/zvec-grep/embedding-models/)

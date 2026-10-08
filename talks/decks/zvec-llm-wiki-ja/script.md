---
# yaml-language-server: $schema=../../.dek/schema.json
title: "Agent Skills カタログと zvec-llm-wiki"
description: 独立した Agent Skill のカタログと、docs/wiki を zg で回す zvec-llm-wiki の紹介。
event: 社内共有
date: 2026-10-08
duration: 8m
---

## Agent Skills カタログと zvec-llm-wiki {#cover}

こんにちは。今日は、このリポジトリにある Agent Skill と、
その中核の zvec-llm-wiki を紹介します。

この資料は発表のスライドであり、そのまま読める配布資料でもあります。
八分で、三つを話します。カタログとは何か。スキルが何をするか。
そして、入れ方と運用のループです。

> 質問は最後にまとめてください。

## このリポジトリは、独立した Agent Skill を集めるカタログです {#catalog}

まず場所の整理からです。ここはスライドの道具ではなく、
エージェントに入れるスキルを置く場所です。

### カタログの役割 {#catalog-role}

Cursor や Codex などのターミナルエージェント向けに、
独立した Agent Skill を集めたカタログです。

### 独立パッケージ {#catalog-package}

スキルごとにフォルダが分かれていて、
その中だけ取り出せばインストールと実行が完結します。

## メインのスキルは、生きた wiki を zg で回す zvec-llm-wiki です {#skills}

現時点でメインのスキルは zvec-llm-wiki です。

### 英語と日本語 {#skills-locales}

英語版は `zvec-llm-wiki`、日本語版は `zvec-llm-wiki-ja` という別の名前で、
同じ挙動を別ロケールとして配布しています。

### 何ができるか {#skills-what}

ソースや設計判断、プロジェクトの文脈を `docs/wiki/` の生きた wiki に編纂し、
検索は zvec-grep の `zg` に一本化します。

## 知識は Query から index まで、同じループで積み上がる {#loop}

スキルの中心は、このループです。

### Query {#loop-query}

まず `docs/wiki/index.md` を読み、足りなければ wiki 向けの hybrid 検索、
名前が決まっていれば rg で exact に当てます。

### Work {#loop-work}

調べたうえで実装や調査を進めます。

### Ingest と記録 {#loop-ingest}

wiki への書き込みは involved です。
ページ案を示してから編集し、大きな変更は log に残します。

### Lint と index {#loop-lint}

lint のあと、wiki を編集したら差分の `zg index` で索引を更新します。

## 情報は raw、wiki、ホットメモリ、README の四層に分かれる {#layers}

情報は層に分かれています。混同すると、どこを直すべきかわからなくなります。

### Raw {#layers-raw}

実行可能なコードとパッケージファイルは raw です。
wiki はリンクするだけで、全部を prose に焼き込みません。

### Wiki {#layers-wiki}

`docs/wiki/` が、人とエージェントが共有するコンパイル済み知識の本体です。

### ホットメモリ {#layers-agents}

`AGENTS.md` のマーク付きブロックと、インストール済みスキルが、
毎ターンの入口になります。

### 人向け README {#layers-readme}

ルートの README はインストーラー UI で、
スキル本体のコピーには含まれません。

## 導入は、スキルの install とプロジェクトの bootstrap の二段階です {#two-steps}

ここを混同しないのが大事です。マシンに入れる話と、
プロジェクトに wiki を配線する話は別です。

### スキルのインストール {#two-install}

`install/install.sh` は、スキルファイルをエージェント用ディレクトリにコピーします。
マシンかリポジトリごとに一度です。

### プロジェクトのブートストラップ {#two-bootstrap}

`scripts/zg-bootstrap.sh` は、対象リポジトリに wiki や zg の配線を入れます。
プロジェクトごとに一度です。

## スキルはユーザ全体、プロジェクト、Claude の三通りで入れられる {#install}

代表的なパスは三つです。

### ユーザ全体 {#install-user}

`install.sh` の既定は `~/.agents/skills/` 向けです。
入れたらエージェントを再起動します。

### プロジェクトスコープ {#install-project}

チームリポジトリや Cloud Agents 向けに `--project` を付ければ
`.agents/skills/` に入ります。

### Claude と更新 {#install-claude}

Claude Code 向けは `--claude` です。
カタログを pull したあとは README の指示に従い `--force` で上書きします。

## bootstrap は、対象リポジトリに wiki と zg を配線する {#bootstrap}

対象は「このカタログ」ではなく、wiki を持たせたいあなたのプロジェクトです。

### 前提 {#bootstrap-prereq}

Node.js 22 以上が必要です。zg は npm パッケージとして入ります。

### 実行 {#bootstrap-run}

プロジェクトのルートで bootstrap を走らせます。
`docs/wiki/` が無ければ scaffold を作り、既存 wiki は壊しません。

### あとで {#bootstrap-after}

`AGENTS.md` のホットブロックを upsert し、MCP と索引を整えます。
終わったらまたエージェントを再起動します。

## 既定は英語、日本語は独立した別パッケージです {#locale}

エージェントのトークン負荷を抑えるため、既定は英語です。

### 独立フォルダ {#locale-independence}

日本語は `-ja` 付きの別フォルダで、
シンボリックリンクや実行時の相互参照はしません。

### メンテナンス {#locale-maintain}

挙動を変えるときは、同じスキルの全ロケールを同じ変更で揃えます。

## このカタログ自身が、zvec-llm-wiki の試し場です {#dogfood}

このカタログ自身が、zvec-llm-wiki のドックフーディング先です。

### wiki の中身 {#dogfood-wiki}

`docs/wiki/index.md` にレジストリがあり、
概念・ADR・runbook がリンクされています。

### あなたの次の一歩 {#dogfood-next}

スキルを入れて、自分のリポジトリで bootstrap すれば、
同じループをすぐ試せます。

## 持ち帰ってほしい、三つのこと {#summary}

最後に、三つだけ持ち帰ってください。

### カタログと独立スキル {#summary-catalog}

スキルはフォルダ単位で完結する。カタログは配る場所、README は人向けの入口。

### install と bootstrap {#summary-steps}

マシンへのコピーと、プロジェクトへの wiki 配線は別の一度きりの作業。

### wiki と zg のループ {#summary-loop}

index を先に、記録して lint し、差分で索引を更新する。

> 詳細は各スキルの README と
> `docs/wiki/runbooks/skill-setup.md` を参照してください。

---
name: ingest-youtube
description: YouTube 動画を kubutaku-memory リポジトリに取り込む。トランスクリプトを raw-sources/youtube/ に保存し、内容から主要トピックを抽出して既存 wiki ページとの関連づけや stub 化候補を提示する。「YouTube を ingest」「この動画まとめて」「URL を取り込んで」「動画の内容を保存」「YouTube から学習」など、ユーザーが YouTube URL を提示して内容を kubutaku-memory に残したい意図を示したら必ず使用する。Zettelkasten 原則のため wiki ページの自動生成はしない。
---

# ingest-youtube

YouTube 動画を Karpathy の LLM Wiki パターン（raw / wiki / schema 3層）に従って kubutaku-memory に取り込むスキル。

## 思想

- **raw-sources は不変の事実層**。トランスクリプトを丸ごと保存し、後から検証できる状態にする
- **wiki は人が自分の言葉で書く層**。skill は wiki ページを **自動生成しない**。Zettelkasten 原則「自分の言葉で書く」を守る
- skill の役割は「raw を取り込む」「トピックを抽出して学習対象を可視化する」までで止める。学習自体は kubutaku-memory の既存ワークフロー（CLAUDE.md の Step 1-3）に渡す

## 前提

- リポジトリ: `/Users/kokubutakuya/repos/kubutaku-memory`
- 依存コマンド: `yt-dlp`（未インストールなら `brew install yt-dlp` を案内して中断）
- 今日の日付は会話冒頭の `currentDate` または `date +%Y-%m-%d` で取得

## ワークフロー

### Step 1: 前提チェック

```bash
which yt-dlp
```

無ければユーザーに `brew install yt-dlp` を案内し、インストール後に再実行してもらう。先に進めない。

### Step 2: メタ情報とトランスクリプト取得

`scripts/fetch_transcript.sh <URL> <出力ディレクトリ>` を実行する。手動字幕（ja → en の優先順）を試し、無ければ自動字幕にフォールバックする。スクリプトは以下を出力ディレクトリに作る:

- `<slug>.info.json` — メタ情報（タイトル、チャンネル、投稿日、URL）
- `<slug>.<lang>.vtt` — 字幕ファイル

字幕がまったく取れなければユーザーに報告して中断（音声から書き起こすなどの選択を仰ぐ）。

### Step 3: トランスクリプトを Markdown 化して raw-sources に保存

VTT のタイムスタンプを除去しプレーンテキスト化したものを以下のフォーマットで保存:

保存先: `vault/raw-sources/youtube/<YYYY-MM-DD>-<slug>.md`
- `<YYYY-MM-DD>` は **取得日**（投稿日ではない）
- `<slug>` は動画タイトルから生成（日本語可、空白は `-`、`/` 等の禁止文字は除去、長すぎる場合は 60 文字程度で切る）

ファイル本文:

```markdown
---
type: youtube
url: <URL>
title: <タイトル>
channel: <チャンネル名>
published: <投稿日 YYYY-MM-DD>
fetched: <取得日 YYYY-MM-DD>
lang: <字幕言語 ja/en>
subtitle_kind: <manual or auto>
---

# <タイトル>

<プレーンテキストのトランスクリプト>
```

### Step 4: 内容を読みトピックを抽出

raw に保存したファイルを読み、動画が扱う **主要なトピック・概念を 3〜10 個** 抽出する。粒度は Zettelkasten の「1 ノート 1 アイデア」に揃える（例: 「dbt の使い方全般」ではなく「dbt model」「ref 関数」「Jinja マクロ」のように分解）。

### Step 5: 既存 wiki との突き合わせ

`vault/wiki/index.md` と `vault/wiki/pages/` を確認し、抽出したトピックそれぞれについて以下を判定:

- **既存ページあり**: そのページに raw-sources へのリンクを「参考資料」セクションに追記する候補とする
- **未作成（stub も無い）**: 新規学習候補として提示する

### Step 6: ユーザーに提示して判断を仰ぐ

以下のフォーマットでユーザーに報告:

```
## ingest 完了
- raw: vault/raw-sources/youtube/<file>.md
- 動画: <タイトル>（<チャンネル>）

## 抽出したトピック
| トピック | 状態 | 提案 |
|---|---|---|
| dbt model | 既存 [[dbt]] | 参考資料に追記 |
| Jinja マクロ | 未作成 | 学習候補（stub 化 or 学ぶ） |
| ref 関数 | 既存 [[dbt-ref]] | 参考資料に追記 |

どれを進めますか？
- A) 既存ページに参考資料を追記
- B) 未作成トピックを学習する（CLAUDE.md の学習ワークフロー Step 1 から）
- C) 未作成トピックを stub として index.md に登録だけしておく
- D) 何もしない（raw 保存だけで終了）
```

### Step 7: log.md に追記

`vault/wiki/log.md` の末尾に1行追記:

```
## [<取得日 YYYY-MM-DD>] ingest | YouTube: <タイトル>
```

これは Step 6 の判断に関わらず、raw 保存が成功した時点で必ず実行する。

## 既存ワークフローへの引き継ぎ

ユーザーが Step 6 の B（学習する）を選んだ場合、CLAUDE.md の学習ワークフローに従う:

1. ユーザーが知っていることを聞く
2. 対話で理解を深める
3. ユーザーに自分の言葉で統括を書いてもらう
4. その後で wiki ページを `vault/templates/learning-page.md` のテンプレートで作成

skill 側で勝手に統括を書かない。raw のトランスクリプトは「定義」セクションの参考資料として活用できる（公式ドキュメント＋動画の組み合わせ）。

## エッジケース

- **複数動画を一度に渡された**: 1 本ずつ順に処理する。並行はしない（CLAUDE.md「複数タスクを並行しない」）
- **長尺動画（2 時間超など）**: トランスクリプトをそのまま保存。要約はしない。トピック抽出時にセクション見出しを併記する
- **ライブ配信のアーカイブ**: 字幕の質が低いことが多い。状態を報告した上で進める
- **字幕が完全に無い**: ユーザーに報告し、`yt-dlp` で音声をダウンロードして Whisper 等で書き起こすか、別動画にするか聞く

## raw-sources のサブディレクトリ方針

現在は `youtube/` のみ。将来 `articles/`, `papers/` 等を追加する可能性があるが、追加が必要になった時点で別 skill（`ingest-article` など）として切り出す。YAGNI。

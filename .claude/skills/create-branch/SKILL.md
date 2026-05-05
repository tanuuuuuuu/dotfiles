---
name: create-branch
description: 既存の Issue から開発用ブランチを作成し Issue に紐付けてチェックアウト。「/create-branch」「ブランチを作成」「開発を始めたい」「Issue から作業ブランチを切りたい」で使用。
---

# create-branch

既存の Issue から開発用ブランチを作成する。`gh issue develop` を使い、Issue とブランチを GitHub 上で自動リンクする。

## ワークフロー

1. **Issue 番号確認**: ユーザーに対象 Issue 番号を確認（直前の会話で作成した Issue 番号があればそれを提示）
2. **Issue 内容取得**: `gh issue view <番号>` でタイトルと labels / type を取得
3. **ブランチ名決定**: 命名規則に沿って候補を提示し、ユーザーに確認
4. **ブランチ作成**: `gh issue develop` でリモート作成 + Issue 紐付け + ローカルチェックアウト

## 1. Issue 内容の取得

```bash
gh issue view <番号> --json number,title,labels,issueType
```

出力例:

```json
{
  "number": 123,
  "title": "ログインボタンを追加する",
  "labels": [{"name": "enhancement"}],
  "issueType": {"name": "Feature"}
}
```

## 2. ブランチ名の命名規則

`<prefix>/<issue番号>-<簡潔な説明>` の形式。

### prefix の選び方

Issue Type または labels を優先。無ければタイトル・本文から判断。

| 内容 | prefix |
|---|---|
| 機能追加、改善 | `feat` |
| バグ修正 | `fix` |
| ドキュメント更新 | `docs` |
| リファクタ | `refactor` |
| 雑務、設定変更、調査 | `chore` |
| テスト追加・修正 | `test` |

リポジトリで Issue Type が定義されていれば優先する。labels も補助情報として参照する。

### 簡潔な説明

- 英小文字 + ハイフン区切り（kebab-case）
- 4〜6 単語以内
- Issue タイトルから動詞 + 主要な目的語を抽出して英訳・短縮

例:

| Issue タイトル | ブランチ名 |
|---|---|
| 「ログインボタンを追加する」（#123, 機能追加） | `feat/123-add-login-button` |
| 「null pointer エラーを修正する」（#456, バグ） | `fix/456-fix-null-pointer` |
| 「設定値の挙動を調査する」（#789, 調査） | `chore/789-investigate-config-behavior` |
| 「README を更新する」（#234, ドキュメント） | `docs/234-update-readme` |

候補名をユーザーに提示し、確認を取ってから次へ進む。

## 3. ブランチ作成

```bash
gh issue develop <issue番号> --name <ブランチ名> --checkout
```

このコマンドで以下が一括実行される:

- リモートに新ブランチを作成
- Issue とブランチをリンク（GitHub の Issue ページに「Development」として表示される）
- ローカルでブランチをチェックアウト

## 4. 完了メッセージ

```
ブランチを作成しました: <ブランチ名>
- Issue: #<番号> <タイトル>
- リモート: origin/<ブランチ名>
- ローカル: チェックアウト済み

このブランチでコミットを開始できます。
```

## 注意

- main / master ブランチ上での作業は避けるための運用補助スキル
- 実装中に scope が変わってきたら、コミット前に `git branch -m <新名>` でローカルブランチ名を変更し、`git push origin -u <新名>` で再 push する

## 関連スキル

- まだ Issue が無い場合は先に `/create-issue` で作成する
- マージ後の片付けは `/git-cleanup`

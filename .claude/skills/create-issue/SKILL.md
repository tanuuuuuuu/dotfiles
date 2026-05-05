---
name: create-issue
description: GitHub Issue を作成。Issue Template があればそれに従い、Issue Type や Project の設定機能があれば自動連携する。「/create-issue」「イシューを作成」「Issue を立てて」「新しいタスクを作りたい」で使用。
---

# create-issue

GitHub Issue を作成する。コアは `gh issue create` 一発のシンプルな処理。リポジトリ固有の設定（Issue Template / Issue Type / Project）が存在する場合のみ追加で連携する graceful degradation 方式。

## ワークフロー

1. **情報収集**: タイトル・本文・担当者をユーザーに確認
2. **Issue 作成**: `gh issue create` で作成
3. **応用設定（任意）**: リポジトリで Issue Type や Project が使われている場合のみ追加設定

ほとんどの個人リポジトリは 1 と 2 だけで完結する。3 は機能を使っているチーム/組織リポジトリ向け。

## 1. 情報収集

ユーザーに確認する内容:

- **タイトル**: 動詞始まりで具体的に。「○○ を追加する」「○○ のバグを修正する」「○○ を調査する」
- **本文**: 下記の判断フローで生成し、ユーザーに draft を見せて確認
- **担当者**: デフォルト `@me`（自分）。変更する場合のみコラボレーターから選択

### 本文の生成

```bash
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
```

- **テンプレートあり**（`.yml` / `.yaml` / `.md`）: そのセクション構造に沿って本文を生成
- **テンプレートなし**: 簡素な構造で生成。デフォルトは「**やりたいこと / 背景・理由 / 完了条件**」だが、内容に応じて柔軟に省略・追加してよい。短いタスクなら 1〜2 行のフリーテキストでも可

### 担当者を変更する場合

```bash
gh api repos/:owner/:repo/collaborators --jq '.[].login'
```

## 2. Issue 作成

最小コマンド:

```bash
gh issue create --title "タイトル" --body "本文" --assignee "@me"
```

Project にも追加したい場合は、後述の §応用設定 を先に確認してから `--project` を付与する。

```
Issue を作成しました: <Issue URL>
```

ここで終わってよい。応用設定は必要なら続ける。

---

## 応用設定（リポジトリで使っている場合のみ）

Issue Type と Project は **GitHub の組織・有料プラン中心の機能**であることが多く、個人 free アカウントの単独リポジトリではほとんど使われない。下記は使っているリポジトリ向けの追加処理。

### A. Issue Type の自動設定

Issue Type が定義されているか先に確認:

```bash
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issueTypes(first: 20) {
      nodes { id name description }
    }
  }
}'
```

`nodes` が空なら **このセクションをスキップ**。定義されている場合のみ続ける。

判定: 各 Type の `description` を基準にイシューの内容に最も合う Type を選ぶ。一般的な対応:

- Feature / Enhancement → 機能追加
- Bug / Fix → バグ修正
- Task / Chore → 雑務、設定
- Documentation → ドキュメント

設定:

```bash
# Issue の Node ID を取得
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: ISSUE_NUMBER) { id }
  }
}'

# Type を割り当て
gh api graphql -f query='mutation {
  updateIssue(input: {
    id: "ISSUE_NODE_ID",
    issueTypeId: "ISSUE_TYPE_ID"
  }) {
    issue { number issueType { name } }
  }
}'
```

### B. Project への追加とステータス設定

トークンに `project` スコープが必要:

```bash
gh auth status 2>&1 | grep -q "'project'" && echo "HAS" || echo "NO"
```

- `NO`: スキップ。`gh auth refresh -s project` でスコープ追加可能と案内
- `HAS`: 続ける

リポジトリにリンクされた Project を確認:

```bash
gh project list --owner OWNER 2>&1 | head -20
```

Issue 作成時から Project に追加する場合は、最初の `gh issue create` に `--project "PROJECT_NAME"` を加える。

作成後にステータスを設定する場合（Todo / In Progress など）:

```bash
# Project Item ID と Project ID を取得
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: ISSUE_NUMBER) {
      projectItems(first: 5) {
        nodes { id project { id } }
      }
    }
  }
}'

# Status フィールドの ID と Option ID を取得
gh api graphql -f query='{
  node(id: "PROJECT_ID") {
    ... on ProjectV2 {
      field(name: "Status") {
        ... on ProjectV2SingleSelectField {
          id
          options { id name }
        }
      }
    }
  }
}'

# ステータスを設定
gh api graphql -f query='mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PROJECT_ID",
    itemId: "PROJECT_ITEM_ID",
    fieldId: "STATUS_FIELD_ID",
    value: { singleSelectOptionId: "OPTION_ID" }
  }) {
    projectV2Item { id }
  }
}'
```

---

## 完了メッセージ

実行できた項目だけ表示:

```
Issue を作成しました: <Issue URL>
- Type: <Type名>           （設定された場合のみ）
- Project: <ステータス>    （設定された場合のみ）
```

## 関連スキル

- 作成した Issue から開発ブランチを切るには `/create-branch`

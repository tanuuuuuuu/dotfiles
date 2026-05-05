---
name: create-issue
description: GitHub Issue を作成。担当者を設定し、Issue Type と Project を可能なら自動設定。「/create-issue」「イシューを作成」「Issue を立てて」「新しいタスクを作りたい」で使用。
---

# create-issue

GitHub Issue を作成する。リポジトリの設定（Issue Template / Issue Type / Project）に応じて段階的に対応し、無ければスキップする graceful degradation 方式。

## ワークフロー

1. **リポジトリ確認**: `gh repo view --json nameWithOwner,defaultBranchRef` で現在のリポジトリを確認
2. **スコープ確認**: `gh auth status` で `project` スコープの有無を確認
3. **Issue Template 確認**: `.github/ISSUE_TEMPLATE/` の存在をチェック、あればその構造に沿う
4. **情報収集**: タイトル、本文、担当者をユーザーに確認
5. **Issue 作成**: `gh issue create` で Issue を作成
6. **Issue Type 自動設定**（リポジトリで Issue Type が定義されていれば）: 内容から判定し GraphQL で設定
7. **Project ステータス設定**（project スコープがあれば）: ユーザーに Todo / In Progress を選ばせて設定
8. **完了メッセージ**: Issue URL と設定内容を表示

## 1. リポジトリとスコープの確認

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
gh auth status 2>&1 | grep -q "'project'" && echo "HAS_PROJECT_SCOPE" || echo "NO_PROJECT_SCOPE"
```

- `HAS_PROJECT_SCOPE`: `--project` オプションを使用可能
- `NO_PROJECT_SCOPE`: `--project` を使うと認証エラーになるため省略する

## 2. Issue Template の確認

```bash
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
```

- `.yml` / `.yaml` / `.md` テンプレートがあれば、その構造に沿って本文を生成する
- 無ければ標準的な構造で本文を生成: **背景 / やること / 完了条件**

## 3. 情報収集

ユーザーに以下を確認:

- **タイトル**: 動詞始まりで具体的に。例: 「○○ を追加する」「○○ のバグを修正する」「○○ を調査する」
- **本文**: 既存テンプレートに沿うか、無ければ「背景 / やること / 完了条件」セクションで生成。ユーザーに draft を見せて確認を取る
- **担当者**: デフォルトは `@me`。変更する場合のみコラボレーター一覧を提示

担当者を変える場合のコラボレーター取得:

```bash
gh api repos/:owner/:repo/collaborators --jq '.[].login'
```

## 4. Issue 作成

### project スコープがあり、リポジトリに Project がリンクされている場合

リポジトリにリンクされた Project 名を確認:

```bash
gh project list --owner OWNER 2>&1 | head -20
```

ユーザーに対象 Project 名を確認した上で:

```bash
gh issue create \
  --title "タイトル" \
  --body "本文" \
  --assignee "@me" \
  --project "PROJECT_NAME"
```

### project スコープがない / Project を使わない場合

```bash
gh issue create \
  --title "タイトル" \
  --body "本文" \
  --assignee "@me"
```

## 5. Issue Type 自動設定（オプショナル）

リポジトリで Issue Type が定義されている場合のみ実行する。定義されていなければ静かにスキップ。

### 5.1. Issue Type 一覧の取得

```bash
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issueTypes(first: 20) {
      nodes { id name description }
    }
  }
}'
```

返ってきた `nodes` が空の場合はこの章をスキップ。

### 5.2. Type の判定

各 Type の `description` を判定基準とし、Issue のタイトル・本文の内容に最も合う Type を選ぶ。一般的には:

- **Feature / Enhancement**: 機能追加、改善
- **Bug / Fix**: バグ修正
- **Task / Chore**: 雑務、設定変更、リファクタ
- **Research / Investigation**: 調査、検証
- **Documentation**: ドキュメント

### 5.3. Issue の Node ID 取得 + Type 設定

```bash
# Issue の Node ID
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: ISSUE_NUMBER) { id }
  }
}'

# Type 設定
gh api graphql -f query='mutation {
  updateIssue(input: {
    id: "ISSUE_NODE_ID",
    issueTypeId: "ISSUE_TYPE_ID"
  }) {
    issue { number issueType { name } }
  }
}'
```

## 6. Project ステータス設定（オプショナル）

project スコープがあり、Issue が Project に追加されている場合のみ実行する。

### 6.1. ステータス選択

ユーザーに選ばせる:

- **Todo**: とりあえず立てておき後で着手
- **In Progress**: これから取り掛かる

### 6.2. Project Item ID と Project ID 取得

```bash
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: ISSUE_NUMBER) {
      projectItems(first: 5) {
        nodes {
          id
          project { id }
        }
      }
    }
  }
}'
```

### 6.3. Status フィールド ID と Option ID 取得

```bash
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
```

### 6.4. ステータス設定

```bash
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

## 7. 完了メッセージ

実行できた項目だけ表示する。

```
Issue を作成しました: <Issue URL>
- Type: <自動判定した Type>（設定された場合のみ）
- Project ステータス: <選択したステータス>（設定された場合のみ）
```

スコープ不足等でスキップした項目があれば一行で補足:

```
⚠️ project スコープが無いため Project への追加はスキップしました。
   `gh auth refresh -s project` でスコープを追加できます。
```

## 関連スキル

- 作成した Issue から開発ブランチを切るには `/create-branch`

---
name: worktree
description: git worktree を使って Claude Code を別ブランチで並行起動できるようにするスキル。「並行作業したい」「別ブランチで作業」「PR レビュー中に別の修正」「Claude Code をもう一つ立ち上げたい」「worktree」などの文脈で積極的に使用する。「/worktree」で明示的に呼び出すこともできる。同時に複数ブランチを触りたいケースには必ず検討する。
---

# worktree

git worktree を使って **同じリポジトリの別ブランチを別フォルダで開く**。これにより Cursor のもう 1 ウィンドウで Claude Code をもう 1 セッション立ち上げ、現在の作業に干渉せず並行で進められる。これがこのスキルの主目的。

## このスキルの中心的な価値

worktree を作るだけなら git の素のコマンドで済む。このスキルが提供するのは:

1. **新ウィンドウで Claude Code を並行起動する流れ**を必ず案内する
2. **命名規約**（`../<repo>-<branch>`、`/` は `-` に置換）で配置を統一する
3. **削除時にマージ状態を判定**し、未マージは保護する
4. **macOS 環境ルール**（`trash` コマンド使用）を守る

## ワークフロー

ユーザーの意図から「作る」「見る」「消す」「再開する」のいずれかを判別して進む。判別が付かないなら `git worktree list` で現状を共有してから聞く。

### A. 作る（並行作業を始める）

新ウィンドウで Claude Code を立ち上げるところまでが 1 セット。コマンド提示で終わらせない。

#### A-1. 既存ブランチで作る

```bash
git worktree add ../<repo>-<branch> <branch>
```

#### A-2. 新規ブランチで作る

```bash
git worktree add -b <new-branch> ../<repo>-<new-branch> <base-branch>
```

`<base-branch>` は `main` か `origin/main`。リモート最新から切るなら `git fetch` を先に促す。

#### 作成後の必須案内

絶対パスで以下を提示し、「新しい Cursor ウィンドウが開くので、そこで `claude` を起動してください」と添える。これがスキルの目玉。

```bash
cursor <作成した worktree の絶対パス>
```

### B. 見る（一覧と整理判断）

```bash
git worktree list
```

そのまま見せたあと、判断材料を添える:

- 各ブランチの **マージ状態**: `git branch --merged main` / `git branch --no-merged main`
- 必要なら最新コミット: `git -C <path> log -1 --oneline`
- prunable があるか

ユーザーが「整理したい」と言っていても、勝手に消さない。候補と判定を出して確認を取る。

### C. 再開する（既存 worktree で作業を続ける）

```bash
cursor <worktreeの絶対パス>
```

絶対パスは `git worktree list` の出力から取る。

### D. 消す（マージ済みクリーンアップ）

未マージの worktree を消すと作業が消える。**必ずマージ状態を判定してから動く**。

1. `git branch --merged main` でマージ済みリストを取る
2. マージ済みのものだけ削除:
   ```bash
   git worktree remove <path>
   ```
3. ディレクトリが残ったら `trash <path>` で送る（macOS。`rm -rf` は使わない）
4. 未マージのものは削除せず、対象として残った理由を明示

`--merged` は squash / rebase merge を拾えないことがある。判定が付かないなら `gh pr list --state merged --head <branch>` で補助確認するか、ユーザーに「未確認だが消していいか」を聞く。

### E. 後片付け

worktree のディレクトリを手動で消した・別マシンに移したなどで参照だけ残っている場合:

```bash
git worktree prune
```

`git worktree list` に `prunable` の表示があるときに使う。

## 命名規約

worktree は **リポジトリの 1 つ上に `<repo>-<branch>` 形式** で作る。

- `~/work/myproject/` → `~/work/myproject-feature-a/`
- ブランチ名の `/` は `-` に置換: `feature/login` → `myproject-feature-login`

理由: 元リポジトリと並んで一覧でき、Cursor / VS Code のワークスペース管理上も独立して扱える。リポジトリ内に置くと git 自身が混乱しやすい。

## 注意

- リポジトリ外で呼ばれたら、まず `git rev-parse --show-toplevel` で確認し、対象リポジトリを明らかにする
- 同じブランチを 2 つの worktree で同時にチェックアウトすることはできない（git が拒否）。並行で別作業したい場合は別ブランチを切る
- ユーザーが dbt / データ基盤系のキーワード（dbt, profiles.yml, .env, BigQuery）を使っている場合のみ、`target/`・`dbt_packages/`・`.env`・`profiles.yml` などが worktree 間で共有されない点を補足する。それ以外の文脈では触れない

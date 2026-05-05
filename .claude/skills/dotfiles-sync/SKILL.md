---
name: dotfiles-sync
description: PC 設定変更後に ~/dotfiles リポジトリへの反映を提案・実行する。設定ファイルの追加・変更、セットアップスクリプトの更新、README の更新を一括で行う。「/dotfiles-sync」「dotfiles に反映」「設定を保存」「dotfiles を更新」で使用。また、brew install / uv tool install / システム設定変更など PC 環境を変更する作業を行った直後に、能動的にこのスキルを発動して dotfiles への反映を提案する。
---

# dotfiles-sync

PC 設定の変更を `~/dotfiles` リポジトリに反映し、別の PC でも同じ環境を再現可能にする。

## ワークフロー

### 1. 変更内容の特定

直前の会話や作業履歴から、何が変更されたかを特定する。典型的な変更パターン:

- **パッケージ追加**: `brew install xxx` → Brewfile に追記
- **Python ツール追加**: `uv tool install xxx` → `.config/uv/uv-tools.txt` に追記
- **設定ファイル変更**: Ghostty / Zellij / Starship 等の設定変更 → 該当ファイルを更新
- **新しい設定ファイル追加**: → dotfiles に配置 + `setup.sh` に symlink 追加
- **macOS システム設定**: defaults コマンド → `macos.sh` に追記
- **Windows システム設定**: PowerShell 設定 → `windows.sh` に追記
- **シェル設定**: alias / function / 環境変数 → `.zshrc` or `.zprofile` に追記

### 2. ユーザーに確認

AskUserQuestion で以下を確認:
- dotfiles に反映するかどうか
- 複数の変更がある場合、どれを反映するか

### 3. dotfiles を更新

変更の種類に応じて適切なファイルを更新する。詳細は [references/dotfiles-structure.md](references/dotfiles-structure.md) を参照。

更新対象の判断基準:
- **設定ファイル自体**: 変更があれば dotfiles 内の該当ファイルを更新
- **setup.sh**: 新しい設定ファイルを追加した場合、symlink 作成処理を追加
- **Brewfile**: `brew install` 時。通常パッケージは `brew "名前"`、cask は `cask "名前"`、tap が必要なら `tap "タップ名"` も追加
- **README.md**: 新ツール追加（技術スタック表）、新設定ファイル追加（ディレクトリ構成ツリー）、macos.sh / windows.sh の内容変更（内容一覧）の場合に更新

### 4. 変更の報告

更新したファイル一覧と変更内容のサマリを報告する。

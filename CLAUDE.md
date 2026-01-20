# dotfiles

macOS 用の個人設定ファイル管理リポジトリ。

## 技術スタック

- OS: macOS
- シェル: zsh
- パッケージ管理: Homebrew
- ランタイム管理: mise
- Python パッケージ管理: uv
- ターミナルマルチプレクサ: Zellij
- ターミナルエミュレータ: Ghostty
- コーディングエージェント: Claude Code

## 構造

- `.zshrc` - シェル設定
- `Brewfile` - Homebrew パッケージ一覧
- `.config/` - 各種ツールの設定
- `.claude/` - Claude Code の設定
- `setup.sh` - 初期セットアップスクリプト

## 作業ルール

- シンボリックリンクで管理されるファイルは直接編集しない
- ディレクトリ構造を変更した場合は CLAUDE.md と README.md の整合性を確認・更新する
- `.config/` および `.claude/` 以下はミラーリング方式（実際の配置場所と同じ構造）で管理する

## コミット前チェック

1. `./setup.sh` を実行して動作確認する
2. 機密情報（APIキー、トークン等）が含まれていないか確認する

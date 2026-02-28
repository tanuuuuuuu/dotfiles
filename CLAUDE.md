# dotfiles

macOS 用の個人設定ファイル管理リポジトリ。

## 技術スタック

- OS: macOS
- シェル: zsh
- パッケージ管理: Homebrew
- ランタイム管理: mise
- Python パッケージ管理: uv
- エディタ: Neovim
- プロンプト: Starship
- ターミナルマルチプレクサ: Zellij
- ターミナルエミュレータ: Ghostty
- ランチャー: Raycast
- コーディングエージェント: Claude Code

## 作業ルール

- ローカルリポジトリは `~/repos/` で管理（dotfiles のみ `~/dotfiles/`）
- シンボリックリンクで管理されるファイルは、リンク先（`~/.config/` 等）ではなく dotfiles リポジトリ内を編集する
- `.config/` および `.claude/` 以下はミラーリング方式（実際の配置場所と同じ構造）で管理する
- ディレクトリ構造を変更した場合は CLAUDE.md と README.md の整合性を確認・更新する
- コミット前に機密情報（APIキー、トークン等）が含まれていないか確認する

## 設定ファイルの追加・変更

新しいツールの設定を dotfiles 管理に含める場合:

1. dotfiles 内の適切な場所にファイルを作成（`.config/<ツール名>/` or `.claude/`）
2. `setup.sh` にシンボリックリンク作成コマンドを追加
3. パッケージが必要なら `Brewfile` にも追加

`.claude/` は `setup.sh` で個別ファイル/ディレクトリ単位でリンクしている（ディレクトリ丸ごとではない）。新しいファイルを管理に含める場合は `setup.sh` にリンクを追加する。

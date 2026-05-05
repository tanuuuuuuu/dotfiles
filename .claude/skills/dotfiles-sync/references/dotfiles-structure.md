# dotfiles リポジトリ構成

リポジトリ: `~/dotfiles`

## ファイルと役割

| ファイル | 役割 | 更新タイミング |
|----------|------|----------------|
| `setup.sh` | セットアップスクリプト（Homebrew, mise, uv, symlink 等） | ツールの追加・設定ファイルの追加 |
| `macos.sh` | macOS 固有設定（defaults コマンド） | macOS システム設定の変更 |
| `windows.sh` | Windows 固有設定（PowerShell 経由） | Windows システム設定の変更（WSL から実行） |
| `Brewfile` | Homebrew パッケージ一覧 | brew install 実行時 |
| `.zshrc` | シェル設定 | alias / function / plugin の追加 |
| `.zprofile` | ログインシェル設定 | 環境変数の追加 |
| `.gitconfig` | Git 設定 | Git 設定の変更 |
| `.config/uv/uv-tools.txt` | uv グローバルツール一覧 | uv tool install 実行時 |
| `.config/mise/config.toml` | ランタイムバージョン管理 | Python 等のバージョン変更 |
| `.config/ghostty/config` | ターミナル設定 | Ghostty 設定の変更 |
| `.config/zellij/config.kdl` | ターミナルマルチプレクサ設定 | Zellij 設定の変更 |
| `.config/zellij/layouts/default.kdl` | Zellij レイアウト | レイアウトの変更 |
| `.config/starship.toml` | プロンプト設定 | プロンプトの変更 |
| `.config/nvim/` | Neovim 設定 | エディタ設定の変更 |
| `.config/git/ignore` | グローバル gitignore | 除外パターンの追加 |
| `.claude/CLAUDE.md` | Claude Code カスタム指示 | Claude の振る舞い変更 |
| `.claude/settings.json` | Claude Code 設定 | Claude Code 設定の変更 |
| `.claude/skills/` | Claude Code カスタムスキル | スキルの追加・更新 |
| `README.md` | リポジトリ説明 | 上記いずれかの変更で構成が変わった場合 |

## setup.sh のシンボリックリンク管理

新しい設定ファイルを追加する場合、`setup.sh` に symlink の作成処理も追加する:

```bash
# ファイル単位
mkdir -p ~/.config/xxx
ln -sf "$DOTFILES_DIR/.config/xxx/config" ~/.config/xxx/config

# ディレクトリ単位
if [ -d ~/.config/xxx ] && [ ! -L ~/.config/xxx ]; then
    rm -rf ~/.config/xxx
fi
ln -sfn "$DOTFILES_DIR/.config/xxx" ~/.config/xxx
```

## README.md の更新が必要なケース

- 新しいツール/カテゴリの追加（技術スタック表）
- 新しい設定ファイルの追加（ディレクトリ構成ツリー）
- セットアップ手順の変更
- macos.sh / windows.sh への設定追加（内容一覧）

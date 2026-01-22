# dotfiles

個人用の設定ファイル管理リポジトリ。

## 前提

- OS: macOS（Intel / Apple Silicon どちらも対応）
- シェル: zsh

## ディレクトリ構造

```
.
├── .zshrc                   # シェル設定
├── Brewfile                 # Homebrewパッケージ
├── setup.sh                 # セットアップスクリプト
│
├── .config/
│   ├── ghostty/config       # Ghostty設定
│   ├── mise/config.toml     # mise（グローバルPython）
│   ├── nvim/                # Neovim設定
│   ├── raycast/
│   │   └── script-commands/ # Raycastスクリプトコマンド
│   ├── starship.toml        # Starshipプロンプト設定
│   ├── uv/
│   │   ├── uv.toml          # uv設定
│   │   └── uv-tools.txt     # uvでインストールするCLIツール
│   └── zellij/
│       ├── config.kdl       # Zellij設定
│       └── layouts/         # Zellijレイアウト
│
└── .claude/                 # Claude Code設定（ユーザーレベル）
    ├── CLAUDE.md            # カスタム指示
    ├── settings.json        # 設定
    ├── skills/
    │   ├── claude-md/       # CLAUDE.md作成・改善スキル
    │   └── skill-creator/   # スキル作成ガイド（Anthropic公式）
    ├── sounds/              # 通知音
    └── statusline.sh        # ステータスライン
```

`.claude/` は `~/.claude/` にリンクされるユーザーレベル設定。このため dotfiles プロジェクト固有の Claude Code 設定は作成できない（必要になった場合は構造の見直しが必要）。

## セットアップ

```bash
git clone https://github.com/tanuuuuuuu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
source ~/.zshrc
```

## setup.sh がやること

1. Homebrew をインストール（未インストールの場合）
2. `Brewfile` のパッケージをインストール
3. mise で Python をインストール
4. uv をインストール
5. `.config/uv/uv-tools.txt` に記載されたツールをインストール
6. Claude Code をインストール（未インストールの場合）
7. シンボリックリンクを作成（`.zshrc`, `.config/`, `.claude/`）

## 手動でインストールするアプリ

Homebrew で管理できないアプリ。

| アプリ | 入手先 | 説明 |
|--------|--------|------|
| RunCat | [App Store](https://apps.apple.com/jp/app/runcat/id1429033973) | メニューバーでCPU使用率を表示 |

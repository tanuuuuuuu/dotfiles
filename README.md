# dotfiles

個人用の設定ファイル管理リポジトリ。

## 前提

- OS: macOS（Intel / Apple Silicon どちらも対応）
- シェル: zsh

## リポジトリ配置

ローカルリポジトリは基本的に `~/repos/` で管理する。dotfiles のみ慣習的なわかりやすさから `~/dotfiles/` に配置。

```
~/
├── dotfiles/    # このリポジトリ（設定ファイル管理）
└── repos/       # その他のリポジトリ
```

## ディレクトリ構造

```
.
├── .gitattributes           # Git属性設定
├── .gitignore               # Git除外設定
├── .zprofile                # ログインシェル設定
├── .zshrc                   # インタラクティブシェル設定
├── Brewfile                 # Homebrewパッケージ
├── setup.sh                 # セットアップスクリプト
├── macos.sh                 # macOS システム設定
│
├── .config/
│   ├── ghostty/
│   │   ├── config           # Ghostty設定
│   │   └── bg.jpg           # 背景画像
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
    │   ├── canvas-design/   # ビジュアルデザイン・アート作成（Anthropic公式）
    │   ├── claude-md/       # CLAUDE.md作成・改善スキル
    │   ├── doc-coauthoring/ # ドキュメント共同執筆ワークフロー（Anthropic公式）
    │   ├── git-cleanup/     # PRマージ後のブランチ整理
    │   ├── internal-comms/  # 社内コミュニケーション作成（Anthropic公式）
    │   ├── skill-creator/   # スキル作成ガイド（Anthropic公式）
    │   └── theme-factory/   # アーティファクトのテーマ適用（Anthropic公式）
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
7. Google Cloud SDK をインストール（未インストールの場合）
8. シンボリックリンクを作成（`.zprofile`, `.zshrc`, `.config/`, `.claude/`）

## macOS システム設定

`defaults` コマンドによる macOS 設定を適用する。`setup.sh` とは独立しており、必要に応じて手動実行する。

```bash
./macos.sh
```

含まれる設定:
- **Dock**: 右側配置、自動非表示、アイコンサイズ、アニメーション速度
- **Finder**: 隠しファイル表示、拡張子表示、パスバー、ステータスバー、カラム表示、フォルダ優先
- **キーボード**: キーリピート速度（超速）、長押しでキーリピート
- **テキスト入力**: 自動大文字・スペル修正・スマート引用符などを無効化
- **トラックパッド**: タップでクリック、3本指ドラッグ、ナチュラルスクロール
- **マウス**: スクロール速度
- **Hot Corners**: 左下でスクリーンセーバー
- **メニューバー**: バッテリー%表示、Bluetooth表示
- **スクリーンショット**: ~/Pictures/Screenshots に保存
- **TextEdit**: デフォルトをプレーンテキストに
- **その他**: .DS_Store をネットワーク/USB に作成しない、フォルダ名を英語表示

**注意**: システムフォルダの英語表示に sudo が必要です。

## 手動でインストールするアプリ

Homebrew で管理できないアプリ。

| アプリ | 入手先 | 説明 |
|--------|--------|------|
| RunCat | [App Store](https://apps.apple.com/jp/app/runcat/id1429033973) | メニューバーでCPU使用率を表示 |

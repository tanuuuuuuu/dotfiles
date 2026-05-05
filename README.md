# dotfiles

macOS / Windows (WSL Ubuntu) 対応の個人設定ファイル管理リポジトリ。

![開発環境](assets/dev-environment.png)
*Ghostty + Zellij 上で AstroNvim と Claude Code を使った開発環境*

シェル、エディタ、ターミナル等の設定をシンボリックリンクで管理する。`~/dotfiles/` に clone して使用。

> **注意**: Windows環境ではWSLのUbuntuを使用します。PowerShellは使用しません。

## 技術スタック

### macOS

| カテゴリ | ツール | 説明 |
|----------|--------|------|
| OS | macOS | Intel / Apple Silicon 両対応 |
| パッケージ管理 | Homebrew | macOS 用パッケージマネージャ |
| | mise | ランタイムバージョン管理（Python 等） |
| | uv | 高速な Python パッケージマネージャ |
| シェル | zsh | デフォルトシェル |
| | Starship | カスタマイズ可能なプロンプト |
| ターミナル | Ghostty | ターミナルエミュレータ |
| | Zellij | ターミナルマルチプレクサ（tmux 代替） |
| 開発ツール | Neovim（AstroNvim ベース） | エディタ |
| | Claude Code | コーディングエージェント |
| ユーティリティ | Raycast | ランチャーアプリ |

### Windows (WSL Ubuntu)

| カテゴリ | ツール | 説明 |
|----------|--------|------|
| OS | Windows 10/11 + WSL2 | WSL2 で Ubuntu を使用 |
| パッケージ管理 | Homebrew (Linux版) | Linux 用パッケージマネージャ |
| | mise | ランタイムバージョン管理（Python 等） |
| | uv | 高速な Python パッケージマネージャ |
| シェル | zsh | デフォルトシェル（Ubuntu） |
| | Starship | カスタマイズ可能なプロンプト |
| ターミナル | Windows Terminal | ターミナルエミュレータ（WSL Ubuntu接続） |
| | Zellij | ターミナルマルチプレクサ（tmux 代替） |
| 開発ツール | Neovim（AstroNvim ベース） | エディタ |
| | Claude Code | コーディングエージェント |

## ディレクトリ構成

```
.
├── .zprofile                      # ログインシェル設定（macOS/WSL共通）
├── .zshrc                         # インタラクティブシェル設定（macOS/WSL共通）
├── Brewfile                       # Homebrew パッケージ（共通）
├── Brewfile.macos                 # macOS 専用パッケージ
├── Brewfile.linux                 # Linux 専用パッケージ
├── setup.sh                       # セットアップスクリプト（macOS/WSL共通）
├── macos.sh                       # macOS: システム設定スクリプト
├── windows.sh                     # Windows: システム設定スクリプト（WSLから実行）
│
├── .config/                       # ~/.config/ にリンク
│   ├── ghostty/                   # macOS: ターミナル設定
│   ├── windows-terminal/          # Windows: Windows Terminal 設定（WSL Ubuntu用）
│   ├── nvim/                      # Neovim 設定（共通）
│   ├── mise/                      # ランタイム管理設定（共通）
│   ├── raycast/                   # macOS: Raycast スクリプト
│   ├── powertoys-run/             # Windows: PowerToys Run スクリプト（参考用）
│   ├── starship.toml              # プロンプト設定（共通）
│   ├── uv/                        # Python パッケージ管理設定（共通）
│   └── zellij/                    # ターミナルマルチプレクサ設定（共通）
│
└── .claude/                       # ~/.claude/ にリンク（ユーザーレベル設定）
    ├── CLAUDE.md                  # カスタム指示
    ├── settings.json              # 設定
    └── skills/                    # カスタムスキル
```

詳細は各ディレクトリの README を参照。

## セットアップ

### macOS

#### 前提条件

- macOS（Intel / Apple Silicon 両対応）
- zsh（macOS デフォルト）
- Git
- Xcode Command Line Tools

#### インストール

```bash
git clone https://github.com/tanuuuuuuu/dotfiles.git ~/dotfiles
~/dotfiles/setup.sh
source ~/.zshrc  # またはターミナル再起動
```

> [!WARNING]
> - 既存の設定ファイル（.zshrc, .zprofile, .config/nvim 等）は上書きされる。必要に応じて事前にバックアップを取ること
> - Homebrew のインストール時に sudo パスワードを求められる場合がある

#### setup.sh の内容

1. Homebrew をインストール（未インストールの場合）
2. Brewfile のパッケージをインストール（共通 + macOS 専用）
3. mise で Python をインストール
4. uv をインストール
5. uv-tools.txt に記載されたツールをインストール
6. Claude Code をインストール（未インストールの場合）
7. Google Cloud SDK をインストール（未インストールの場合）
8. シンボリックリンクを作成

### Windows (WSL Ubuntu)

#### 前提条件

- Windows 10/11
- WSL2 がインストール済み
- Ubuntu がインストール済み（WSL内）
- Git（Ubuntu内）

#### インストール

1. Windows Terminal を開き、Ubuntu プロファイルを選択
2. WSL Ubuntu 内で以下を実行:

```bash
git clone https://github.com/tanuuuuuuu/dotfiles.git ~/dotfiles
~/dotfiles/setup.sh
source ~/.zshrc  # またはターミナル再起動
```

> **注意**
> - 既存の設定ファイル（.zshrc, .zprofile, .config/nvim 等）は上書きされる。必要に応じて事前にバックアップを取ること
> - Homebrew のインストール時に sudo パスワードを求められる場合がある
> - WSL環境では Homebrew の Linux版が使用される

#### setup.sh の内容（WSL環境）

1. Homebrew (Linux版) をインストール（未インストールの場合）
2. Brewfile のパッケージをインストール（共通 + Linux 専用）
3. デフォルトシェルを zsh に変更
4. **GUIアプリをapt/.debでインストール**（Discord、Slack、Notion、Obsidian、Google Chrome、1Password CLI）
5. mise で Python をインストール
6. uv をインストール
7. uv-tools.txt に記載されたツールをインストール
8. Claude Code をインストール（未インストールの場合）
9. Google Cloud SDK をインストール（未インストールの場合）
10. シンボリックリンクを作成（Ghostty、Raycast設定はスキップ）

> **注意**: WSL環境でGUIアプリを実行するには、WSLg（Windows 11推奨）またはX11転送が必要です。Windows 10の場合はWSLgが利用できないため、X11転送の設定が必要な場合があります。

#### Windows Terminal 設定

Windows Terminal の設定ファイルを適用する場合:

1. Windows Terminal を開く
2. 設定（Ctrl + ,）を開く
3. 「JSONファイルを開く」をクリック
4. `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` を開く
5. `.config/windows-terminal/settings.json` の内容をコピーして適用（または手動で設定）

> **注意**: Windows Terminal の設定は直接コピーするか、手動で設定してください。シンボリックリンクは使用できません。

## カスタムコマンド

`.zshrc` で定義しているシェル関数。

| コマンド | 説明 |
|----------|------|
| `dotup` | dotfiles を最新化（`git pull` → `setup.sh` 実行）し、Brewfile から削除されたパッケージを警告表示する |

## macOS システム設定

`defaults` コマンドで macOS の設定を適用する。setup.sh とは独立しており、必要に応じて手動実行する。

#### 使い方

```bash
~/dotfiles/macos.sh
```

> [!WARNING]
> - システムフォルダの英語表示に sudo パスワードが必要
> - 設定反映のため、実行後に再ログインまたは再起動を推奨

#### macos.sh の内容

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

### Windows (WSL Ubuntu)

WSL から `reg.exe` コマンドで Windows のレジストリ設定を適用する。setup.sh とは独立しており、必要に応じて手動実行する。

#### 使い方

```bash
~/dotfiles/windows.sh
```

> **注意**
> - 一部の設定（CapsLock リマップ、高速スタートアップ）は管理者権限が必要
> - 設定反映のため、実行後に再ログインまたは再起動を推奨

#### windows.sh の内容

- **キーボード**: キーリピート速度（最速）、CapsLock → Ctrl リマップ
- **エクスプローラー**: 隠しファイル表示、拡張子表示、フォルダを先頭に表示
- **外観**: ダークモード（アプリ・システム両方）
- **タスクバー**: 自動非表示、検索ボックス非表示、タスクビュー・Copilot・ウィジェット・チャットボタン非表示
- **電源**: 高速スタートアップ無効化（WSL安定性向上のため）
- **サウンド**: 通知音無効化

## 手動インストールアプリ

### macOS

Homebrew で管理できないアプリ。

| アプリ | 入手先 | 説明 |
|--------|--------|------|
| RunCat | [App Store](https://apps.apple.com/jp/app/runcat/id1429033973) | メニューバーでCPU使用率を表示 |

### Windows (WSL Ubuntu)

WSL環境で使用するアプリ。

| アプリ | 入手先 | 説明 |
|--------|--------|------|
| Windows Terminal | [Microsoft Store](https://apps.microsoft.com/detail/9N0DX20HK701) | ターミナルエミュレータ（WSL Ubuntu接続用） |
| WSL2 | [Microsoft公式](https://learn.microsoft.com/ja-jp/windows/wsl/install) | Windows Subsystem for Linux |
| Ubuntu | [Microsoft Store](https://apps.microsoft.com/detail/9PDXGNCFSCZV) | WSL用Ubuntuディストリビューション |

#### GUIアプリのインストール

`setup.sh` を実行すると、以下のGUIアプリが自動的にインストールされます（.debパッケージまたはaptリポジトリ経由）：

- **Discord**: .debパッケージをダウンロードしてインストール
- **Slack**: .debパッケージをダウンロードしてインストール
- **Notion**: notion-repackagedの.debパッケージをインストール
- **Obsidian**: .debパッケージをダウンロードしてインストール
- **Google Chrome**: 公式aptリポジトリを追加してインストール
- **1Password CLI**: バイナリを直接インストール

> **注意**:
> - 各アプリのインストールは、既にインストール済みの場合はスキップされます
> - インストールに失敗してもスクリプトは続行されます
> - GUIアプリを実行するには、WSLg（Windows 11推奨）が必要です

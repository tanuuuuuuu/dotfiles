# dotfiles

個人用の設定ファイル管理リポジトリ。

## 前提

- OS: macOS（Intel / Apple Silicon どちらも対応）
- シェル: zsh

## 含まれる設定

| ファイル          | 説明                                 |
| ----------------- | ------------------------------------ |
| `.zshrc`          | シェル設定                           |
| `.python-version` | グローバルPythonバージョン           |
| `Brewfile`        | Homebrewでインストールするパッケージ |
| `uv/uv.toml`      | uv設定                               |
| `uv/uv-tools.txt` | uvでインストールするツール           |

## セットアップ

```bash
git clone https://github.com/tanu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
source ~/.zshrc
```

## setup.sh がやること

1. Homebrew をインストール（未インストールの場合）
2. `Brewfile` のパッケージをインストール
3. uv をインストール
4. Python 3.13 をインストール
5. `uv/uv-tools.txt` に記載されたツールをインストール
6. シンボリックリンクを作成

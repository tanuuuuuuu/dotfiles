#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==================================================
# Homebrew
# ==================================================
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # アーキテクチャ/OS に応じてパスを設定
    if [[ -f /opt/homebrew/bin/brew ]]; then
        # Apple Silicon
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        # Linux (WSL含む)
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

OS=$(uname -s)

brew bundle --file="$DOTFILES_DIR/Brewfile"
if [[ "$OS" == "Darwin" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile.macos"
elif [[ "$OS" == "Linux" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile.linux"
fi

# ==================================================
# デフォルトシェルを zsh に変更（Linux のみ）
# ==================================================
if [[ "$OS" == "Linux" ]]; then
    ZSH_PATH=$(which zsh)
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        echo "Changing default shell to zsh..."
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$ZSH_PATH"
    fi
fi

# ==================================================
# WSL環境: aptでGUIアプリをインストール
# ==================================================
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
    echo "WSL環境を検出しました。GUIアプリとCLIツールをインストールします..."

    # 必要なツールをインストール
    sudo apt-get update
    sudo apt-get install -y wget curl gdebi-core unzip apt-transport-https ca-certificates gnupg lsb-release

    # trash-cli (trash の Linux 代替)
    if ! command -v trash &> /dev/null; then
        echo "Installing trash-cli..."
        sudo apt-get install -y trash-cli 2>/dev/null || true
    fi

    # 一時ディレクトリ
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Discord (.debパッケージ)
    if ! command -v discord &> /dev/null; then
        echo "Installing Discord..."
        wget -qO discord.deb "https://discord.com/api/download?platform=linux&format=deb" 2>/dev/null || true
        if [ -f discord.deb ] && [ -s discord.deb ]; then
            sudo gdebi -n discord.deb 2>/dev/null || sudo dpkg -i discord.deb 2>/dev/null || true
            sudo apt-get install -f -y 2>/dev/null || true
        fi
    fi

    # Slack (.debパッケージ)
    if ! command -v slack &> /dev/null; then
        echo "Installing Slack..."
        SLACK_VERSION="4.40.130"
        wget -qO slack.deb "https://downloads.slack-edge.com/releases/linux/${SLACK_VERSION}/prod/x64/slack-desktop-${SLACK_VERSION}-amd64.deb" 2>/dev/null || true
        if [ -f slack.deb ] && [ -s slack.deb ]; then
            sudo gdebi -n slack.deb 2>/dev/null || sudo dpkg -i slack.deb 2>/dev/null || true
            sudo apt-get install -f -y 2>/dev/null || true
        fi
    fi

    # Notion (.debパッケージ - notion-repackagedを使用)
    if ! command -v notion-app &> /dev/null; then
        echo "Installing Notion..."
        NOTION_VERSION=$(curl -s https://api.github.com/repos/notion-enhancer/notion-repackaged/releases/latest 2>/dev/null | grep -oP '"tag_name": "\K[^"]+' | head -1)
        if [ -n "$NOTION_VERSION" ]; then
            wget -qO notion.deb "https://github.com/notion-enhancer/notion-repackaged/releases/download/${NOTION_VERSION}/Notion-${NOTION_VERSION#v}-linux.deb" 2>/dev/null || true
            if [ -f notion.deb ] && [ -s notion.deb ]; then
                sudo gdebi -n notion.deb 2>/dev/null || sudo dpkg -i notion.deb 2>/dev/null || true
                sudo apt-get install -f -y 2>/dev/null || true
            fi
        fi
    fi

    # Obsidian (.debパッケージ)
    if ! command -v obsidian &> /dev/null; then
        echo "Installing Obsidian..."
        OBSIDIAN_VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest 2>/dev/null | grep -oP '"tag_name": "\K[^"]+' | head -1)
        if [ -n "$OBSIDIAN_VERSION" ]; then
            wget -qO obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/download/${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION#v}_amd64.deb" 2>/dev/null || true
            if [ -f obsidian.deb ] && [ -s obsidian.deb ]; then
                sudo gdebi -n obsidian.deb 2>/dev/null || sudo dpkg -i obsidian.deb 2>/dev/null || true
                sudo apt-get install -f -y 2>/dev/null || true
            fi
        fi
    fi

    # Google Chrome (aptリポジトリを追加)
    if ! command -v google-chrome &> /dev/null && ! command -v google-chrome-stable &> /dev/null; then
        echo "Installing Google Chrome..."
        if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 2>/dev/null || true
            echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
            sudo apt-get update 2>/dev/null || true
        fi
        sudo apt-get install -y google-chrome-stable 2>/dev/null || true
    fi

    # 1Password CLI (バイナリを直接インストール)
    if ! command -v op &> /dev/null; then
        echo "Installing 1Password CLI..."
        OP_VERSION="v2.24.0"
        wget -qO op.zip "https://cache.agilebits.com/dist/1P/op2/pkg/${OP_VERSION}/op_linux_amd64_${OP_VERSION}.zip" 2>/dev/null || true
        if [ -f op.zip ] && [ -s op.zip ]; then
            unzip -q op.zip -d /tmp/op-install 2>/dev/null || true
            if [ -f /tmp/op-install/op ]; then
                sudo mv /tmp/op-install/op /usr/local/bin/op 2>/dev/null || true
                sudo chmod +x /usr/local/bin/op 2>/dev/null || true
            fi
            rm -rf /tmp/op-install 2>/dev/null || true
        fi
    fi

    # クリーンアップ
    cd "$HOME"
    rm -rf "$TEMP_DIR"

    echo ""
    echo "WSL環境のGUIアプリインストールが完了しました。"
    echo "注意: WSL環境でGUIアプリを実行するには、WSLg（Windows 11推奨）またはX11転送が必要です。"
fi

# ==================================================
# mise（グローバル Python）
# ==================================================
mise trust "$DOTFILES_DIR/.config/mise/config.toml"
eval "$(mise activate bash)"
mise install

# ==================================================
# uv（グローバル CLI ツール）
# ==================================================
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -f "$DOTFILES_DIR/.config/uv/uv-tools.txt" ]; then
    while IFS= read -r tool || [ -n "$tool" ]; do
        [[ "$tool" =~ ^#.*$ || -z "$tool" ]] && continue
        echo "Installing $tool..."
        uv tool install "$tool"
    done < "$DOTFILES_DIR/.config/uv/uv-tools.txt"
fi

# Playwright ブラウザのインストール
if command -v playwright &> /dev/null; then
    echo "Installing Playwright browsers..."
    playwright install chromium
fi

# ==================================================
# Claude Code
# ==================================================
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

# ==================================================
# Google Cloud SDK
# ==================================================
if ! command -v gcloud &> /dev/null && [ ! -d "$HOME/google-cloud-sdk" ]; then
    echo "Installing Google Cloud SDK..."
    export CLOUDSDK_CORE_DISABLE_PROMPTS=1
    curl https://sdk.cloud.google.com | bash
fi

# ==================================================
# 設定ファイル（シンボリックリンク）
# ==================================================
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/.bash_profile" ~/.bash_profile
ln -sf "$DOTFILES_DIR/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc

mkdir -p ~/.config/mise
ln -sf "$DOTFILES_DIR/.config/mise/config.toml" ~/.config/mise/config.toml

mkdir -p ~/.config/uv
ln -sf "$DOTFILES_DIR/.config/uv/uv.toml" ~/.config/uv/uv.toml

mkdir -p ~/.config/zellij/layouts
ln -sf "$DOTFILES_DIR/.config/zellij/config.kdl" ~/.config/zellij/config.kdl
ln -sf "$DOTFILES_DIR/.config/zellij/layouts/default.kdl" ~/.config/zellij/layouts/default.kdl
ln -sf "$DOTFILES_DIR/.config/zellij/layouts/tmp.kdl" ~/.config/zellij/layouts/tmp.kdl

# macOS 専用の設定リンク
if [[ "$OS" == "Darwin" ]]; then
    mkdir -p ~/.config/ghostty
    ln -sf "$DOTFILES_DIR/.config/ghostty/config" ~/.config/ghostty/config
    ln -sf "$DOTFILES_DIR/.config/ghostty/bg.jpg" ~/.config/ghostty/bg.jpg

    # raycast script-commandsはディレクトリ全体をシンボリックリンク
    if [ -d ~/.config/raycast/script-commands ] && [ ! -L ~/.config/raycast/script-commands ]; then
        rm -rf ~/.config/raycast/script-commands
    fi
    mkdir -p ~/.config/raycast
    ln -sfn "$DOTFILES_DIR/.config/raycast/script-commands" ~/.config/raycast/script-commands
fi

mkdir -p ~/.config/karabiner
ln -sf "$DOTFILES_DIR/.config/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

ln -sf "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml

mkdir -p ~/.config/git
ln -sf "$DOTFILES_DIR/.config/git/ignore" ~/.config/git/ignore

# nvimはディレクトリ全体をシンボリックリンク
if [ -d ~/.config/nvim ] && [ ! -L ~/.config/nvim ]; then
    rm -rf ~/.config/nvim
fi
ln -sfn "$DOTFILES_DIR/.config/nvim" ~/.config/nvim

# Claude Code設定（ファイル単位でリンク、他のファイルは残す）
mkdir -p ~/.claude/sounds
ln -sf "$DOTFILES_DIR/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES_DIR/.claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES_DIR/.claude/statusline.sh" ~/.claude/statusline.sh
ln -sf "$DOTFILES_DIR/.claude/play-sound.sh" ~/.claude/play-sound.sh
ln -sfn "$DOTFILES_DIR/.claude/scripts" ~/.claude/scripts

# skillsはディレクトリ全体をシンボリックリンク
if [ -d ~/.claude/skills ] && [ ! -L ~/.claude/skills ]; then
    rm -rf ~/.claude/skills
fi
ln -sfn "$DOTFILES_DIR/.claude/skills" ~/.claude/skills

# Codex CLI グローバル設定
mkdir -p ~/.codex
ln -sf "$DOTFILES_DIR/.codex/AGENTS.md" ~/.codex/AGENTS.md

# サウンドファイルは macOS のみ使用（afplay コマンド）
if [[ "$OS" == "Darwin" ]]; then
    ln -sf "$DOTFILES_DIR/.claude/sounds/complete_girl.wav" ~/.claude/sounds/complete_girl.wav
    ln -sf "$DOTFILES_DIR/.claude/sounds/confirm.wav" ~/.claude/sounds/confirm.wav
fi

echo "Setup complete! Run 'source ~/.zshrc' to apply changes."

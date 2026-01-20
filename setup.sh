#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==================================================
# Homebrew
# ==================================================
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # アーキテクチャに応じてパスを設定
    if [[ -f /opt/homebrew/bin/brew ]]; then
        # Apple Silicon
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"

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
fi

if [ -f "$DOTFILES_DIR/.config/uv/uv-tools.txt" ]; then
    while IFS= read -r tool || [ -n "$tool" ]; do
        [[ "$tool" =~ ^#.*$ || -z "$tool" ]] && continue
        echo "Installing $tool..."
        uv tool install "$tool"
    done < "$DOTFILES_DIR/.config/uv/uv-tools.txt"
fi

# ==================================================
# 設定ファイル（シンボリックリンク）
# ==================================================
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc

mkdir -p ~/.config/mise
ln -sf "$DOTFILES_DIR/.config/mise/config.toml" ~/.config/mise/config.toml

mkdir -p ~/.config/uv
ln -sf "$DOTFILES_DIR/.config/uv/uv.toml" ~/.config/uv/uv.toml

mkdir -p ~/.config/zellij/layouts
ln -sf "$DOTFILES_DIR/.config/zellij/config.kdl" ~/.config/zellij/config.kdl
ln -sf "$DOTFILES_DIR/.config/zellij/layouts/default.kdl" ~/.config/zellij/layouts/default.kdl

echo "Setup complete! Run 'source ~/.zshrc' to apply changes."

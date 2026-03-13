# ==================================================
# Homebrew
# ==================================================
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ==================================================
# uv（グローバル CLI ツール）
# ==================================================
export PATH="$HOME/.local/bin:$PATH"

# ==================================================
# Google Cloud SDK
# ==================================================
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# ==================================================
# Obsidian CLI
# ==================================================
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

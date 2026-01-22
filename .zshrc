# ==================================================
# mise（グローバル Python）
# ==================================================
eval "$(mise activate zsh)"

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
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  . "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# ==================================================
# プラグイン
# ==================================================
# コマンド入力時に履歴から補完候補を表示
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# ファジーファインダー（Ctrl+Rで履歴検索など）
source $(brew --prefix)/opt/fzf/shell/completion.zsh
source $(brew --prefix)/opt/fzf/shell/key-bindings.zsh
# ターミナル起動時に入力メソッドを英数に切り替え
macism com.apple.keylayout.ABC

# ==================================================
# プロンプト（Starship）
# ==================================================
eval "$(starship init zsh)"

# ==================================================
# その他の設定
# ==================================================
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt correct

# ==================================================
# エイリアス
# ==================================================
alias vim='nvim'

# ==================================================
# Zellij自動起動（Ghostty使用時のみ）
# ==================================================
if [[ "$TERM" == "xterm-ghostty" ]] && [[ -z "$ZELLIJ" ]]; then
  zellij
fi

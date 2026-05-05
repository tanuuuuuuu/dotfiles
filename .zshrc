# ==================================================
# mise（グローバル Python）
# ==================================================
eval "$(mise activate zsh)"

# ==================================================
# Google Cloud SDK（補完）
# ==================================================
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  . "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# ==================================================
# プラグイン
# ==================================================
# Homebrew が利用可能な場合のみプラグインを読み込む
if command -v brew &> /dev/null; then
    BREW_PREFIX=$(brew --prefix)
    # コマンド入力時に履歴から補完候補を表示
    if [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
        source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
    # ファジーファインダー（Ctrl+Rで履歴検索など）
    if [ -f "$BREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then
        source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"
    fi
    if [ -f "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then
        source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
    fi
fi
# ターミナル起動時に入力メソッドを英数に切り替え（macOS専用）
if [[ "$OSTYPE" == "darwin"* ]] && command -v macism &> /dev/null; then
    macism com.apple.keylayout.ABC
fi

# ==================================================
# direnv（ディレクトリごとの環境変数管理）
# ==================================================
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# ==================================================
# プロンプト（Starship）
# ==================================================
eval "$(starship init zsh)"

# ==================================================
# direnv（ディレクトリごとの環境変数管理）
# NOTE: 他のシェル拡張（starship等）の後に置くこと
#       https://direnv.net/docs/hook.html
# ==================================================
eval "$(direnv hook zsh)"

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
alias repo='nocorrect cd $(ghq root)/$(ghq list | fzf)'
alias cm='cmux'

# ==================================================
# カスタム関数
# ==================================================
# dotfiles を pull → setup.sh → Brewfile から消えたパッケージを警告表示
# Usage: dotup
dotup() {
  local DOTDIR="$HOME/dotfiles"
  (
    cd "$DOTDIR" || return 1
    git pull --ff-only || { echo "[dotup] git pull failed" >&2; return 1; }
    ./setup.sh || { echo "[dotup] setup.sh failed" >&2; return 1; }
  ) || return 1

  echo ""
  echo "=== Brewfile から削除されたパッケージのチェック ==="
  brew bundle cleanup --file="$DOTDIR/Brewfile"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew bundle cleanup --file="$DOTDIR/Brewfile.macos" 2>/dev/null
  else
    brew bundle cleanup --file="$DOTDIR/Brewfile.linux" 2>/dev/null
  fi
  echo ""
  echo "削除する場合: brew bundle cleanup --file=<上記の Brewfile> --force"
}

# ==================================================
# tmux 自動起動（Ghostty または WSL 使用時、cmux 内・既に tmux 内なら除外）
# dev session を 5 タブ構成で展開（既存 session があれば attach のみ）
# ==================================================
if [[ -o interactive ]] \
   && [[ -z "$TMUX" ]] \
   && [[ -z "$CMUX_WORKSPACE_ID" ]] \
   && { [[ "$TERM" == "xterm-ghostty" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; }; then
  ~/dotfiles/.config/tmux/scripts/dev-layout.sh
fi

# bun completions
[ -s "/Users/kokubutakuya/.bun/_bun" ] && source "/Users/kokubutakuya/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

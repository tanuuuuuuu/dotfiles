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

# ==================================================
# カスタム関数
# ==================================================
# 指定ディレクトリで Nvim + Claude Code の Zellij タブを開く
# Usage: ztmp [dir]  (省略時はカレントディレクトリ)
ztmp() {
  local dir="${1:-.}"
  local name="$(realpath "$dir" | sed "s|^$HOME|~|")"
  zellij action new-tab --layout ~/.config/zellij/layouts/tmp.kdl --cwd "$dir" --name "$name"
}

# ==================================================
# Zellij自動起動（Ghostty または WSL 使用時）
# ==================================================
# if [[ -o interactive ]] && [[ -z "$ZELLIJ" ]] && { [[ "$TERM" == "xterm-ghostty" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; }; then
#   zellij
# fi

# bun completions
[ -s "/Users/kokubutakuya/.bun/_bun" ] && source "/Users/kokubutakuya/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

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
# コマンド入力時に履歴から補完候補を表示
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# ファジーファインダー（Ctrl+Rで履歴検索など）
source $HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh
source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh
# ターミナル起動時に入力メソッドを英数に切り替え
macism com.apple.keylayout.ABC

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

# ==================================================
# Ghostty ヘルパー関数
# ==================================================
## 指定ディレクトリで垂直分割（左: nvim, 右: claude code）
## 実装は bin/gdev を参照
source "$HOME/.local/bin/gdev"


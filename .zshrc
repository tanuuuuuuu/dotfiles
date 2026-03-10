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
gdev() {
  local dir="${1:-$HOME/dotfiles}"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || { echo "gdev: ディレクトリが見つかりません: $1"; return 1; }

  cd "$dir"

  # Ghostty API で右に分割 + claude 起動 + リサイズ
  osascript <<EOF
    tell application "Ghostty"
      set cfg to new surface configuration
      set command of cfg to "$(which claude)"
      set initial working directory of cfg to "${dir}"
      set environment variables of cfg to {"PATH=$HOME/.local/bin:$PATH"}

      set term to focused terminal of selected tab of front window
      set newTerm to split term direction right with configuration cfg

      perform action "resize_split:right,300" on term
      focus newTerm
    end tell
EOF

  # 左ペインで nvim 起動
  nvim
}


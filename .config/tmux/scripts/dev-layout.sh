#!/usr/bin/env bash
# tmux dev session を 5 タブ構成で自動展開する。
#
# 既存の "dev" session があれば attach するだけ（continuum の自動復元と共存可能）。
# session が無ければ以下のタブを作成して attach する。
# 各 dev タブは「nvim 65% + claude 35% (direnv 経由)」の縦分割。
# 指定ディレクトリが存在しないタブはスキップする（warn）。

set -uo pipefail

SESSION="dev"

# 既に session があれば attach するだけで終了
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

# 並列配列でタブ定義（編集する場合はここだけ）
# mode: dev = nvim + claude split / shell = シェルのみ
TAB_NAMES=("dotfiles" "memory" "polaris" "life" "repos")
TAB_DIRS=(
    "$HOME/dotfiles"
    "$HOME/repos/kubutaku-memory"
    "$HOME/repos/polaris"
    "$HOME/repos/life-dashboard"
    "$HOME/repos"
)
TAB_MODES=("dev" "dev" "dev" "dev" "shell")

# nvim 左 + claude 右（35%）の dev レイアウトを構築
setup_dev_pane() {
    local target="$1" dir="$2"
    tmux send-keys -t "$target" "nvim" Enter
    tmux split-window -h -p 35 -t "$target" -c "$dir"
    tmux send-keys -t "$target" 'eval "$(direnv export zsh 2>/dev/null)" && exec claude' Enter
    # 左の nvim pane に戻る（pane-base-index に依存しないよう -L で相対指定）
    tmux select-pane -t "$target" -L
}

session_created=0
focus_window=""

for i in "${!TAB_NAMES[@]}"; do
    name="${TAB_NAMES[$i]}"
    dir="${TAB_DIRS[$i]}"
    mode="${TAB_MODES[$i]}"

    if [ ! -d "$dir" ]; then
        echo "[dev-layout] skip: $name ($dir not found)" >&2
        continue
    fi

    if [ $session_created -eq 0 ]; then
        tmux new-session -d -s "$SESSION" -n "$name" -c "$dir"
        session_created=1
    else
        tmux new-window -t "$SESSION" -n "$name" -c "$dir"
    fi

    if [ "$mode" = "dev" ]; then
        setup_dev_pane "$SESSION:$name" "$dir"
    fi

    focus_window="$name"
done

# どのタブも作れなかった場合のフォールバック（ホームでシェル 1 つ）
if [ $session_created -eq 0 ]; then
    tmux new-session -d -s "$SESSION" -c "$HOME"
fi

# 最後に登録できたタブにフォーカス
if [ -n "$focus_window" ]; then
    tmux select-window -t "$SESSION:$focus_window"
fi

exec tmux attach -t "$SESSION"

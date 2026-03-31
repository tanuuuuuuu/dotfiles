#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
DISPLAY_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|")

# 色の定義 (GitHub Dark テーマ)
BLUE=$'\033[38;2;88;166;255m'
GREEN=$'\033[38;2;63;185;80m'
YELLOW=$'\033[38;2;210;153;34m'
MAGENTA=$'\033[38;2;188;140;255m'
RED=$'\033[38;2;248;81;85m'
DIM=$'\033[38;2;74;88;92m'
RESET=$'\033[0m'

# 使用率に応じた色を返す (0-49:緑, 50-79:黄, 80-100:赤)
color_for_pct() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then echo "$RED"
    elif [ "$pct" -ge 50 ]; then echo "$YELLOW"
    else echo "$GREEN"
    fi
}

# プログレスバーを生成 (10セグメント, █░)
# 引数: $1=パーセント $2=バーの色
make_bar() {
    local pct=$1
    local color=$2
    local filled=$((pct * 10 / 100))
    [ "$filled" -gt 10 ] && filled=10
    local empty=$((10 - filled))
    local bar=""

    [ "$filled" -gt 0 ] && bar="${color}$(printf "%${filled}s" | tr ' ' '█')"

    if [ "$empty" -gt 0 ]; then
        bar="${bar}${DIM}$(printf "%${empty}s" | tr ' ' '░')${RESET}"
    fi

    echo "$bar"
}

# epoch → JST のリセット時刻文字列 (5h用: H:MM)
format_reset_hm() {
    local epoch=$1
    if [ -z "$epoch" ] || [ "$epoch" = "0" ] || [ "$epoch" = "null" ]; then echo ""; return; fi
    TZ=Asia/Tokyo date -j -f "%s" "$epoch" "+%-H:%M" 2>/dev/null || echo ""
}

# epoch → JST のリセット時刻文字列 (7d用: m/d)
format_reset_md() {
    local epoch=$1
    if [ -z "$epoch" ] || [ "$epoch" = "0" ] || [ "$epoch" = "null" ]; then echo ""; return; fi
    TZ=Asia/Tokyo date -j -f "%s" "$epoch" "+%-m/%-d" 2>/dev/null || echo ""
}

# --- 1行目: ディレクトリ (ブランチ) ---
GIT_INFO=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        DIRTY=""
        if [ -n "$(git -C "$CURRENT_DIR" status --porcelain 2>/dev/null)" ]; then
            DIRTY="${YELLOW}*${RESET}"
        fi
        GIT_INFO=" [${BRANCH}${DIRTY}]"
    fi
fi

echo -e "${DISPLAY_DIR}${GIT_INFO}"

# --- 2行目: コンテキストウィンドウ ---
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
[ -z "$PCT" ] || [ "$PCT" = "null" ] && PCT=0
CTX_COLOR=$(color_for_pct "$PCT")
CTX_PCT="${PCT}"
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
COMPACTIONS=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    COMPACTIONS=$(grep '"compactMetadata"' "$TRANSCRIPT" 2>/dev/null | grep -c '"trigger"')
    [ -z "$COMPACTIONS" ] && COMPACTIONS=0
fi
[ "$COMPACTIONS" -ge 1 ] 2>/dev/null && CTX_COLOR="$RED"
CTX_BAR=$(make_bar "$PCT" "$CTX_COLOR")
CTX_PART="ctx ${CTX_BAR} ${CTX_COLOR}${CTX_PCT}%${RESET}"

# --- 2行目: コンテキスト | 5h | 7d を1行で表示 ---
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)

FIVE_H_RESETS=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_D_RESETS=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$FIVE_H" ] && [ -n "$SEVEN_D" ]; then
    FIVE_COLOR=$(color_for_pct "$FIVE_H")
    SEVEN_COLOR=$(color_for_pct "$SEVEN_D")

    FIVE_BAR=$(make_bar "$FIVE_H" "$FIVE_COLOR")
    SEVEN_BAR=$(make_bar "$SEVEN_D" "$SEVEN_COLOR")

    FIVE_RESET=$(format_reset_hm "$FIVE_H_RESETS")
    SEVEN_RESET=$(format_reset_md "$SEVEN_D_RESETS")

    FIVE_RESET_PART=""
    [ -n "$FIVE_RESET" ] && FIVE_RESET_PART=" ${DIM}↻${FIVE_RESET}${RESET}"
    SEVEN_RESET_PART=""
    [ -n "$SEVEN_RESET" ] && SEVEN_RESET_PART=" ${DIM}↻${SEVEN_RESET}${RESET}"

    echo -e "${CTX_PART} ${DIM}|${RESET} 5h ${FIVE_BAR} ${FIVE_COLOR}${FIVE_H}%${RESET}${FIVE_RESET_PART} ${DIM}|${RESET} 7d ${SEVEN_BAR} ${SEVEN_COLOR}${SEVEN_D}%${RESET}${SEVEN_RESET_PART}"
else
    echo -e "${CTX_PART}"
fi

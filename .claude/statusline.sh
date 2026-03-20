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

# プログレスバーを生成 (10セグメント, ▰▱)
make_bar() {
    local pct=$1
    local filled=$((pct * 10 / 100))
    [ "$filled" -gt 10 ] && filled=10
    local empty=$((10 - filled))
    local bar=""
    [ "$filled" -gt 0 ] && bar=$(printf "%${filled}s" | tr ' ' '■')
    [ "$empty" -gt 0 ] && bar="${bar}$(printf "%${empty}s" | tr ' ' '□')"
    echo "$bar"
}

# epoch → JST のリセット時刻文字列
format_reset_time() {
    local epoch=$1
    if [ -z "$epoch" ] || [ "$epoch" = "0" ]; then
        echo ""
        return
    fi
    TZ=Asia/Tokyo date -j -f "%s" "$epoch" "+%-m/%-d %-H:%M" 2>/dev/null || echo ""
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
CTX_BAR=$(make_bar "$PCT")
CTX_PCT=$(printf "%3d" "$PCT")
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
COMPACTIONS=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    COMPACTIONS=$(grep '"compactMetadata"' "$TRANSCRIPT" 2>/dev/null | grep -c '"trigger"')
    [ -z "$COMPACTIONS" ] && COMPACTIONS=0
fi
[ "$COMPACTIONS" -ge 1 ] 2>/dev/null && CTX_COLOR="$RED"
COMPACT_LABEL="compactions"
[ "$COMPACTIONS" -eq 1 ] 2>/dev/null && COMPACT_LABEL="compaction"
CTX_COMPACT="  ${DIM}${COMPACTIONS} ${COMPACT_LABEL}${RESET}"
echo -e "ctx ${CTX_COLOR}${CTX_BAR} ${CTX_PCT}%${RESET}${CTX_COMPACT}"

# --- 3-4行目: レートリミット (入力JSONから取得) ---
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)

if [ -n "$FIVE_H" ] && [ -n "$SEVEN_D" ]; then
    FIVE_H_EPOCH=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // 0')
    SEVEN_D_EPOCH=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // 0')

    FIVE_COLOR=$(color_for_pct "$FIVE_H")
    SEVEN_COLOR=$(color_for_pct "$SEVEN_D")

    FIVE_BAR=$(make_bar "$FIVE_H")
    SEVEN_BAR=$(make_bar "$SEVEN_D")

    FIVE_RESET_STR=$(format_reset_time "$FIVE_H_EPOCH")
    SEVEN_RESET_STR=$(format_reset_time "$SEVEN_D_EPOCH")

    FIVE_RESET_PART="  ${DIM}reset ${FIVE_RESET_STR:--}${RESET}"
    SEVEN_RESET_PART="  ${DIM}reset ${SEVEN_RESET_STR:--}${RESET}"

    FIVE_PCT=$(printf "%3d" "$FIVE_H")
    SEVEN_PCT=$(printf "%3d" "$SEVEN_D")

    echo -e "5h  ${FIVE_COLOR}${FIVE_BAR} ${FIVE_PCT}%${RESET}${FIVE_RESET_PART}"
    echo -e "7d  ${SEVEN_COLOR}${SEVEN_BAR} ${SEVEN_PCT}%${RESET}${SEVEN_RESET_PART}"
fi

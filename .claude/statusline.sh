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

# --- 3-4行目: レートリミット (キャッシュ付き) ---
QUOTA_CACHE="/tmp/claude-quota-cache"
QUOTA_CACHE_TTL=300

# キャッシュの経過秒数
NOW_EPOCH=$(date +%s)
if [ -f "$QUOTA_CACHE" ]; then
    CACHE_AGE=$(( NOW_EPOCH - $(stat -f %m "$QUOTA_CACHE") ))
    # リセット時刻が過去ならキャッシュを無効化（データが古い）
    read -r _ _ CACHED_5H_EPOCH _ < "$QUOTA_CACHE"
    if [ -n "$CACHED_5H_EPOCH" ] && [ "$CACHED_5H_EPOCH" != "0" ] && [ "$CACHED_5H_EPOCH" -le "$NOW_EPOCH" ] 2>/dev/null; then
        CACHE_AGE=$(( QUOTA_CACHE_TTL + 1 ))
    fi
else
    CACHE_AGE=$(( QUOTA_CACHE_TTL + 1 ))
fi

# バックグラウンドで更新
if [ "$CACHE_AGE" -gt "$QUOTA_CACHE_TTL" ]; then
    (
        QUOTA_JSON=$(bash ~/.claude/scripts/fetch_usage.sh 2>/dev/null)
        if ! echo "$QUOTA_JSON" | jq -e '.five_hour' > /dev/null 2>&1; then
            # API 失敗時: キャッシュがあれば touch して TTL 分は再試行を抑制
            [ -f "$QUOTA_CACHE" ] && touch "$QUOTA_CACHE"
            exit 0
        fi
        FIVE_H=$(echo "$QUOTA_JSON" | jq -r '.five_hour.utilization // 0')
        SEVEN_D=$(echo "$QUOTA_JSON" | jq -r '.seven_day.utilization // 0')
        FIVE_H_RESETS_AT=$(echo "$QUOTA_JSON" | jq -r '.five_hour.resets_at // empty')
        SEVEN_D_RESETS_AT=$(echo "$QUOTA_JSON" | jq -r '.seven_day.resets_at // empty')
        FIVE_H_EPOCH="0"
        if [ -n "$FIVE_H_RESETS_AT" ]; then
            FIVE_H_RESET=$(echo "$FIVE_H_RESETS_AT" | sed 's/\.[0-9]*//' | sed 's/\([-+][0-9][0-9]\):\([0-9][0-9]\)$/\1\2/')
            FIVE_H_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$FIVE_H_RESET" "+%s" 2>/dev/null || echo "0")
        fi
        SEVEN_D_EPOCH="0"
        if [ -n "$SEVEN_D_RESETS_AT" ]; then
            SEVEN_D_RESET=$(echo "$SEVEN_D_RESETS_AT" | sed 's/\.[0-9]*//' | sed 's/\([-+][0-9][0-9]\):\([0-9][0-9]\)$/\1\2/')
            SEVEN_D_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$SEVEN_D_RESET" "+%s" 2>/dev/null || echo "0")
        fi
        echo "$FIVE_H $SEVEN_D $FIVE_H_EPOCH $SEVEN_D_EPOCH" > "$QUOTA_CACHE"
    ) &
fi

# キャッシュから読み取り、3-4行目を出力
if [ -f "$QUOTA_CACHE" ]; then
    read -r FIVE_H SEVEN_D FIVE_H_EPOCH SEVEN_D_EPOCH < "$QUOTA_CACHE"
    if [ -n "$FIVE_H" ] && [ -n "$SEVEN_D" ]; then
        FIVE_H_INT=$(printf "%.0f" "$FIVE_H")
        SEVEN_D_INT=$(printf "%.0f" "$SEVEN_D")

        FIVE_COLOR=$(color_for_pct "$FIVE_H_INT")
        SEVEN_COLOR=$(color_for_pct "$SEVEN_D_INT")

        FIVE_BAR=$(make_bar "$FIVE_H_INT")
        SEVEN_BAR=$(make_bar "$SEVEN_D_INT")

        FIVE_RESET_STR=$(format_reset_time "$FIVE_H_EPOCH")
        SEVEN_RESET_STR=$(format_reset_time "$SEVEN_D_EPOCH")

        FIVE_RESET_PART="  ${DIM}reset ${FIVE_RESET_STR:--}${RESET}"
        SEVEN_RESET_PART="  ${DIM}reset ${SEVEN_RESET_STR:--}${RESET}"

        FIVE_PCT=$(printf "%3d" "$FIVE_H_INT")
        SEVEN_PCT=$(printf "%3d" "$SEVEN_D_INT")

        echo -e "5h  ${FIVE_COLOR}${FIVE_BAR} ${FIVE_PCT}%${RESET}${FIVE_RESET_PART}"
        echo -e "7d  ${SEVEN_COLOR}${SEVEN_BAR} ${SEVEN_PCT}%${RESET}${SEVEN_RESET_PART}"
    fi
fi

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
RESET=$'\033[0m'

# コンテキストウィンドウ使用率を計算
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

CONTEXT_PERCENT=""
if [ "$USAGE" != "null" ] && [ "$CONTEXT_SIZE" != "null" ] && [ "$CONTEXT_SIZE" != "0" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    CONTEXT_PERCENT=" | ${MAGENTA}ctx:${PERCENT}%${RESET}"
fi

# Gitブランチとdirty状態を取得
GIT_INFO=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        DIRTY=""
        if [ -n "$(git -C "$CURRENT_DIR" status --porcelain 2>/dev/null)" ]; then
            DIRTY="${YELLOW}*${RESET}"
        fi
        GIT_INFO=" | ${GREEN}${BRANCH}${RESET}${DIRTY}"
    fi
fi

echo -e "[$MODEL] ${BLUE}${DISPLAY_DIR}${RESET}${GIT_INFO}${CONTEXT_PERCENT}"

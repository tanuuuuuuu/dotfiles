#!/bin/bash
# Claude Code の OAuth トークンを取得し、
# Anthropic の使用量 API を呼び出して結果を返すスクリプト。

set -euo pipefail

CREDS_FILE="$HOME/.claude/.credentials.json"

# 認証情報ファイルからトークン取得
# NOTE: キーチェーン (security find-generic-password -w) は認証情報が長い場合に
# 2KB で切り詰められて JSON が壊れるため、ファイルから読み取る
if [ ! -f "$CREDS_FILE" ]; then
    echo '{"error": "認証情報ファイルが見つかりません。Claude Code で認証済みか確認してください。"}'
    exit 1
fi

TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE")
if [ -z "$TOKEN" ]; then
    echo '{"error": "OAuth トークンが見つかりません。Claude Code で再認証してください。"}'
    exit 1
fi

# API 呼び出し
RESPONSE=$(curl -s --max-time 5 "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Accept: application/json")

# レスポンス検証
if ! echo "$RESPONSE" | jq -e '.five_hour' > /dev/null 2>&1; then
    echo '{"error": "API からの応答が不正です。トークンが期限切れの可能性があります。"}'
    exit 1
fi

echo "$RESPONSE"

#!/bin/bash
# Claude Code の OAuth トークンを取得し、
# Anthropic の使用量 API を呼び出して結果を返すスクリプト。

set -euo pipefail

CREDS_FILE="$HOME/.claude/.credentials.json"

# 認証情報ファイル → キーチェーンの順でトークン取得
TOKEN=""
if [ -f "$CREDS_FILE" ]; then
    TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE")
fi
if [ -z "$TOKEN" ]; then
    KEYCHAIN_JSON=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
    if [ -n "$KEYCHAIN_JSON" ]; then
        TOKEN=$(echo "$KEYCHAIN_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    fi
fi
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
    API_ERROR=$(echo "$RESPONSE" | jq -r '.error.message // .error // "不明なエラー"' 2>/dev/null)
    echo "{\"error\": \"API エラー: ${API_ERROR}\"}"
    exit 1
fi

echo "$RESPONSE"

#!/usr/bin/env bash
# YouTube からメタ情報と字幕を取得する
# 使い方: fetch_transcript.sh <URL> <出力ディレクトリ>
# 出力: <出力ディレクトリ>/<id>.info.json と <id>.<lang>.vtt
# 字幕は手動 ja → 手動 en → 自動 ja → 自動 en の順で試す

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <URL> <output_dir>" >&2
  exit 1
fi

URL="$1"
OUT="$2"
mkdir -p "$OUT"

if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "ERROR: yt-dlp not installed. Run: brew install yt-dlp" >&2
  exit 127
fi

# まず手動字幕（ja, en）を試す
yt-dlp \
  --skip-download \
  --write-info-json \
  --write-subs \
  --sub-langs "ja,en" \
  --sub-format "vtt" \
  --convert-subs vtt \
  -o "$OUT/%(id)s.%(ext)s" \
  "$URL" || true

# 手動字幕が無ければ自動字幕にフォールバック
ID=$(yt-dlp --print id "$URL" 2>/dev/null | head -1)
if ! ls "$OUT"/"$ID".*.vtt >/dev/null 2>&1; then
  echo "Manual subs not found, trying auto-generated..." >&2
  yt-dlp \
    --skip-download \
    --write-info-json \
    --write-auto-subs \
    --sub-langs "ja,en" \
    --sub-format "vtt" \
    --convert-subs vtt \
    -o "$OUT/%(id)s.%(ext)s" \
    "$URL" || true
fi

if ! ls "$OUT"/"$ID".*.vtt >/dev/null 2>&1; then
  echo "ERROR: No subtitles available (manual or auto) for $URL" >&2
  exit 2
fi

echo "OK: $OUT/$ID"
ls -1 "$OUT"/"$ID".* 2>/dev/null || true

#!/bin/sh
# Claude Code PreToolUse/Stop フック。現在のツール操作（Read foo.ts 等）を
# herdr のカスタムトークン $activity として報告し、サイドバーに表示する。
# herdr 管理の herdr-agent-state.sh とは独立（あちらは herdr が上書き管理）。

set -eu

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

activity="$(python3 -c '
import json, os, sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

event = data.get("hook_event_name", "")
if event == "SessionStart":
    # 開始直後から3行目を確保する（空だと行ごと消えて高さがガクつく）
    print("idle")
    sys.exit(0)
if event != "PreToolUse":
    # Stop 等では何も報告せず、直前のツール操作を表示したまま残す
    sys.exit(1)

tool = data.get("tool_name", "")
inp = data.get("tool_input") or {}

if tool in ("Read", "Edit", "Write", "NotebookEdit"):
    print(f"{tool} {os.path.basename(str(inp.get("file_path", "")))}")
elif tool == "Bash":
    desc = inp.get("description") or inp.get("command") or ""
    print(f"$ {str(desc)[:40]}")
elif tool in ("Grep", "Glob"):
    print(f"{tool} {str(inp.get("pattern", ""))[:30]}")
else:
    print(tool)
' 2>/dev/null || true)"

# 空のときは報告しない（直前の表示を維持。空を報告すると行が消える）
[ -n "$activity" ] || exit 0

herdr pane report-metadata "$HERDR_PANE_ID" \
  --source claude-activity-hook \
  --token activity="$activity" 2>/dev/null || true

exit 0

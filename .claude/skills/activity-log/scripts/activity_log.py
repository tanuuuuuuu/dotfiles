#!/usr/bin/env python3
"""Claude Code の活動ログをプロジェクト別に出力する。

使い方:
    python activity_log.py                          # 今日
    python activity_log.py 2026-03-11               # 特定の日
    python activity_log.py 2026-03-01 2026-03-05    # 期間指定
"""

import json
import os
import sys
from collections import defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

JST = ZoneInfo("Asia/Tokyo")
PROJECTS_DIR = Path.home() / ".claude" / "projects"


def parse_args():
    """引数から開始日・終了日を返す (JST aware datetime)。"""
    args = sys.argv[1:]
    today = datetime.now(JST).date()

    if len(args) == 0:
        start = today
        end = today
    elif len(args) == 1:
        start = end = datetime.strptime(args[0], "%Y-%m-%d").date()
    elif len(args) == 2:
        start = datetime.strptime(args[0], "%Y-%m-%d").date()
        end = datetime.strptime(args[1], "%Y-%m-%d").date()
    else:
        print("Usage: activity_log.py [start_date] [end_date]", file=sys.stderr)
        sys.exit(1)

    start_dt = datetime(start.year, start.month, start.day, tzinfo=JST)
    end_dt = datetime(end.year, end.month, end.day, tzinfo=JST) + timedelta(days=1)
    return start_dt, end_dt


def project_name_from_dir(dirname: str) -> str:
    """ディレクトリ名からプロジェクト名を復元する。"""
    if dirname == "-Users-tanu":
        return "~(home)"
    prefix = "-Users-tanu-"
    if dirname.startswith(prefix):
        rest = dirname[len(prefix):]
        return rest.replace("-", "/")
    return dirname


def sessions_from_index(index_path: Path, project_dir: Path, start_dt, end_dt):
    """sessions-index.json からセッションを取得し、JSONL から会話全文を補完する。"""
    sessions = []
    try:
        with open(index_path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return sessions

    for entry in data.get("entries", []):
        created = entry.get("created", "")
        if not created:
            continue
        try:
            dt = datetime.fromisoformat(created.replace("Z", "+00:00")).astimezone(JST)
        except ValueError:
            continue

        if start_dt <= dt < end_dt:
            session_id = entry.get("sessionId", "")
            jsonl_path = project_dir / f"{session_id}.jsonl"
            conversation = _extract_conversation(jsonl_path) if jsonl_path.exists() else []

            sessions.append({
                "time": dt.strftime("%H:%M"),
                "date": dt.strftime("%m/%d"),
                "summary": entry.get("summary", ""),
                "first_prompt": (entry.get("firstPrompt", "") or "")[:200].replace("\n", " ").strip(),
                "message_count": entry.get("messageCount", 0),
                "conversation": conversation,
                "source": "index",
            })
    return sessions


def sessions_from_jsonl(project_dir: Path, start_dt, end_dt):
    """JSONL ファイルの更新日時と会話内容から取得する (フォールバック)。"""
    sessions = []
    start_ts = start_dt.timestamp()
    end_ts = end_dt.timestamp()

    for jsonl_path in project_dir.glob("*.jsonl"):
        if "subagents" in str(jsonl_path):
            continue

        mtime = jsonl_path.stat().st_mtime
        if mtime < start_ts or mtime >= end_ts:
            continue

        mtime_dt = datetime.fromtimestamp(mtime, tz=JST)
        conversation = _extract_conversation(jsonl_path)
        user_messages = [m["text"] for m in conversation if m["role"] == "user"]

        if not user_messages:
            continue

        first_prompt = _find_meaningful_message(user_messages)
        sessions.append({
            "time": mtime_dt.strftime("%H:%M"),
            "date": mtime_dt.strftime("%m/%d"),
            "summary": "",
            "first_prompt": first_prompt[:200].replace("\n", " ").strip(),
            "message_count": len(user_messages),
            "conversation": conversation,
            "source": "jsonl",
        })
    return sessions


def _extract_conversation(jsonl_path: Path) -> list[dict]:
    """JSONL からユーザーとアシスタントの会話を時系列で抽出する。

    Returns:
        [{"role": "user"|"assistant", "text": "..."}]
    """
    messages = []
    try:
        with open(jsonl_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                msg_type = obj.get("type", "")

                if msg_type == "user":
                    text = _extract_text_from_message(obj)
                    if text:
                        messages.append({"role": "user", "text": text})

                elif msg_type == "assistant":
                    text = _extract_text_from_message(obj)
                    if text:
                        messages.append({"role": "assistant", "text": text})
    except Exception:
        pass
    return messages


def _extract_text_from_message(obj: dict) -> str:
    """メッセージオブジェクトからテキスト部分のみを抽出する。"""
    msg = obj.get("message", {})
    if isinstance(msg, str):
        return msg.strip()
    if isinstance(msg, dict):
        content = msg.get("content", "")
        return _extract_text(content)
    return ""


def _extract_text(content) -> str:
    """content からテキストを取り出す。"""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, dict):
        inner = content.get("content", "")
        return _extract_text(inner)
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(item.get("text", ""))
        return " ".join(parts).strip()
    return ""


NOISE_PREFIXES = (
    "<local-command-caveat>",
    "<command-name>",
    "<command-message>",
    "Base directory for this skill:",
)

SHORT_NOISE = {
    "ok", "おk", "おけ", "はい", "yes", "y", "うん",
    "[request interrupted by user]",
}


def _is_noise(text: str) -> bool:
    """セッション操作やコマンドメタデータかどうか判定する。"""
    if any(text.startswith(p) for p in NOISE_PREFIXES):
        return True
    if text.lower().strip() in SHORT_NOISE:
        return True
    if text.startswith("[Request interrupted"):
        return True
    return False


def _find_meaningful_message(messages: list[str]) -> str:
    """ノイズでない最初のメッセージを返す。"""
    for msg in messages:
        if not _is_noise(msg):
            return msg
    return messages[0] if messages else ""


def collect_all_sessions(start_dt, end_dt):
    """全プロジェクトからセッションを収集する。"""
    results = defaultdict(list)

    if not PROJECTS_DIR.exists():
        return results

    for project_dir in PROJECTS_DIR.iterdir():
        if not project_dir.is_dir():
            continue

        project = project_name_from_dir(project_dir.name)
        index_path = project_dir / "sessions-index.json"

        # まず sessions-index.json から取得を試みる
        sessions = sessions_from_index(index_path, project_dir, start_dt, end_dt)

        # インデックスに該当セッションがなければ JSONL フォールバック
        if not sessions:
            sessions = sessions_from_jsonl(project_dir, start_dt, end_dt)

        if sessions:
            results[project].extend(sessions)

    # 各プロジェクト内で時刻順にソート
    for project in results:
        results[project].sort(key=lambda s: s["time"])

    return results


def format_conversation(conversation: list[dict]) -> str:
    """会話をコンパクトなテキストに整形する。"""
    lines = []
    for msg in conversation:
        role = "U" if msg["role"] == "user" else "A"
        text = msg["text"].replace("\n", " ")
        lines.append(f"[{role}] {text}")
    return "\n".join(lines)


def format_markdown(sessions_by_project, start_dt, end_dt):
    """Markdown 形式で出力する。"""
    start_str = start_dt.strftime("%Y-%m-%d")
    end_str = (end_dt - timedelta(days=1)).strftime("%Y-%m-%d")
    if start_str == end_str:
        period = start_str
    else:
        period = f"{start_str} 〜 {end_str}"

    lines = [f"# Claude Code 活動ログ ({period})", ""]

    if not sessions_by_project:
        lines.append("該当期間のセッションはありませんでした。")
        return "\n".join(lines)

    total = sum(len(s) for s in sessions_by_project.values())
    lines.append(f"合計 **{total}** セッション / **{len(sessions_by_project)}** プロジェクト")
    lines.append("")

    for project in sorted(sessions_by_project.keys()):
        sessions = sessions_by_project[project]
        lines.append(f"## {project}")
        lines.append("")
        for s in sessions:
            label = s["summary"] or s["first_prompt"] or "(内容不明)"
            if _is_noise(label):
                label = "(セッション操作)"
            lines.append(f"### [{s['date']} {s['time']}] {label}")
            lines.append("")
            if s["conversation"]:
                lines.append(format_conversation(s["conversation"]))
            lines.append("")
        lines.append("")

    return "\n".join(lines)


def main():
    start_dt, end_dt = parse_args()
    sessions = collect_all_sessions(start_dt, end_dt)
    print(format_markdown(sessions, start_dt, end_dt))


if __name__ == "__main__":
    main()

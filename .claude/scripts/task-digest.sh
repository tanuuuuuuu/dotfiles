#!/bin/bash
#
# Task digest: GitHub の自分宛 open issue を Discord に通知
#
# 表示フォーマットは task-digest-style-guide.md を参照（Single Source of Truth）。
#
# - androots/polaris と androots/workhub から open issue を取得
# - 期日 / 進行状況 / 待ち / その他に分類
# - Discord embed で色分け表示
# - 土日・日本の祝日はスキップ（--force で無視）
#

set -euo pipefail

FORCE=false
if [ "${1:-}" = "--force" ]; then
    FORCE=true
fi

REPOS=("androots/polaris" "androots/workhub")
KEYCHAIN_SERVICE="discord-webhook-task"
TODAY=$(TZ=Asia/Tokyo date +%Y-%m-%d)

#-------------------------------------------------
# 0. 平日 + 祝日でない日のみ実行
#-------------------------------------------------
if [ "$FORCE" = false ]; then
    DOW=$(TZ=Asia/Tokyo date +%u)  # 1=Mon, 7=Sun
    if [ "$DOW" -ge 6 ]; then
        echo "[skip] 土日のため終了" >&2
        exit 0
    fi

    HOLIDAYS_JSON=$(curl -fsS https://holidays-jp.github.io/api/v1/date.json 2>/dev/null || echo '{}')
    if echo "$HOLIDAYS_JSON" | jq -e --arg d "$TODAY" 'has($d)' > /dev/null 2>&1; then
        HOLIDAY_NAME=$(echo "$HOLIDAYS_JSON" | jq -r --arg d "$TODAY" '.[$d]')
        echo "[skip] 祝日（${HOLIDAY_NAME}）のため終了" >&2
        exit 0
    fi
fi

#-------------------------------------------------
# 1. webhook 取得
#-------------------------------------------------
WEBHOOK=$(security find-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || true)
if [ -z "${WEBHOOK:-}" ]; then
    echo "[error] Keychain から webhook URL を取得できません ($KEYCHAIN_SERVICE)" >&2
    exit 1
fi

#-------------------------------------------------
# 2. issue 取得
#-------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ALL_JSON="$TMP/all.json"
echo "[]" > "$ALL_JSON"

for repo in "${REPOS[@]}"; do
    if ! gh issue list --repo "$repo" --assignee @me --state open \
            --json number,title,body,createdAt,updatedAt,labels,url,author \
            --limit 100 > "$TMP/raw.json" 2>"$TMP/err"; then
        echo "[warn] $repo の issue 取得失敗: $(cat $TMP/err)" >&2
        continue
    fi
    jq --arg r "$repo" 'map(. + {repo: $r})' "$TMP/raw.json" > "$TMP/with_repo.json"
    jq -s '.[0] + .[1]' "$ALL_JSON" "$TMP/with_repo.json" > "$TMP/merged.json"
    mv "$TMP/merged.json" "$ALL_JSON"
done

#-------------------------------------------------
# 3. Python で分類・整形して Discord payload (JSON) を出力
#-------------------------------------------------
PAYLOADS_DIR="$TMP/payloads"
mkdir -p "$PAYLOADS_DIR"

python3 - "$ALL_JSON" "$TODAY" "$PAYLOADS_DIR" <<'PYEOF'
import json
import re
import sys
import os
from datetime import date, datetime, timezone, timedelta

JST = timezone(timedelta(hours=9))
WEEKDAYS_JP = ['月', '火', '水', '木', '金', '土', '日']

CATEGORY_DEFS = [
    ('overdue',     '🔴 オーバーデュー',       15158332),
    ('soon',        '🟠 期日近 (3日以内)',     15105570),
    ('in_progress', '🔵 進行中',               3447003),
    ('waiting',     '🟡 待ち / 停滞',          15844367),
    ('other',       '⚪ その他',               9807270),
]
SUMMARY_COLOR = 9807270

EMBED_DESC_LIMIT = 4096
MESSAGE_TOTAL_LIMIT = 6000
MAX_EMBEDS_PER_MESSAGE = 10
TITLE_MAX = 60
SUMMARY_MAX = 80
REQUESTER_MAX = 40

with open(sys.argv[1]) as f:
    issues = json.load(f)
today = date.fromisoformat(sys.argv[2])
payloads_dir = sys.argv[3]

#-------------------------------------------------
# Helpers
#-------------------------------------------------
def repo_short(full):
    name = full.split('/')[-1].lower()
    return {'polaris': 'p', 'workhub': 'w'}.get(name, name[:1])

def parse_deadline(body):
    if not body:
        return None
    m = re.search(r'Deadline\s*[:：]\s*(\d{4}-\d{2}-\d{2})', body)
    if not m:
        return None
    try:
        return date.fromisoformat(m.group(1))
    except ValueError:
        return None

def clean_text(text, max_len):
    text = re.sub(r'```[\s\S]*?```', '', text)
    text = re.sub(r'\n+', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    if len(text) > max_len:
        text = text[:max_len].rstrip() + '…'
    return text

def parse_requester(body, author_login):
    fallback = f"@{author_login}" if author_login else '@?'
    if not body:
        return fallback
    section_re = r'(?:^|\n)##\s*(?:報告元|依頼元|依頼者|報告者|相談者)[^\n]*\n([^\n#]+)'
    m = re.search(section_re, body)
    if m:
        v = clean_text(m.group(1), REQUESTER_MAX)
        if v:
            return v
    line_re = r'(?:^|\n)\s*(?:依頼|報告|相談|from)\s*[:：]\s*([^\n]+)'
    m = re.search(line_re, body, re.IGNORECASE)
    if m:
        v = clean_text(m.group(1), REQUESTER_MAX)
        if v:
            return v
    return fallback

def parse_summary(body):
    if not body:
        return ''
    section_patterns = [
        r'##\s*何をしたいか[^\n]*\n(.+?)(?=\n##|\Z)',
        r'##\s*概要[^\n]*\n(.+?)(?=\n##|\Z)',
        r'##\s*背景[^\n]*\n(.+?)(?=\n##|\Z)',
        r'##\s*What[^\n]*\n(.+?)(?=\n##|\Z)',
    ]
    for p in section_patterns:
        m = re.search(p, body, re.DOTALL | re.IGNORECASE)
        if m:
            return clean_text(m.group(1), SUMMARY_MAX)
    return clean_text(body, SUMMARY_MAX)

def truncate(s, n):
    return s if len(s) <= n else s[:n].rstrip() + '…'

def has_label(issue, names):
    labels = [l['name'].lower() for l in issue.get('labels', [])]
    return any(n.lower() in labels for n in names)

def days_diff(d1, d2):
    return (d1 - d2).days

def fmt_deadline(d):
    """期日表記。今日/超過/3日以内/それ以外で分岐。残4日以上は表示しない (None を返す)"""
    if d is None:
        return None
    diff = days_diff(d, today)
    label = f"{d.month}/{d.day}"
    if diff < 0:
        return f"{label} ({-diff}d経過)"
    if diff == 0:
        return f"{label} (今日)"
    if diff <= 3:
        return f"{label} (残{diff}d)"
    return None  # 4日以上先は表示しない

#-------------------------------------------------
# Categorize
#-------------------------------------------------
categories = {k: [] for k, _, _ in CATEGORY_DEFS}

for issue in issues:
    body = issue.get('body', '') or ''
    deadline = parse_deadline(body)
    requester = parse_requester(body, issue.get('author', {}).get('login', ''))
    summary = parse_summary(body)
    updated = datetime.fromisoformat(issue['updatedAt'].replace('Z', '+00:00')).astimezone(JST).date()
    days_since_update = days_diff(today, updated)

    created = datetime.fromisoformat(issue['createdAt'].replace('Z', '+00:00'))
    enriched = {
        **issue,
        '_deadline': deadline,
        '_requester': requester,
        '_summary': summary,
        '_days_since_update': days_since_update,
        '_updated': updated,
        '_created': created,
    }

    if deadline and deadline < today:
        categories['overdue'].append(enriched)
    elif deadline and 0 <= days_diff(deadline, today) <= 3:
        categories['soon'].append(enriched)
    elif has_label(issue, ['blocked', 'waiting', '待ち', 'on hold']) or days_since_update >= 4:
        categories['waiting'].append(enriched)
    elif days_since_update <= 3:
        categories['in_progress'].append(enriched)
    else:
        categories['other'].append(enriched)

def sort_key(i):
    # 作成日時の降順（新しい issue が上）
    return -i['_created'].timestamp()

for k in categories:
    categories[k].sort(key=sort_key)

#-------------------------------------------------
# Format issue lines per style guide
#-------------------------------------------------
def fmt_issue(issue):
    title = truncate(issue['title'], TITLE_MAX)
    handle = f"{repo_short(issue['repo'])}#{issue['number']}"
    deadline_str = fmt_deadline(issue['_deadline'])
    # 1行目: [**handle title**](URL) · 期日
    line1 = f"[**{handle} {title}**]({issue['url']})"
    if deadline_str:
        line1 += f" · {deadline_str}"
    # 2行目: 　└ 依頼者 · 要約
    parts = [issue['_requester']] if issue['_requester'] else []
    if issue['_summary']:
        parts.append(issue['_summary'])
    line2 = '　└ ' + ' · '.join(parts) if parts else ''
    return f"{line1}\n{line2}".rstrip()

#-------------------------------------------------
# Build embeds
#-------------------------------------------------
def build_summary_embed():
    now_label = datetime.now(JST)
    title = f"📋 タスク進捗 {now_label.month}/{now_label.day} ({WEEKDAYS_JP[now_label.weekday()]}) {now_label.strftime('%H:%M')}"
    lines = []
    for key, label, _ in CATEGORY_DEFS:
        n = len(categories[key])
        lines.append(f"{label}: {n}件")
    desc = '\n'.join(lines)
    total = sum(len(categories[k]) for k in categories)
    return {
        'title': title,
        'color': SUMMARY_COLOR,
        'description': desc,
        'footer': {'text': f"合計 {total} 件"},
    }

def build_category_embeds(key, label, color):
    items = categories[key]
    if not items:
        return []
    blocks = [fmt_issue(i) for i in items]
    embeds = []
    current = []
    current_len = 0
    for b in blocks:
        # 各 issue ブロックの間に空行 1 つを挟む
        sep = '\n\n' if current else ''
        addition_len = len(sep) + len(b)
        if current_len + addition_len > EMBED_DESC_LIMIT:
            embeds.append({
                'title': f"{label} ({len(items)}件)",
                'color': color,
                'description': '\n\n'.join(current),
            })
            current = [b]
            current_len = len(b)
        else:
            current.append(b)
            current_len += addition_len
    if current:
        embeds.append({
            'title': f"{label} ({len(items)}件)",
            'color': color,
            'description': '\n\n'.join(current),
        })
    # (続) を 2 個目以降に付ける
    if len(embeds) > 1:
        for i, e in enumerate(embeds[1:], start=2):
            e['title'] = f"{label} ({len(items)}件) 続{i-1}"
    return embeds

all_embeds = [build_summary_embed()]
for key, label, color in CATEGORY_DEFS:
    all_embeds.extend(build_category_embeds(key, label, color))

#-------------------------------------------------
# Pack into messages (max 10 embeds, max 6000 chars total per message)
#-------------------------------------------------
def embed_size(e):
    s = len(e.get('title', '')) + len(e.get('description', ''))
    if 'footer' in e:
        s += len(e['footer'].get('text', ''))
    return s

messages = []
buf = []
buf_size = 0
for e in all_embeds:
    sz = embed_size(e)
    if buf and (len(buf) >= MAX_EMBEDS_PER_MESSAGE or buf_size + sz > MESSAGE_TOTAL_LIMIT):
        messages.append(buf)
        buf = []
        buf_size = 0
    buf.append(e)
    buf_size += sz
if buf:
    messages.append(buf)

# Part numbering when multiple messages
if len(messages) > 1:
    for idx, msg in enumerate(messages, start=1):
        for e in msg:
            footer = e.setdefault('footer', {})
            existing = footer.get('text', '')
            tag = f"({idx}/{len(messages)})"
            footer['text'] = f"{existing} {tag}".strip() if existing else tag

#-------------------------------------------------
# Write payloads to files (1 file per message)
#-------------------------------------------------
for idx, msg in enumerate(messages):
    path = os.path.join(payloads_dir, f"{idx:02d}.json")
    with open(path, 'w') as f:
        json.dump({'embeds': msg}, f, ensure_ascii=False)

print(f"messages={len(messages)} embeds={len(all_embeds)} total_issues={sum(len(v) for v in categories.values())}")
PYEOF

#-------------------------------------------------
# 4. Discord に投稿
#-------------------------------------------------
post_count=0
for f in $(ls "$PAYLOADS_DIR"/*.json | sort); do
    if curl -fsS -o /dev/null -X POST "$WEBHOOK" \
        -H "Content-Type: application/json" \
        --data-binary "@$f"; then
        post_count=$((post_count + 1))
    else
        echo "[error] Discord 投稿失敗 ($f)" >&2
        exit 1
    fi
    sleep 0.5  # rate limit 緩和
done

NOW_LABEL=$(TZ=Asia/Tokyo date "+%Y-%m-%d %H:%M JST")
echo "[ok] 投稿完了 ($NOW_LABEL, $post_count messages)"

#!/usr/bin/env python3
"""Claude Code UserPromptSubmit / SessionStart フック。

セッションの内容を Haiku に1行で要約させ、herdr のカスタムトークン $summary
として報告する。表示側は ~/.config/herdr/config.toml の [ui.sidebar.agents]。

- UserPromptSubmit: 発言のたびに要約を更新する
- SessionStart: 再開（--resume 等）したセッションに、発言を待たず要約を出す。
  新規セッションは会話ログが空なので何もしない

settings.json では async: true で登録する（要約に数秒かかるため、
プロンプト送信を待たせない）。標準出力には何も出さない
（これらのフックの標準出力は会話コンテキストに注入されるため）。
"""

import json
import os
import shutil
import subprocess
import sys
import unicodedata

# サイドバー1行に収める表示幅の上限（半角=1、全角=2 で数える）。
# 行頭の字下げ等で数列使われるので、config.toml の sidebar_width（42）より 6 小さくしている。
# sidebar_width を変えたらここも合わせる
MAX_CELLS = 36
# 要約の材料にするユーザー発言の数と、1発言あたりの文字数上限
RECENT_PROMPTS = 8
PROMPT_CHARS = 200
# 自分が起動した claude からの再帰呼び出しを止める目印
GUARD_ENV = "HERDR_SUMMARY_HOOK"

SYSTEM_PROMPT = (
    "あなたはコーディングエージェントのセッション一覧に表示する見出しを作る。"
    "入力はユーザーの発言の抜粋。セッション全体の主題（何を対象に何をしているか）を、"
    f"日本語で全角{MAX_CELLS // 2 - 5}〜{MAX_CELLS // 2 - 1}文字の体言止め1行で出力する。"
    "「設定」「対応」のような抽象語だけで終わらせず、具体的な作業内容を入れる。"
    "一時的なやり取り（確認・相づち・操作の報告）は主題に含めない。"
    f"全角{MAX_CELLS // 2}文字を超えてはならない。"
    "[前回の見出し] がある場合、主題が変わっていなければ一字一句そのまま出力し、"
    "主題が変わったか作業が大きく進んだときだけ作り直す。"
    "見出し本文だけを出力し、引用符・句点・説明・前置きは付けない。"
)

# 要約が上限を超えたときの言い直し用（LLM は文字数を正確に数えられないため）
SHORTEN_PROMPT = (
    "入力された見出しは長すぎる。意味を保ったまま、"
    f"日本語で全角{MAX_CELLS // 2 - 2}文字以内の体言止め1行に短縮して出力する。"
    "見出し本文だけを出力し、引用符・句点・説明・前置きは付けない。"
)


def cell_width(text):
    """端末上の表示幅を返す（全角・曖昧幅の文字は 2 として数える）。"""
    return sum(2 if unicodedata.east_asian_width(c) in "WFA" else 1 for c in text)


def truncate(text, max_cells):
    """表示幅が max_cells を超える場合、末尾を … に置き換えて収める。"""
    if cell_width(text) <= max_cells:
        return text
    ellipsis = "…"
    budget = max_cells - cell_width(ellipsis)
    out = ""
    for char in text:
        if cell_width(out + char) > budget:
            break
        out += char
    return out + ellipsis


def previous_summary(pane_id):
    """このペインに前回報告した要約を herdr から取得する。無ければ空文字。"""
    try:
        result = subprocess.run(
            ["herdr", "pane", "get", pane_id],
            capture_output=True,
            text=True,
            timeout=10,
        )
        summary = json.loads(result.stdout)["result"]["pane"]["tokens"].get("summary", "")
    except (OSError, subprocess.SubprocessError, ValueError, KeyError, TypeError):
        return ""
    # 切り詰められた見出しは引き継がない（「…」付きのまま維持されてしまうため）
    return "" if summary.endswith("…") else summary


def past_prompts(transcript_path):
    """会話ログ（JSONL）から、ユーザーが実際に入力した発言だけを取り出す。"""
    prompts = []
    try:
        lines = open(transcript_path, encoding="utf-8")
    except OSError:
        return prompts
    with lines:
        for line in lines:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("type") != "user":
                continue
            # サブエージェントの発言・内部メッセージ・compact 要約は除く
            if entry.get("isSidechain") or entry.get("isMeta") or entry.get("isCompactSummary"):
                continue
            content = entry.get("message", {}).get("content")
            if isinstance(content, list):
                # ツール結果（tool_result）は捨て、テキスト部分だけ残す
                content = "\n".join(b.get("text", "") for b in content if b.get("type") == "text")
            if not isinstance(content, str):
                continue
            content = content.strip()
            # <command-name> などタグで始まるものはコマンド実行の記録なので除く
            if content and not content.startswith("<"):
                prompts.append(content)
    return prompts


def build_input(prompts, previous=""):
    """最初の依頼（目的）と直近の依頼（今の話題）を要約の材料として並べる。

    previous（前回の見出し）も渡す。毎回ゼロから作らせると同じ内容でも
    言い回しが変わり、サイドバーのラベルが揺れて見分けにくくなるため。
    """
    clip = lambda text: " ".join(text.split())[:PROMPT_CHARS]
    parts = ["[最初の依頼]", clip(prompts[0])]
    recent = prompts[1:][-RECENT_PROMPTS:]
    if recent:
        parts.append("[直近の依頼]")
        parts.extend(f"- {clip(p)}" for p in recent)
    if previous:
        parts.extend(["[前回の見出し]", previous])
    return "\n".join(parts)


def summarize(text, system_prompt=SYSTEM_PROMPT):
    """Haiku に要約させる。失敗したら空文字を返す。"""
    # herdr の環境変数を外す: 子の claude が herdr のフックや statusline 経由で
    # このペインの状態表示を書き換えないようにするため
    env = {k: v for k, v in os.environ.items() if not k.startswith("HERDR_")}
    env[GUARD_ENV] = "1"
    try:
        result = subprocess.run(
            [
                "claude", "-p",
                "--model", "haiku",
                "--system-prompt", system_prompt,
                "--tools", "",                # ツール不要
                "--strict-mcp-config",        # MCP サーバーを読み込まない
                "--setting-sources", "",      # ユーザー設定（フック・CLAUDE.md）を読まない
                "--disable-slash-commands",
                "--no-session-persistence",   # 要約用の会話を履歴に残さない
            ],
            input=text,
            capture_output=True,
            text=True,
            timeout=45,
            env=env,
            cwd=os.path.expanduser("~"),
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    if result.returncode != 0:
        return ""
    lines = result.stdout.strip().splitlines()
    return lines[0].strip() if lines else ""


def main():
    pane_id = os.environ.get("HERDR_PANE_ID")
    if os.environ.get("HERDR_ENV") != "1" or not pane_id or os.environ.get(GUARD_ENV):
        return
    if not shutil.which("herdr") or not shutil.which("claude"):
        return

    try:
        hook_input = json.load(sys.stdin)
    except ValueError:
        return

    prompts = past_prompts(hook_input.get("transcript_path") or "")
    # 今回の発言はまだ会話ログに書かれていないことがあるので、無ければ足す
    current = (hook_input.get("prompt") or "").strip()
    if current and (not prompts or prompts[-1] != current):
        prompts.append(current)
    if not prompts:
        return

    summary = summarize(build_input(prompts, previous_summary(pane_id)))
    if not summary:
        return  # 失敗時は報告しない（直前の表示を維持）
    if cell_width(summary) > MAX_CELLS:
        # 上限超えは1回だけ言い直させる。それでも超えたら下の truncate が切る
        summary = summarize(summary, SHORTEN_PROMPT) or summary

    subprocess.run(
        [
            "herdr", "pane", "report-metadata", pane_id,
            "--source", "claude-summary-hook",
            "--token", f"summary={truncate(summary, MAX_CELLS)}",
        ],
        capture_output=True,
        timeout=10,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # フックの失敗で Claude Code の動作を妨げない
    sys.exit(0)

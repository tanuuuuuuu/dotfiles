---
name: quota
description: Claude の API 使用量クォータを確認。5時間・7日間ローリングウィンドウの使用率（%）とリセット時刻を表示。「/quota」「使用量」「クォータ」「残量」「あとどれくらい使える」で使用。
allowed-tools: Bash(bash ~/.claude/skills/quota/scripts/fetch_usage.sh:*)
---

# Quota

macOS キーチェーンから Claude Code の認証情報を使い、Anthropic の使用量 API を呼び出してクォータ状況を取得・表示する。

## ワークフロー

1. `scripts/fetch_usage.sh` を実行して JSON を取得
2. エラーの場合はエラーメッセージをそのまま伝える
3. 成功した場合は以下をシンプルに報告:
   - **5時間ウィンドウ**: 使用率 % とリセット時刻（日本時間に変換）
   - **7日間ウィンドウ**: 使用率 % とリセット時刻（日本時間に変換）
   - モデル別の内訳があれば（`seven_day_opus`, `seven_day_sonnet` 等が non-null なら）追記

## 注意事項

- macOS 専用（`security` コマンドでキーチェーンにアクセス）
- 非公式 API のため将来動作しなくなる可能性がある
- トークン期限切れでエラーになることがある。その場合は Claude Code を再起動すると解消される場合がある旨を伝える

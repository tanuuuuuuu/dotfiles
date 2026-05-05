# tmux 設定

くぶたく用の tmux 設定。XDG 準拠で `~/.config/tmux/tmux.conf` に配置する。dotfiles からシンボリックリンクで参照される。

## 設計方針

- **prefix は `Ctrl-b`（デフォルト維持）**
- **vim 流のキーバインド**（hjkl で pane 移動）
- **設定ファイルは小さく保ち、自分で育てる**
- **配色は VS Code Dark / Tokyo Night 系**（zellij からの引き継ぎ）

## 機能一覧

### 基本動作

| 機能 | 設定値 | 効果 |
|---|---|---|
| 256 色 + true color | `default-terminal` + `terminal-overrides` | nvim のカラーテーマがフルカラーで出る |
| インデックス 1 始まり | `base-index 1` / `pane-base-index 1` | キーボードで `1〜9` が押しやすい |
| window 番号の自動詰め | `renumber-windows on` | window を閉じても歯抜けにならない |
| スクロールバック 10 万行 | `history-limit 100000` | 長いビルドログでも流れない |
| Esc 遅延 10ms | `escape-time 10` | nvim の Esc が即反応 |
| マウス操作 | `mouse on` | クリックで pane 切替、ドラッグでリサイズ、ホイールでスクロール |

### キーバインド

#### Prefix キー

`Ctrl-b` を押してから次のキー、という二段階操作。tmux のすべての操作の起点。

#### pane 操作

| 操作 | キー | 備考 |
|---|---|---|
| 縦分割（左右） | `prefix \|` | 現在の作業ディレクトリを引き継ぐ |
| 横分割（上下） | `prefix -` | 同上 |
| pane フォーカス左 | `prefix h` または `Alt+h` | Alt 版は prefix 不要 |
| pane フォーカス下 | `prefix j` または `Alt+j` | 同上 |
| pane フォーカス上 | `prefix k` または `Alt+k` | 同上 |
| pane フォーカス右 | `prefix l` または `Alt+l` | 同上 |
| pane リサイズ左 | `prefix H`（連打可） | `-r` で Shift 押しっぱでも反応 |
| pane リサイズ下 | `prefix J`（連打可） | 同上 |
| pane リサイズ上 | `prefix K`（連打可） | 同上 |
| pane リサイズ右 | `prefix L`（連打可） | 同上 |
| pane 全画面切替 | `prefix z` | tmux デフォルト（zoom）|
| pane 閉じる | `prefix x` | tmux デフォルト |

#### window（タブ）操作

`tmux.conf` で明示してないが tmux デフォルトで使える主要操作:

| 操作 | キー |
|---|---|
| window 新規作成 | `prefix c` |
| window 切替（次） | `prefix n` |
| window 切替（前） | `prefix p` |
| window 直接指定 | `prefix 1〜9` |
| **直前の window に戻る** | `prefix Tab` |
| window 名変更 | `prefix ,` |
| window 閉じる | `prefix &` |
| window 一覧から選択 | `prefix w` |

注: tmux デフォルトの「直前 window」は `prefix l` だが、ここでは `prefix l` を vim 流の
「右 pane へ移動（select-pane -R）」に上書きしているため `prefix Tab` に逃がしている。

#### session 操作（detach / attach）

| 操作 | キー / コマンド |
|---|---|
| detach（切り離し）| `prefix d` |
| attach（再接続）| シェルから `tmux attach` または `tmux a` |
| session 一覧から選択 | `prefix s` |
| session 名変更 | `prefix $` |
| session 新規作成 | シェルから `tmux new -s セッション名` |

#### その他

| 操作 | キー |
|---|---|
| 設定ファイル再読み込み | `prefix r` |
| コマンドモード | `prefix :` |
| ヘルプ（キーバインド一覧） | `prefix ?` |
| copy mode（スクロール / 検索） | `prefix [` （`q` で抜ける）|

### ステータスバー

下部 1 行のバーに以下を表示:

```
 [session名] | [window1] [window2*]                                 2026-05-05 19:07
```

| エリア | 内容 | 色 |
|---|---|---|
| 左 | 現在のセッション名 | 青（`#7aa2f7`）|
| 中央 | window のリスト（アクティブは青背景） | 白 / アクティブは反転 |
| 右 | 日付 + 時刻 | 緑（日付） / 黄（時刻） |
| pane 枠 | アクティブ pane だけ青枠 | `#7aa2f7` |

## ユースケース

### Case 1: 1 つのプロジェクトで作業

```bash
cd ~/repos/myproject
tmux new -s myproject
```

→ tmux セッション `myproject` が起動。`prefix |` で縦分割して左で nvim、右で `npm run dev` などの定番。

### Case 2: ターミナルを閉じても作業を継続

長時間ビルドや学習スクリプトを走らせている時:

1. tmux 内でジョブを起動
2. `prefix d` で detach（ターミナルは閉じても OK）
3. 後で `tmux attach` または `tmux a -t myproject` で復帰
4. 画面・ログ・実行中プロセスがそのまま残ってる

### Case 3: SSH 切断対策（リモートサーバー）

```bash
ssh user@server
tmux new -s work     # サーバー側で tmux 起動
# 中で長時間ジョブを走らせる
# ネット切断 / 蓋閉じ / VPN 落ち
ssh user@server
tmux attach -t work  # 復帰、ジョブは死んでない
```

### Case 4: 複数プロジェクトを並列で持つ

```bash
tmux new -s frontend     # 1 つ目のセッション作って detach
tmux new -s backend      # 2 つ目
tmux new -s research     # 3 つ目
tmux ls                  # セッション一覧
tmux attach -t backend   # 戻りたいやつに attach
```

または起動済みなら `prefix s` で一覧から選択。

### Case 5: pane でログ tail と作業を並べる

```bash
tmux new -s dev
# prefix - で横分割
# 上 pane: nvim
# 下 pane: tail -f logs/app.log
```

### Case 6: AI エージェント並列

`~/repos/myproject` で作業中、別ブランチで Claude Code を走らせたい:

1. `git worktree add ../myproject-feat-x feat/x` で別ディレクトリを作成
2. tmux で `prefix c` で新 window
3. `cd ../myproject-feat-x && claude` で並列実行
4. `prefix 1` で本作業 / `prefix 2` で agent 作業を切替

将来的に Phase 3 で「worktree → 自動 window 展開」のスクリプトを書く予定。

## ファイル配置

```
~/dotfiles/.config/tmux/
  ├ tmux.conf              ← 本体
  ├ scripts/
  │   └ dev-layout.sh      ← 5 タブ自動展開スクリプト
  └ README.md              ← このファイル

~/.config/tmux/
  ├ tmux.conf              ← ↑ への symlink（setup.sh が作成）
  └ plugins/               ← TPM が管理（resurrect / continuum / sensible 等）
```

## dev session 自動展開

Ghostty 起動時に `dev` という名前の tmux session が以下の 5 タブ構成で自動的に立ち上がる。
スクリプト本体は `scripts/dev-layout.sh`、呼び出しは `.zshrc` の自動起動ブロック。

| タブ名 | 作業ディレクトリ | 構成 |
|--------|-----------------|------|
| `dotfiles` | `~/dotfiles` | nvim 55% + claude 45%（direnv 環境引き継ぎ） |
| `memory` | `~/repos/kubutaku-memory` | 同上 |
| `polaris` | `~/repos/polaris` | 同上 |
| `life` | `~/repos/life-dashboard` | 同上 |
| `repos` | `~/repos` | シェルのみ（フォーカス） |

存在しないディレクトリは自動スキップ（stderr に warn）。タブを増減したいときは `dev-layout.sh` 内の
`TAB_NAMES` / `TAB_DIRS` / `TAB_MODES` 配列を編集する。

`continuum` が前回の状態を復元できる場合は復元が優先され、`dev-layout.sh` は何もせず attach する。

## トラブルシュート

### 設定変更が反映されない

`tmux.conf` を編集した後は **reload が必要**:

- 起動中の tmux 内で `prefix r`
- または再起動: `tmux kill-server` → 再起動

### 色がおかしい

ターミナルエミュレータが true color 対応してるか確認:

```bash
echo $TERM
# xterm-ghostty / xterm-256color などが期待値
```

### Alt+hjkl が効かない

iTerm2 の場合、「Profiles → Keys → Left Option Key」を **Esc+** に設定する必要あり（Ghostty はデフォルトで OK）。

## 関連

- 上位概念: [tmux の wiki ページ](~/repos/kubutaku-memory/vault/wiki/pages/tmux.md)
- 移行経緯: zellij からの移行（2026-05-05）。詳細は kubutaku-memory の memory 参照
- 公式: <https://github.com/tmux/tmux/wiki>

## 育て方（Phase 2 以降の予定）

| Phase | 内容 |
|---|---|
| Phase 1（現在） | 最小キーバインド + ステータスバー |
| Phase 2 | TPM 導入、tmux-resurrect / continuum で session 永続化、tmuxinator でプロジェクト初期構成 |
| Phase 3 | vim-tmux-navigator で nvim 連携、gitmux で status-line に git 情報、AI 並列運用に最適化（hook + macOS 通知） |

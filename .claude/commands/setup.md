## 起動時チェック 1：PC セットアップ済みか

`~/.claude/ai-devguide-flow.md` が存在するか確認する。

**存在しない場合（PC 未設定）**：以下を順番に実行する。

1. `gh --version` を実行する。コマンドが見つからない場合は、まずインストール済みで PATH 未登録の可能性を確認する：
   - Windows: `& "C:\Program Files\GitHub CLI\gh.exe" --version` も試す
   - macOS/Linux: `which gh` や `/usr/local/bin/gh --version` を試す
   - それでも見つからなければ GitHub CLI をインストールする：
     - Windows: `winget install --id GitHub.cli`（完了後ターミナルを再起動）
     - macOS: `brew install gh`
     - Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md 参照
   - インストール済みで PATH 未登録と判明した場合は、フルパスで `gh` を呼び出すか、人間に「ターミナルを再起動してから `/setup` を再実行してください」と案内する
2. `gh auth status` を確認する。未認証なら `gh auth login` を実行し、表示されたワンタイムコードを人間に伝え「ブラウザでこのコードを承認してください」と求める
3. このファイルを `~/.claude/ai-devguide-flow.md` にコピーする
4. 人間に伝える：「`~/.claude/CLAUDE.md`（なければ新規作成）の末尾に以下の1行を追記してください。完了したらお知らせください。」
   ```
   @import ai-devguide-flow.md
   ```
5. 人間から完了の連絡を受けたら：「次回セッションからすべてのプロジェクトでこのフローが自動認識されます。」と案内する

**存在する場合**：チェック2 へ。

---

## 起動時チェック 2：プロジェクト初期化済みか

`gh label list` を実行し、`eng:project` ラベルが存在するか確認する。

**存在しない場合（未初期化）**：以下を順番に実行する。

1. `eng:` ラベル9個を作成する

```bash
gh label create "eng:project"          --color 6F42C1 --description "レベル: プロジェクト" --force
gh label create "eng:feature"          --color 1D76DB --description "レベル: フィーチャー" --force
gh label create "eng:task"             --color 0E8A16 --description "レベル: 末端タスク" --force
gh label create "eng:ready"            --color FBCA04 --description "着手可能" --force
gh label create "eng:wip"              --color D4C5F9 --description "進行中" --force
gh label create "eng:waiting-children" --color C5DEF5 --description "子待ち" --force
gh label create "eng:review"           --color FEF2C0 --description "レビュー中" --force
gh label create "eng:stale"            --color E99695 --description "要再確認" --force
gh label create "eng:dropped"          --color 555555 --description "中止" --force
```

2. `.gitignore` に `.engineering/` を追記する（すでにあれば何もしない）
3. `.github/ISSUE_TEMPLATE/node.md` を作成する（内容は `operations/claude/ai-devguide-flow.md` の §Issue テンプレート）
4. `.claude/commands/setup.md` を作成する（内容: このファイルをコピー）
5. `git add -A && git commit -m "chore: ai-devguide フロー初期化" && git push`

**`eng:project` ラベルが存在する場合**：以下の順で現在地を確認する。

1. `gh issue list --label eng:wip` を実行する。
   - Issue がある場合：番号とタイトルを表示し「#N ＜タイトル＞ が進行中です。続きから始めますか？」と確認し、その Issue の工程から再開する。
   - ない場合：次へ。
2. `gh issue list --label eng:review` を実行する。
   - Issue がある場合：「#N ＜タイトル＞ がレビュー待ちです。評価を行いますか？」と確認し、工程5へ。
   - ない場合：次へ。
3. `gh issue list --label eng:ready` を実行する。
   - Issue がある場合：「#N ＜タイトル＞ が着手可能です。これを始めますか？」と確認し、工程4へ。
   - ない場合：次へ。
4. `gh issue list --state open` を実行する。
   - オープンの Issue がある場合：一覧を表示し「どれを進めますか？」と確認する。
   - オープンの Issue が1件もない場合：工程1へ。

---
description: Initialize a project with ai-devguide flow. Creates eng: labels, .gitignore entry, and ISSUE_TEMPLATE.
---

まず `gh --version` を実行し、GitHub CLI の有無を確認する。

**gh が未インストールの場合**：`winget install --id GitHub.cli` を実行してインストールする。インストール後 `gh auth login` を実行し、ブラウザでの認証を案内する。認証完了後、次へ進む。

**gh がインストール済みの場合**：`gh auth status` で認証確認する。未認証なら `gh auth login` を実行して認証する。

---

`gh label list` を実行し、`eng:project` ラベルが存在するか確認する。

**存在する場合**：「このプロジェクトは初期化済みです。」と伝えて終了する。

**存在しない場合（未初期化）**：以下を順番に実行する。

1. `eng:` ラベル9個を作成する（gh が PATH にない場合は `C:\Program Files\GitHub CLI\gh.exe` のフルパスで試す）

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
3. `.github/ISSUE_TEMPLATE/node.md` を作成する（内容は ai-devguide-flow.md の §Issue テンプレート）
4. `git add -A && git commit -m "chore: ai-devguide フロー初期化" && git push`

# ai-devguide フロー命令書

Claude Code がセッション開始時に読む実行指示書。起動するたびに以下のチェックを順番に行い、フローを進めること。

---

## 起動時チェック 1：PC セットアップ済みか

`~/.claude/ai-devguide-flow.md` が存在するか確認する。

**存在しない場合（PC 未設定）**：以下を順番に実行する。

1. `gh --version` を実行する。コマンドが見つからなければ GitHub CLI をインストールする
   - Windows: `winget install --id GitHub.cli`（完了後ターミナルを再起動）
   - macOS: `brew install gh`
   - Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md 参照
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
3. `.github/ISSUE_TEMPLATE/node.md` を作成する（内容は末尾の §Issue テンプレート）
4. `git add -A && git commit -m "chore: ai-devguide フロー初期化" && git push`

**存在する場合**：工程1 へ。

---

## 工程1「問題定義」

出口の成果物：確定した問題定義 = ルートIssue（`eng:project` ラベル）

### 新規プロジェクトの場合

1. 人間に問いかける：「ゴールは何ですか？新規プロジェクトですか、既存ですか？」
2. 人間が「新規」＋ゴールを述べる
3. `.engineering/` フォルダと `current.md` を作成する（`.gitignore` 済みなのでコミット不要）
4. 問題定義の叩き台を作る（ゴール・入力と出力・完了条件・背景・制約）
5. 叩き台を人間に見せ承認を求める ← **承認ゲート**
6. 承認されたらルートIssueを作成する：
   ```bash
   gh issue create --label "eng:project" --title "<ゴール>" --body "<問題定義節を埋めたIssue本文>"
   ```
7. 工程2 へ

### 既存プロジェクトの場合

1. 人間に問いかける：「ゴールは何ですか？新規プロジェクトですか、既存ですか？」
2. 人間が「既存＝AI開発へ移行する」と宣言する
3. `.engineering/` フォルダと `current.md` を作成する
4. コード・README・`git log` を調査して現状を要約する
5. 人間に要約を見せ確認・補足を求める
6. 要約を踏まえ問題定義の叩き台を作る
7. 叩き台を人間に見せ承認を求める ← **承認ゲート**
8. 承認されたらルートIssueを作成する
9. 工程2 へ

---

## 工程2「手法選定」

出口の成果物：手法選定節（Issue に記録）

1. ルートIssueの問題定義節（ゴール・完了条件）を読む
2. 解き方に選択肢があるか判断する
   - **選択肢なし（一択）**：手法選定節に「該当なし（一択）」と書き、工程3 へ
   - **選択肢あり**：候補を比較し（精度・速度・コスト・拡張性）、選定案と「なぜそれか」を出す → 人間に見せ承認を求める ← **承認ゲート**
3. 承認されたら手法選定節を Issue に書き込む
4. 工程3 へ

---

## 工程3「設計（分解）」

出口の成果物：設計（分解）節 ＋ 子Issue（分解する場合）

1. 問題定義節・手法選定節を読む
2. 分解が必要か判断する
   - **末端・自明**：設計節に「末端ノード」と書き、工程4 へ
   - **分解必要**：分解案・理由・子の依存（どの子が他の子の完了を前提にするか）を出す → 人間に見せ承認を求める ← **承認ゲート**
3. 承認されたら：
   - 設計節を親Issueに書き込む
   - 子Issueを作成する：`gh issue create --label "eng:task" --title "<子のゴール>" --body "<Issue本文>"`
   - 依存関係に従い着手できる子に `eng:ready` を付ける：`gh issue edit <ID> --add-label "eng:ready"`
   - 親Issueに `eng:waiting-children` を付ける：`gh issue edit <親ID> --add-label "eng:waiting-children"`
4. 各子Issueに対し工程1 から繰り返す

---

## 工程4「実装」

出口の成果物：PR

1. IssueのラベルをReadyから `eng:wip` に切り替える：
   ```bash
   gh issue edit <ID> --remove-label "eng:ready" --add-label "eng:wip"
   ```
2. 実装節に方針を書く
3. ブランチを切る：`git checkout -b feature/<Issue番号>-<短いタイトル>`
4. 実装する
5. PRを作成する：
   ```bash
   gh pr create --title "<タイトル>" --body "closes #<Issue番号>" --label "eng:review"
   ```
6. 工程5 へ

---

## 工程5「評価」

出口の成果物：評価節 ＋ マージ or 差し戻し

1. 問題定義節の完了条件を読む
2. 評価を実行し評価節に記録する（完了条件の判定・方針の妥当性・補助点検）
3. PR と評価結果を人間に見せ承認を求める ← **承認ゲート**
4. **承認（合格）**：
   ```bash
   gh pr merge <PR番号> --merge
   gh issue close <Issue番号>
   gh issue edit <Issue番号> --remove-label "eng:wip" --remove-label "eng:review"
   ```
   親Issueの全子が完了なら親の評価へ（工程5 を繰り返す）
5. **差し戻し（不合格）**：
   ```bash
   gh issue edit <Issue番号> --remove-label "eng:review" --add-label "eng:wip"
   ```
   差し戻し先の工程に戻る

---

## §Issue テンプレート

`.github/ISSUE_TEMPLATE/node.md` に書き込む内容：

```markdown
---
name: ノード（Issue）
about: このフローの1ノード。最初から全節を持ち、各工程は自分の節を埋めるだけ。
title: "[task] "
labels: []
---

<!--
1ノード＝1 Issue。下の全節を最初から持つ。各工程は自分の節を「埋める」だけで、節を作り足さない。
通らなかった工程の節は空欄で放置せず「該当なし」と書く（例: 解き方が一択なら手法選定節＝「該当なし（一択）」）。
レベルは Issue のラベル eng:project / eng:feature / eng:task で示す。
-->

## 問題定義節（工程1・必須）

- **親**: #<親Issue番号／ルートなら「なし」>
- **ゴール**: <このノードで達成すること。1〜2文>
- **入力・出力**: <何を受け取り、何を返すか>
- **完了条件**（チェック可能な形で・**開始時に決める**）:
  - [ ] <条件1>
  - [ ] <条件2>
- **背景・理由**: <なぜこのゴール・完了条件にしたか。方針のブレ防止のため必ず残す>
- **制約**: <守るべき条件／なければ「該当なし」>

## 手法選定節（工程2・選択肢がある時のみ）

- **比較**: <候補 × 評価軸（精度／速度／コスト／拡張性 など）の表。なければ「該当なし（一択）」>

  | 候補 | 精度 | 速度 | コスト | 拡張性 |
  |---|---|---|---|---|
  |  |  |  |  |  |

- **選定**: <採用した手法>
- **選定理由**: <なぜそれを選んだか。却下案の理由も簡潔に>

## 設計（分解）節（工程3・分解する時のみ）

- **構造**: <選んだ手法でこのノードをどう解くかの全体像>
- **子の一覧**:
  - #<子ID> <ゴール>
- **子の依存**: <例: #12 は #11 の完了が前提／独立なら「なし」>
- **分解の理由**: <なぜこの分割にしたか>

## 実装節（工程4・末端タスク）

- **変えたもの**: <どのファイル・関数を、どう変えたか>
- **採った手法と理由**: <工程2で選んだ手法をどう実装したか>
- **完了条件への対応**: <工程1の各完了条件に「これで満たす」を対応づけ>
- **プルリクエスト**: #<PR番号>

## 評価節（工程5）

- **完了条件の判定**（verification）:

  | 完了条件 | 満たす/満たさない | 根拠 |
  |---|---|---|
  |  |  |  |

- **方針の妥当性**（validation）: <問題設定・手法は正しかったか>
- **補助点検**: <完了条件外の品質点検>
- **統合評価（親のみ）**: <子の集合で親の完了条件を満たすか>
- **判定**: <合格＝マージ・完了／不合格＝差し戻し先（工程N）／中止>
```

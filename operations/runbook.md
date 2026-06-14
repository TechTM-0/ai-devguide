# 実運用手順書（runbook・B-3）

各工程ステップ（flow-spec の 1-1〜5-4）で **Claude Code が自分のターン内に叩く `gh`／`git` コマンド列**。
状態の持ち方・ラベルは `README.md` を参照（ラベル中心）。

> 記法: `#N`＝対象IssueのIssue番号。`<...>` は埋める値。コマンドは対象リポジトリのルートで実行。
> 木の正本＝各Issue本文の「親: #N」＋レベルラベル。sub-issue の視覚連結（任意）は各所に「視覚用」と注記。

---

## 人間が現在地を確認する方法

このフローで人間が判断・行動するのは決まった4か所だけ。それ以外はAIが進める。

### 自分の番かどうかをラベルで判断する

| ラベルの状態 | 意味 | 人間がすること |
|---|---|---|
| `eng:wip`（会話中に止まる） | AIが作業中。**承認ゲート**が来たら止まって聞いてくる | 会話を見て承認または修正を返す |
| `eng:review` | CIが終わり最終判断（Go/No-go）待ち | CIの緑/赤とデモを見て判断する |
| `eng:ready` / `eng:waiting-children` | AIが自動で処理中 | 見なくていい |

**承認ゲート**（`eng:wip` の中でAIが止まって聞いてくる4か所）：
- **工程1-5**: 問題定義の承認（「この問題設定でいいですか？」）
- **工程2-2**: 手法の承認（「この解き方でいいですか？」）
- **工程3-2**: 分解の承認（「この分け方でいいですか？」）
- **工程5-3**: Go/No-go（「CIが緑です。マージしますか？」）← `eng:review` が目印

### 今の状態を1コマンドで確認する

```bash
# 自分の判断が必要なIssue（eng:review = 最終Go/No-go待ち）
gh issue list --label "eng:review" --state open

# AIが今作業中のIssue
gh issue list --label "eng:wip" --state open

# 次にAIが着手するIssue
gh issue list --label "eng:ready" --state open
```

### `.engineering/current.md` で今何をしているか見る

AIは各ステップ後に `.engineering/current.md` を更新する。**セッション外でも「今どこか」はここを見れば分かる**。
ファイルには必ず次の3項目を含む：

```
現在のノード : #N「タイトル」
現在の工程   : X-Y（すること）
人間の次のアクション: なし（AIが進めます）
                  / 承認待ち（何を承認するか）
                  / Go/No-go待ち（何を判断するか）
```

---

## 工程1 問題定義（**新規 / 既存で入口が違う**）

工程1は**人間との対話で問題定義を固める**段。`gh` コマンドが要るのは最後（ルートIssue作成）だけ。
その手前の「促し → 叩き台 → **人間の承認ゲート**」を飛ばさない。ここを飛ばすと記録が“促し”に戻り目的が死ぬ。
ステップは flow-spec 工程1 と1対1（新規=1-1〜1-6／既存=1-1〜1-8）。

### 新規プロジェクト

| ステップ | 担当 | すること | コマンド |
|---|---|---|---|
| 1-1 | AI | 開始を検知し促す：「ゴールは？／新規か既存か？」 | － |
| 1-2 | 人間 | 「新規」＋ゴールを述べる | － |
| 1-3 | AI | ローカル記録場所（薄いポインタ）を用意。**未初期化リポジトリなら先に README §初期化手順（B-1）を実施**（ラベル・gitignore・Issueテンプレ） | `mkdir -p .engineering`（current.md/log.md） |
| 1-4 | AI | 問題定義の叩き台を作る（ゴール／入力・出力／完了条件／制約）＝チャット。**まだIssue化しない** | － |
| 1-5 | 人間 | 叩き台を承認 or 修正指示（**承認ゲート**） | 修正 → 1-4 へ戻る |
| 1-6 | AI | 確定した問題定義をルートIssueに記録（下のコマンド） | ↓ |

```bash
# 1-6: テンプレに沿って本文を書いた node-body.md を用意して
gh issue create --title "[project] <ゴール>" --label "eng:project" --body-file node-body.md
# => 採番された #N が返る。着手するなら状態を進行中へ
gh issue edit <#N> --add-label "eng:wip"
```

### 既存プロジェクト（AI開発へ移行）

新規との違いは **1-4「現状調査・要約」＋1-5「人間が確認」が挟まる**ことだけ（flow-spec 既存1-4/1-5）。

| ステップ | 担当 | すること | コマンド |
|---|---|---|---|
| 1-1 | AI | 同上の促し | － |
| 1-2 | 人間 | 「既存＝AI開発へ移行する」と宣言 | － |
| 1-3 | AI | 記録場所を用意（既存リポジトリを基盤に。B-1未実施なら先に実施） | `mkdir -p .engineering` |
| 1-4 | AI | コード・README・`git log` を調査して現状を要約（チャット）＝**既存だけの追加段** | （読むだけ） |
| 1-5 | 人間 | 要約を確認・補足 | － |
| 1-6 | AI | 要約を踏まえ問題定義の叩き台（チャット・まだIssue化しない） | － |
| 1-7 | 人間 | 叩き台を承認 or 修正指示（**承認ゲート**） | 修正 → 1-6 へ戻る |
| 1-8 | AI | 確定した問題定義をルートIssueに記録 | 新規1-6と同じ `gh issue create` |

> レベルに応じて `eng:project` / `eng:feature` / `eng:task`。子ノードの問題定義（再帰）も同じ1-4〜1-6だが、1-1〜1-3の入口（新規/既存判定・記録場所用意）は**ルートで1度だけ**通る。

## 工程2 手法選定（2-1 → 2-2 承認）

選択肢があるときだけ通る（条件付き工程）。

| ステップ | 担当 | すること | コマンド |
|---|---|---|---|
| 2-1 | AI | 解き方に選択肢があるか判断。あれば候補を比較（精度／速度／コスト／拡張性）し、選定案＋理由を**手法選定節**に書く | ↓ |
| 2-2 | 人間 | 比較と選定理由を確認（**承認ゲート**） | 承認 → 工程3／修正 → 2-1 |

```bash
# 2-1: Issue本文を全節そのままに、手法選定節だけ埋めて上書き
gh issue view <#N> --json body -q .body > node-body.md   # 現本文を取得
# node-body.md の「手法選定節」を編集して
gh issue edit <#N> --body-file node-body.md
```

選択肢が無ければ本文の手法選定節に「該当なし（一択）」と書いて工程2を素通り（2-2 も無し）。

---

## 工程3 設計（分解）

### 3-1 分解案を作る（AI）
このノードに分解が必要か判断。必要なら採用手法に沿った**分解案＋理由＋子同士の依存**を、本文の**設計（分解）節**に書く。

```bash
gh issue view <#N> --json body -q .body > node-body.md   # 現本文を取得
# 「設計（分解）節」の 構造／子の一覧／子の依存／分解の理由 を埋めて
gh issue edit <#N> --body-file node-body.md
```

分解が不要（末端／自明）なら工程4へ。

### 3-2 分解案を承認（人間・**承認ゲート**）
人間が分解案・理由・依存を確認。修正 → 3-1 へ／承認 → 3-3 へ。

### 3-3 親ブランチ・子Issue・ready を作る（AI）

**順序が重要**（flow-spec 3-3）。①循環確認 → ②親featureブランチ作成push → ③子の振り分け → ④依存無し末端を ready。

#### ① 子の依存が循環していないか（DAG）を確認
本文「子の依存」を見て一方向か確かめる。循環していたら 3-1 へ戻り分解し直す（コマンド無し＝判断）。

#### ② 親 feature ブランチを「親ノードのブランチ」から切って push
子が工程4-1で分岐する土台を**先に**用意する（無いと子が迷子になる）。

```bash
git fetch origin
git switch <親ノードのブランチ>          # 最上位featureなら main
git switch -c "feature/<#N>-<slug>"      # 例 feature/10-login
git push -u origin "feature/<#N>-<slug>"
```

#### ③ 親を「子待ち」にして、子Issueを作る

```bash
# 親の状態: 進行中 → 子待ち
gh issue edit <#N> --remove-label "eng:wip" --add-label "eng:waiting-children"

# 非自明な子（本文に「親: #N」を必ず書く＝木の正本）
gh issue create --title "[task] <子のゴール>" --label "eng:task" --body-file child-body.md
# （任意・視覚用）sub-issue 連結。拡張を入れている場合のみ
gh sub-issue add <#N> <#子>
```

- **自明な子**は Issue にせず、親本文の「子の一覧」にチェックリスト `- [ ]` で残す（Issueを乱立させない）。
- 1ノードの子は5〜7個まで。超えるなら中間ノードを1段挟む。

#### ④ 依存の無い末端の子を ready にする

```bash
gh issue edit <#子> --add-label "eng:ready"
```

> **ready の判定（毎回考えない・状態照合だけ）**: ①未着手 ②親が子待ち ③依存兄弟が全完了。判定するのは2イベントだけ＝**子を作った時（ここ）** と **ノード完了時（5-4）**。木全体は走査しない。
> **次の仕事を取る**: `gh issue list --label "eng:ready" --state open` から1つ。

---

## 工程4 実装（末端タスク／親の自明項目）

### 4-1 ready から1件取り、作業ブランチを切る

```bash
gh issue edit <#N> --remove-label "eng:ready" --add-label "eng:wip"
git fetch origin
git switch "feature/<親#>-<slug>"        # 親featureブランチ＝この子のベース
git switch -c "task/<#N>-<slug>"
```

### 4-2 実装する（手法選定節に従う）

```bash
git add -A
git commit -m "<#N> <何をしたか>"
```

詰まりは原因の層へ：手法では解けない→工程2／分割が悪い→工程3／問題設定が誤り→工程1／やり方レベル→ここで対処。
**自明チェックリスト項目もここで実装する（チェックはまだ入れない＝確認は工程5）。**

### 4-3 ローカル自己点検 → push → PR（レビュー依頼）

```bash
# ローカルでテスト/ビルド/起動して壊れていないか（軽い自己点検）
git push -u origin "task/<#N>-<slug>"
gh pr create --base "feature/<親#>-<slug>" \
  --title "<#N> <ゴール>" \
  --body "Closes #<N>

## 実装節
- 変えたもの: ...
- 採った手法と理由: ...
- 完了条件への対応: ...
"
```

`Closes #N` を入れておくと**マージ時にIssueが自動でclose＝完了**になる。
状態は `eng:wip` のまま（＝CI待ち。PRのチェック実行中であることは `gh pr checks` で分かる）。
**マージはここでしない**（本評価とマージ可否は工程5）。

---

## 工程5 評価

### 5-1 CIで verification（末端）／統合評価（親）

```bash
# 末端: CIの緑/赤を待つ
gh pr checks <PR番号> --watch
```

- **CI赤** → 工程4へ戻して直す（`task/...` ブランチに追加commit→push、`eng:wip` のまま）。
- **CI緑** → レビュー中へ：

  ```bash
  gh issue edit <#N> --remove-label "eng:wip" --add-label "eng:review"
  ```

- **親（子が全部完了）** → コード無しなのでCIを通らず、本文「統合評価」を埋めて：

  ```bash
  gh issue edit <親#> --remove-label "eng:waiting-children" --add-label "eng:review"
  ```

### 5-2 AIが validation＋補助点検
本文「方針の妥当性」「補助点検」を埋める（`gh issue edit <#N> --body-file ...`）。

### 5-3 人間が Go / No-go
人間が見るのは **CIの緑/赤 ＋ 動かした結果のデモ ＋ 評価節**（コードは読まない）。
No-go の差し戻しは「お片付け」へ。

### 5-4 Go → マージ（1個ずつ直列化）→ ready 付け替え

```bash
# マージキュー有効なら --auto でキュー投入（合体後にCI再実行）。依存される子を先にマージ
gh pr merge <PR番号> --merge --auto
# Closes #N により Issue は自動close＝完了。review ラベルを外す
gh issue edit <#N> --remove-label "eng:review"
```

- **この完了で依存が解けた兄弟を ready にする**（隣だけ見る）：

  ```bash
  gh issue edit <#兄弟> --add-label "eng:ready"
  ```

- **マージで衝突** → 進行中へ戻し、AIが両Issueの意図（完了条件）を読んで解決→push→CIやり直し（専用状態は無し）：

  ```bash
  gh issue edit <#N> --add-label "eng:wip" --remove-label "eng:review"
  ```

- **親があり子が全部完了** → 親が 5-1 の統合評価へ（上の親の遷移）。
- **最上位featureの統合評価が通った** → feature を main へマージ。

---

## 差し戻し・stale 時の停止とお片付け

上流へ戻る（stale／5-3 No-go）とき、放置した作業が古い前提でトークンを浪費し再開時に自爆するのを防ぐ。

### (1) 実行中プロセス・CIの即停止
配下で動いている子孫も即 stale にし、走行中CIを止める。

```bash
gh issue edit <#N> --add-label "eng:stale" --remove-label "eng:wip,eng:review,eng:waiting-children"
gh run list --branch "task/<#N>-<slug>" --json databaseId -q '.[].databaseId' | xargs -r -n1 gh run cancel
```

### (2) お片付け（差し戻し・stale が確定したら）

```bash
# ① PR: マージせずクローズ（履歴は残す＝削除しない）
gh pr close <PR番号>

# ② ブランチ: 失敗ブランチを -failed で退避（再開は新しい前提で切り直す。古いブランチでは再開しない）
git branch -m "task/<#N>-<slug>" "task/<#N>-<slug>-failed"
git push origin ":task/<#N>-<slug>"                       # 元のリモートブランチを削除
git push -u origin "task/<#N>-<slug>-failed"

# ③ 子Issue: 戻る先で分ける
#   (a) 実装だけやり直す（問題定義は生きている）→ Issue再利用・該当節を stale にして埋め直す
#   (b) 分解そのものをやり直す（工程3-1へ）→ 古い未着手の子を中止クローズ＋新Issueに supersedes リンク
gh issue close <#旧子> --reason "not planned" --comment "分解やり直しのため中止。後継: #<新子>"
gh issue create --title "[task] <新ゴール>" --label "eng:task" \
  --body "親: #<親>
supersedes #<旧子>

（問題定義節 ...）"
```

---

## 中止（解く価値が無い・打ち切り）

validation で「価値なし」と分かった時、または**人間が中止を指示した時**。進行中／子待ち／CI待ち／レビュー中の**どの状態からでも**起きる終端遷移（flow-spec 状態設計）。
差し戻しと違い上流に戻らず**そのまま閉じる**。配下の実行中プロセス・CIは「お片付け (1)」と同じ手順で止め、PR・ブランチは「お片付け (2)①②」で退避する。

```bash
# 配下の実行中CIを止めてから、中止としてクローズ（完了と区別するため eng:dropped を付ける）
gh issue edit <#N> --add-label "eng:dropped" --remove-label "eng:wip,eng:review,eng:waiting-children,eng:ready"
gh issue close <#N> --reason "not planned" --comment "中止: <理由＝価値なし／ユーザー指示>"
```

> 完了（merged で close）と中止（`eng:dropped` で close）はどちらも closed だが、ラベルで区別できる。記録は残す（削除しない）。

---

## デッドロック（循環依存）検知の保険

予防は 3-3 の DAG 確認が主。保険として、次が**同時に成り立ったら**デッドロックとみなし、親を stale にして 3-1 へ差し戻す。

- 実行中ノードがゼロ：`gh issue list --label "eng:wip" --state open` と `eng:review` `eng:waiting-children` が**全て空**
- ready が空：`gh issue list --label "eng:ready" --state open` が空
- 未完了ノードが残っている：open の Issue がまだある

> 「ready空」だけでは誤検知する（全員が実行中でも ready は空）。必ず「実行中ゼロ」と**組で**判定する。

# 実運用キット（operations/）

`flow-spec.md` で確定した設計を、**Claude Code が `gh`／`git` で実際に実行できる形**にした道具一式。
リポジトリ1つを「このフロー対応」にするための初期化手順・テンプレ・手順書をここに置く。

> 用語は `[日本語の意味（english）]` 併記（RULES.md §7）。
> 状態の持ち方＝**ラベル中心**（決定: log 2026/06/14）。Projects ボードは人間用の可視化として後から足せる任意のオプション。

## 中身

| ファイル | 役割 | flow-spec の対応 |
|---|---|---|
| `README.md`（本書） | キット概要＋**初期化手順（B-1）**＋ラベル定義 | 実運用（git・GitHub）/ 実行環境 |
| `github/ISSUE_TEMPLATE/node.md` | **ノード記録テンプレ（B-2）**。Issueが最初から全節を持つ | ノードの記録（Issue本文）の全体テンプレート |
| `runbook.md` | **実運用手順書（B-3）**。各工程ステップで叩く `gh`／`git` コマンド列 | 工程1〜5・お片付け |
| `github/workflows/ci.example.yml` | **CIワークフロー例（B-4）**。技術はノード毎なので雛形＋差し替え方 | 工程5 verification＝GitHub CI |

`github/` 配下は**対象リポジトリの `.github/` にコピーして使う雛形**。AiRule 自身に適用するものではない。

---

## 状態の表現（ラベル中心）

flow-spec の状態8語彙と ready を、ラベルと Issue の open/closed だけで一意に表す。
**AIはこのラベルの照合だけで「次の仕事（ready）」と「各ノードの状態」を判定できる**（推論不要）。

| 状態（flow-spec） | GitHub上の表現 |
|---|---|
| 未着手 | open ＋ 状態ラベル無し（依存が解けていれば `eng:ready` が付く） |
| 進行中 | open ＋ `eng:wip` |
| CI待ち | open ＋ `eng:wip` ＋ 紐づくPRがopenでチェック実行中（`gh pr checks` で判定・**専用ラベルは置かない**） |
| 子待ち | open ＋ `eng:waiting-children`（分解した親だけが取る） |
| レビュー中 | open ＋ `eng:review`（人間のGo/No-go待ち） |
| 完了 | **closed** ＋ 紐づくPRが merged |
| 中止 | **closed** ＋ `eng:dropped` |
| stale（要再確認） | `eng:stale`（open/closed どちらにも付きうる） |

> 状態ラベルは**1ノードに高々1つ**（`eng:ready`／`eng:wip`／`eng:waiting-children`／`eng:review` は排他）。`eng:stale` だけは上の上に重なる印。

---

## ラベル定義

| ラベル | 意味 | 色 | 種別 |
|---|---|---|---|
| `eng:project` | レベル＝プロジェクト（大きさの目印） | `6F42C1` | レベル |
| `eng:feature` | レベル＝フィーチャー | `1D76DB` | レベル |
| `eng:task` | レベル＝末端タスク | `0E8A16` | レベル |
| `eng:ready` | いま着手できる（親分解済み＋依存兄弟が全完了） | `FBCA04` | キュー |
| `eng:wip` | 進行中（工程1〜4を実行中／CI待ちを含む） | `D4C5F9` | 状態 |
| `eng:waiting-children` | 子待ち（子が全部完了するのを親が待つ） | `C5DEF5` | 状態 |
| `eng:review` | レビュー中（人間のGo/No-go待ち） | `FEF2C0` | 状態 |
| `eng:stale` | 要再確認（上流が変わり前提が崩れた） | `E99695` | 印 |
| `eng:dropped` | 中止（解く価値が無い等で打ち切り・closedに付ける） | `555555` | 印 |

---

## 前提条件（初回のみ・PC共通）

このキットは GitHub CLI（`gh`）を使う。リポジトリ初期化の前に1度だけ確認する。

### GitHub CLI のインストールと認証

```bash
# インストール済みか確認
gh --version
```

入っていなければインストール：

| OS | コマンド |
|---|---|
| Windows | `winget install --id GitHub.cli` （完了後ターミナルを再起動） |
| macOS | `brew install gh` |
| Linux | [https://github.com/cli/cli/blob/trunk/docs/install_linux.md](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) を参照 |

認証（ブラウザが開くのでワンタイムコードを承認する）：

```bash
gh auth login
# GitHub.com → HTTPS → Login with a web browser の順に選ぶ
```

確認：

```bash
gh auth status
# ✓ Logged in to github.com account <username> と出ればOK
```

> この前提条件は **PC 単位で1回だけ**。2本目以降のリポジトリ初期化では不要。

---

## 初期化手順（B-1：リポジトリを1本でフロー対応にする）

対象リポジトリのルートで、Claude Code が以下を実行する。`gh auth status` でログイン済みが前提。

### 1. ラベルを作る

```bash
# レベル
gh label create "eng:project"          --color 6F42C1 --description "レベル: プロジェクト" --force
gh label create "eng:feature"          --color 1D76DB --description "レベル: フィーチャー" --force
gh label create "eng:task"             --color 0E8A16 --description "レベル: 末端タスク" --force
# キュー・状態・印
gh label create "eng:ready"            --color FBCA04 --description "着手可能（親分解済+依存完了）" --force
gh label create "eng:wip"              --color D4C5F9 --description "進行中（CI待ちを含む）" --force
gh label create "eng:waiting-children" --color C5DEF5 --description "子待ち（親が子完了を待つ）" --force
gh label create "eng:review"           --color FEF2C0 --description "レビュー中（人間のGo/No-go待ち）" --force
gh label create "eng:stale"            --color E99695 --description "要再確認（上流変更で前提崩れ）" --force
gh label create "eng:dropped"          --color 555555 --description "中止（打ち切り）" --force
```

### 2. ローカル記録を git から隔離する

```bash
# .engineering/ は薄いポインタ＝リポジトリを汚さないため追跡しない
grep -qxF '.engineering/' .gitignore 2>/dev/null || echo '.engineering/' >> .gitignore
```

### 3. Issueテンプレートを置く

```bash
mkdir -p .github/ISSUE_TEMPLATE
cp <このキット>/github/ISSUE_TEMPLATE/node.md .github/ISSUE_TEMPLATE/node.md
```

### 4.（任意）sub-issue の視覚ネストを使うなら拡張を入れる

GitHub の sub-issue 連結は `gh` ネイティブ未対応のため、使うなら拡張を入れる。
**入れなくてもフローは動く**（木の正本は各Issue本文の「親: #N」＋レベルラベル）。

```bash
gh extension install yahsan2/gh-sub-issue   # 任意。視覚的な入れ子表示のためだけ
```

### 5.（任意・オプトイン）CIを必須ゲート＋マージキューにする

既定では CI の緑/赤は**人間が見る信号**で、マージは止めない（無害）。
「緑じゃないとマージ不可」「マージは1個ずつ直列化」を**望んだ時だけ**有効にする。

1. `github/workflows/ci.example.yml` を `.github/workflows/ci.yml` にコピーし、テスト手順を対象リポジトリの技術に差し替える。
   **`merge_group` トリガは消さない**（マージキュー内で必須チェックが回るのに必要）。
2. 対象ブランチ（例 `main`）に branch protection / ruleset で次を有効化：
   - Require status checks to pass（このCIを必須に）
   - **Require merge queue**（マージを1個ずつ直列化）
3. これで工程5の「CI緑が必須」「マージキューで直列化」が機械的に効く。

> 設定を入れない限り、本キットは既存リポジトリの挙動を変えない（隔離優先）。

---

## まだ設定時に確認するだけの細目

- **sub-issue の実ネスト段数上限**：表示の入れ子が何段まで効くか（データ＝親リンクには影響なし）。深い木は本文リンクで常に表現できるので、表示が浅くても問題ない。
- **ready キューを Projects 列に変えるか**：本キットはラベル中心。人間用ボードが欲しくなったら Projects を足す（段階深化）。

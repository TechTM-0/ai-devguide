# ai-devguide プラグイン インストール手順

## 前提条件

- Claude Code がインストール済み

## 手順

### 1. マーケットプレイスを登録（初回のみ）

Claude Code 上で実行：

```
/plugin marketplace add TechTM-0/ai-devguide
```

### 2. プラグインをインストール

```
/plugin marketplace update
```

表示されるメニューを以下の順に選択：

1. `ai-devguide` を選択
2. `Browse plugins (1)` を選択
3. `ai-devguide` を選択
4. `Install for you (user scope)` を選択

### 3. 反映

```
/reload-plugins
```

## 確認

任意のプロジェクトで Claude Code を起動し、以下を実行：

```
/ai-devguide:setup
```

プロジェクト初期化フローが開始されれば成功。

> **注意**: `/ai-devguide:setup` の実行には `gh` CLI と GitHub アカウントが必要です。

## 備考

- user scope でインストールするため、PC上の全プロジェクトで使用可能
- マーケットプレイス登録（手順1）は1回のみ実施すればよい
- Claude Code のバージョンアップ後にスキルが消えた場合は手順2〜3を再実行

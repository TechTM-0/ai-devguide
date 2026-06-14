#!/usr/bin/env bash
# ============================================================================
# check-spec-coverage.sh
#   設計の正本 flow-spec.md に対して、実運用キット operations/ が
#   全要素を覆っているかを「目視せず機械的に」照合する評価器。
#
#   なぜ要るか: 「実運用キットが設計どおりか」をAIの自己申告や人間の通し読みに
#   頼ると抜けに気づけない（新規フローの脱落がまさにそれだった）。ここで
#   ステップ・状態・記録節の被覆を機械チェックし、抜けを MISS として出す。
#
#   置き場: AiRule の保守用ツール。対象リポジトリには配らない（キットの一部ではない）。
#   使い方: AiRule のルートで  bash check-spec-coverage.sh
#   終了コード: 全被覆=0 / 抜けあり=1
# ============================================================================
set -u

SPEC="flow-spec.md"
RUNBOOK="operations/runbook.md"
README="operations/README.md"
TEMPLATE="operations/github/ISSUE_TEMPLATE/node.md"

fail=0
miss() { echo "  MISS  $1"; fail=1; }
ok()   { echo "  ok    $1"; }

echo "== 1. 工程ステップの被覆（flow-spec の N-M → runbook.md） =="
# flow-spec の手順表セル「| 1-1 |」等から正本のステップID集合を抽出
steps=$(grep -oE '\|[[:space:]]*[1-5]-[0-9]+[[:space:]]*\|' "$SPEC" \
        | grep -oE '[1-5]-[0-9]+' | sort -u)
for s in $steps; do
  # runbook 側で「表セル | 1-1 |」または「見出し ### 1-1」として出ているか
  if grep -qE "(\|[[:space:]]*${s}[[:space:]]*\||#{2,4}[[:space:]]+${s}([[:space:]]|:|$))" "$RUNBOOK"; then
    ok "$s"
  else
    miss "$s  ← runbook に手順が無い"
  fi
done

echo
echo "== 2. 状態8語彙の被覆（flow-spec → README の状態写像表） =="
for st in 未着手 進行中 子待ち CI待ち レビュー中 完了 中止 stale; do
  if grep -qF "$st" "$README"; then ok "$st"; else miss "$st  ← README の状態写像に無い"; fi
done

echo
echo "== 3a. 未定義ラベルの検出（runbook で使う eng:ラベル → README で定義済みか） =="
used=$(grep -oE 'eng:[a-z-]+' "$RUNBOOK" | sort -u)
for l in $used; do
  if grep -qF "$l" "$README"; then ok "$l"; else miss "$l  ← README に定義が無い"; fi
done

echo
echo "== 3b. 手順の欠落検出（README で定義した eng:ラベル → runbook に手順があるか） =="
# 定義したのに runbook で一度も使われないラベル＝その状態の手順が抜けている疑い
defined=$(grep -oE 'eng:[a-z-]+' "$README" | sort -u)
for l in $defined; do
  if grep -qF "$l" "$RUNBOOK"; then ok "$l"; else miss "$l  ← この状態に遷移する手順が runbook に無い"; fi
done

echo
echo "== 4. 記録テンプレの節の被覆（flow-spec の節 → Issueテンプレ node.md） =="
for sec in 問題定義節 手法選定節 "設計（分解）節" 実装節 評価節; do
  if grep -qF "$sec" "$TEMPLATE"; then ok "$sec"; else miss "$sec  ← Issueテンプレに無い"; fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "RESULT: PASS — operations/ は flow-spec の全要素を覆っている"
else
  echo "RESULT: FAIL — 上の MISS が設計に対する被覆の穴。埋めるまで『できた』と言わない"
fi
exit "$fail"

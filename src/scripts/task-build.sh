#!/usr/bin/env bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .claude/scripts/lib-state.sh
TF=".ai/task.json"

[ -f "$TF" ] || { echo "无活动任务，先 /lock。" >&2; exit 1; }
[ "$(state_get_stage "$TF")" = "PLAN" ] || { echo "当前非 PLAN 阶段，无需 /build。" >&2; exit 1; }

CONFIRM=0
[ "${1:-}" = "--confirm" ] && CONFIRM=1

# pre_committed: 检测 draft/ 有文件（.gitkeep 不算）
PRE=0
if ls .ai/memory/draft/* 2>/dev/null | grep -qv '\.gitkeep'; then PRE=1; fi

MISSING=""
[ "$CONFIRM" = 1 ] || MISSING="plan_confirmed(加 --confirm 确认计划)"
[ "$PRE" = 1 ] || MISSING="$MISSING pre_committed(先在 .ai/memory/draft/ 写前置知识)"

if [ -n "$MISSING" ]; then
  echo "/build 未通过 gate，缺:$MISSING" >&2
  exit 1
fi

state_set_gate "$TF" plan_confirmed true
state_set_gate "$TF" pre_committed true
state_set_stage "$TF" BUILD
echo "stage=BUILD。只能在 allowed/extra 范围内写代码。开发完成用 /close。"

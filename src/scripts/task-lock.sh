#!/usr/bin/env bash
set -euo pipefail
# /lock <paths...>  初始化 task.json，进入 PLAN。
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ "$#" -lt 1 ]; then
  echo "用法: /lock <path1> [path2 ...]   例如 /lock src/pay/refund/" >&2
  exit 1
fi

mkdir -p .ai/memory/draft .ai/memory/active

# 规范化路径前缀：统一正斜杠 + 强制以 / 结尾（目录前缀，guardian 前缀匹配契约）
normalize_prefix() {
  local p="$1"
  p="${p//\\//}"                      # 反斜杠 -> 正斜杠
  while [[ "$p" == */ ]]; do p="${p%/}"; done   # 去所有尾斜杠
  while [[ "$p" == ./* ]]; do p="${p#./}"; done # 去 ./ 前缀
  p="${p#/}"                          # 去开头斜杠
  if [ -z "$p" ]; then
    echo "task-lock: 无效路径 '$1'" >&2
    return 1
  fi
  printf '%s/' "$p"
}

ALLOWED_ARGS=()
for arg in "$@"; do
  if ! norm="$(normalize_prefix "$arg")"; then
    exit 1
  fi
  ALLOWED_ARGS+=("$norm")
done
ALLOWED="$(printf '%s\n' "${ALLOWED_ARGS[@]}" | jq -R . | jq -s .)"

DATE=$(date +%Y%m%d)
SLUG="$(normalize_prefix "$1" | tr -d '/')"
SLUG="${SLUG:0:20}"
TID="TASK-${DATE}-${SLUG}"

jq -n \
  --arg id "$TID" \
  --argjson allowed "$ALLOWED" \
  '{
    task_id: $id, stage: "PLAN", human_owner: "",
    scope: { allowed_paths: $allowed, blocked_paths: [], extra_grants: [] },
    gate: { plan_confirmed: false, pre_committed: false, tests_passed: false, review_done: false, post_committed: false }
  }' > .ai/task.json

echo "已锁定范围: ${ALLOWED_ARGS[*]}"
echo "stage=PLAN。写方案到 .ai/plan/，前置知识到 .ai/memory/draft/。"
echo "确认计划后用 /build 进入 BUILD。"

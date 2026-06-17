#!/usr/bin/env bash
set -uo pipefail
# /extend <path>  把路径追加进 extra_grants，guardian 下次放行。
# 铁律: blocked 路径不可放行（前缀匹配，与 guardian 一致）。
# 不强制尾斜杠规范化: extra_grants 既可能是目录(src/util/)也可能是具体文件
# (src/util/helper.go)，强制加斜杠会让文件前缀匹配失效。路径形式由用户负责。
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .claude/scripts/lib-state.sh
TF=".ai/task.json"

[ -f "$TF" ] || { echo "无活动任务。" >&2; exit 1; }
[ -n "${1:-}" ] || { echo "用法: /extend <path>  (目录带尾斜杠如 src/util/，具体文件如 src/util/helper.go 不带)" >&2; exit 1; }
P="$1"
P="${P//\\//}"   # 反斜杠 -> 正斜杠（Windows 兼容）

# 铁律: blocked 不可放行（前缀匹配，与 guardian 一致）
BLOCKED="$(state_get_scope blocked_paths "$TF")"
while IFS= read -r b; do
  [ -n "$b" ] && [[ "$P" == "$b"* ]] && { echo "/extend 拒绝: $P 在 blocked 硬禁区。" >&2; exit 1; }
done <<< "$BLOCKED"

state_extend "$TF" "$P"
echo "已放行: $P (临时，任务结束随 scope 清空)"

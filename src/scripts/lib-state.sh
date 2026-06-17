#!/usr/bin/env bash
# task.json 读写辅助。所有对 task.json 的访问都经这里，便于统一加日志/校验。
# 注意：guardian 只调用读函数；只有 task-*.sh 调用写函数。

state_get_stage() {  # task_file -> stage
  jq -r '.stage' "$1"
}

state_get_scope() {  # key task_file -> 逐行输出数组元素
  jq -r ".scope.$1[]?" "$2"
}

state_get_gate() {  # key task_file -> true/false
  jq -r ".gate.$1" "$2"
}

state_set_stage() {  # task_file stage  （原地改写）
  local f="$1" s="$2"
  local tmp; tmp="$(mktemp)"
  jq --arg s "$s" '.stage = $s' "$f" > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
}

state_set_gate() {  # task_file key value
  local f="$1" k="$2" v="$3"
  local tmp; tmp="$(mktemp)"
  jq --arg k "$k" --argjson v "$v" '.gate[$k] = $v' "$f" > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
}

state_extend() {  # task_file path  （追加到 extra_grants）
  local f="$1" p="$2"
  local tmp; tmp="$(mktemp)"
  jq --arg p "$p" '.scope.extra_grants += [$p]' "$f" > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
}

state_clear_scope() {  # task_file  （清 allowed/blocked/extra，任务结束用）
  local f="$1"
  local tmp; tmp="$(mktemp)"
  jq '.scope = {allowed_paths:[], blocked_paths:[], extra_grants:[]}' "$f" > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
}

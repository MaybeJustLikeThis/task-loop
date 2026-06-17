#!/usr/bin/env bash
set -uo pipefail
# no -e: 必须在 jq 失败后继续，靠 [-n] 空值检查兜底(fail-closed)
# PreToolUse 守卫。读 stdin JSON，按 task.json 的 stage + scope 拦截写类工具。
# 退出码: 0 放行, 2 阻断(stderr 反馈给 AI)。

TASK_FILE=".ai/task.json"

# 无任务 -> 拦所有写
if [ ! -f "$TASK_FILE" ]; then
  echo "GUARDIAN: 无活动任务，先用 /lock 锁定范围后再写文件。" >&2
  exit 2
fi

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
# fail-closed: 解析不出工具名，阻断
[ -n "$TOOL_NAME" ] || { echo "GUARDIAN: 无法解析工具调用(fail-closed)" >&2; exit 2; }

# 只拦截写类工具，其余放行
case "$TOOL_NAME" in
  Write|Edit|NotebookEdit) ;;
  Bash)
    CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
    STAGE_B="$(jq -r '.stage' "$TASK_FILE")"
    # fail-closed: stage 解析异常时阻断，与 Write 分支对称
    [ -n "$STAGE_B" ] && [ "$STAGE_B" != "null" ] || { echo "GUARDIAN: Bash 阶段解析异常(fail-closed)" >&2; exit 2; }
    # DONE: 放行（scope 已清）
    [ "$STAGE_B" = "DONE" ] && exit 0
    # 检测高危写命令
    if echo "$CMD" | grep -qE '(^|[[:space:]])(rm|mv|cp|tee)([[:space:]]|$)|>|>>|sed[[:space:]].*-i'; then
      # PLAN/CLOSE: 一律拦
      if [ "$STAGE_B" = "PLAN" ] || [ "$STAGE_B" = "CLOSE" ]; then
        echo "GUARDIAN: 当前 $STAGE_B 阶段不允许通过 Bash 改文件。需要写代码请先 /build。" >&2
        exit 2
      fi
      # BUILD: best-effort 检查命令是否疑似触碰 blocked（路径检测不可靠，挡明显情况）
      if [ "$STAGE_B" = "BUILD" ]; then
        BLOCKED_B="$(jq -r '.scope.blocked_paths[]?' "$TASK_FILE")"
        while IFS= read -r b; do
          if [ -n "$b" ] && echo "$CMD" | grep -qF -- "$b"; then
            echo "GUARDIAN: BUILD 阶段 Bash 命令疑似触碰 blocked($b)，拒绝（Bash 路径检测不可靠，此为 best-effort）。" >&2
            exit 2
          fi
        done <<< "$BLOCKED_B"
      fi
    fi
    exit 0 ;;
  *)     exit 0 ;;
esac

# 目标路径（Write/Edit 用 file_path，Notebook 用 notebook_path）
TARGET="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
# fail-closed: 写类工具但读不到目标路径，阻断
[ -n "$TARGET" ] || { echo "GUARDIAN: 无法解析写入目标(fail-closed)" >&2; exit 2; }
# 统一为正斜杠（防御 Windows 反斜杠路径绕过命门）
TARGET="${TARGET//\\//}"
# 绝对路径 -> 相对项目根。Windows 上 Claude Code 给的是盘符绝对路径
# (如 D:/Mycase/.../x.go)，而 $PWD 在 MSYS/Git Bash 里是 POSIX 形式
# (/d/Mycase/...)。两种根前缀都要剥一次，否则整路径漏判。
# WINROOT = 盘符 mixed 形式(正斜杠)：/d/Mycase -> D:/Mycase
WINROOT="$PWD"
if command -v cygpath >/dev/null 2>&1; then
  WINROOT="$(cygpath -m "$PWD" 2>/dev/null || echo "$PWD")"
fi
REL="$TARGET"
REL="${REL#"$PWD"/}"
REL="${REL#"$WINROOT"/}"
REL="${REL:-$TARGET}"

# 命门：task.json 对 AI 永远只读
case "$REL" in
  .ai/task.json|*/task.json)
    echo "GUARDIAN: .ai/task.json 是系统状态文件，AI 不可修改。" >&2
    exit 2 ;;
esac

# Task 4: stage 分支（PLAN/BUILD/CLOSE 白名单 + blocked）
# 一次 jq 读回 stage + 三 scope（性能：原 source lib-state 后 4 次 jq 启动合并为 1 次）。
# 字段用 ASCII 31(\x1f) 分隔，数组元素内部用 ASCII 30(\x1e) 分隔——两个控制字符都不会
# 出现在路径里，也不含 \n，从而单次 read 即可完整取回多行数组(不丢元素)。
SEP=$'\x1f'; INNER=$'\x1e'
IFS="$SEP" read -r STAGE ALLOWED BLOCKED EXTRA < <(
  jq -j --arg fs "$SEP" --arg is "$INNER" '
    [.stage,
     (.scope.allowed_paths//[]|join($is)),
     (.scope.blocked_paths//[]|join($is)),
     (.scope.extra_grants//[]|join($is))] | .[] | (. + $fs)
  ' "$TASK_FILE"
)
# 数组内分隔符还原为换行，供 matches_prefix 逐行读
ALLOWED="${ALLOWED//$INNER/$'\n'}"
BLOCKED="${BLOCKED//$INNER/$'\n'}"
EXTRA="${EXTRA//$INNER/$'\n'}"

# 契约: allowed/blocked 路径必须以 / 结尾(目录前缀)，否则前缀匹配会过宽
# (如 "src/pay/refund" 会误匹配 "src/pay/refundother")。task-lock.sh 写入时负责规范化。
# 前缀匹配: 路径以任一前缀开头则命中（前缀来自 stdin，每行一个）
matches_prefix() {  # path
  local p="$1" pat
  while IFS= read -r pat; do
    [ -n "$pat" ] && [[ "$p" == "$pat"* ]] && return 0
  done
  return 1
}

# blocked 铁律: 全阶段生效
if printf '%s\n' "$BLOCKED" | matches_prefix "$REL"; then
  echo "GUARDIAN: $REL 在硬禁区(blocked)，不可修改，/extend 也放不了。" >&2
  exit 2
fi

case "$STAGE" in
  PLAN)
    printf '%s\n' '.ai/plan/' '.ai/memory/draft/' | matches_prefix "$REL" && exit 0
    echo "GUARDIAN: PLAN 阶段只能写方案(.ai/plan/)和知识候选(.ai/memory/draft/)。确认计划后用 /build 进入 BUILD。" >&2
    exit 2 ;;
  BUILD)
    { printf '%s\n' "$ALLOWED"; printf '%s\n' "$EXTRA"; } | matches_prefix "$REL" && exit 0
    echo "GUARDIAN: $REL 超出锁定范围。需要时用 /extend <path> 申请放行。" >&2
    exit 2 ;;
  CLOSE)
    echo '.ai/memory/draft/' | matches_prefix "$REL" && exit 0
    case "$REL" in *.md) exit 0 ;; esac
    echo "GUARDIAN: CLOSE 阶段已冻结实现代码，只能写知识候选和文档。要改代码先 /build 退回。" >&2
    exit 2 ;;
  DONE|*)
    echo "GUARDIAN: 任务已 DONE，无活动任务。新任务用 /lock。" >&2
    exit 2 ;;
esac

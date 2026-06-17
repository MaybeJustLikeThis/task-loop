#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
GUARD="src/hooks/guardian.sh"

# 工具：构造 PreToolUse stdin 并跑 guardian，返回退出码
run_guard() {  # tool_name file_path  -> 退出码
  local payload; payload=$(jq -nc --arg t "$1" --arg p "$2" \
    '{tool_name:$t, tool_input:{file_path:$p}}')
  echo "$payload" | bash "$GUARD" >/dev/null 2>&1; echo $?
}

# 1. 无 task.json -> 拦所有写
rm -f .ai/task.json
assert_eq "$(run_guard Write src/any.go)" "2" "无任务时拦写"

# 2. 有 task.json，但写 task.json 自身 -> 命门，拦
cp tests/fixtures/task-plan.json .ai/task.json
assert_eq "$(run_guard Write .ai/task.json)" "2" "命门:写 task.json 被拦"
assert_eq "$(run_guard Write /abs/.ai/task.json)" "2" "命门:绝对路径写 task.json 被拦"

# 3. fail-closed: 解析异常时阻断（有任务前提下）
assert_eq "$(echo '' | bash "$GUARD" >/dev/null 2>&1; echo $?)" "2" "fail-closed:空 stdin 拦"
assert_eq "$(echo '{}' | bash "$GUARD" >/dev/null 2>&1; echo $?)" "2" "fail-closed:无 tool_name 拦"
# 4. 反斜杠路径也命中命门
assert_eq "$(run_guard Write '.ai\task.json')" "2" "命门:反斜杠路径写 task.json 被拦"

# 5. blocked 硬禁区：写 src/auth/ 被拦（fixture blocked_paths=["src/auth/"]）
assert_eq "$(run_guard Write src/auth/login.go)" "2" "blocked 路径被拦"
# 6. PLAN 白名单：写方案放行，写业务代码被拦
assert_eq "$(run_guard Write .ai/plan/notes.md)" "0" "PLAN 写方案放行"
assert_eq "$(run_guard Write .ai/memory/draft/MEM-x.md)" "0" "PLAN 写知识候选放行"
assert_eq "$(run_guard Write src/pay/refund/handler.go)" "2" "PLAN 写业务代码被拦"

# 7. BUILD: allowed 放行、extra 放行、范围外拦、绝对路径匹配
cp tests/fixtures/task-build.json .ai/task.json
assert_eq "$(run_guard Write src/pay/refund/x.go)" "0" "BUILD 写 allowed 放行"
assert_eq "$(run_guard Write src/util/helper.go)" "0" "BUILD 写 extra 放行"
assert_eq "$(run_guard Write src/other/y.go)" "2" "BUILD 写范围外拦"
assert_eq "$(run_guard Write "$PWD/src/pay/refund/x.go")" "0" "BUILD 绝对路径在 allowed 放行"
# mixed 盘符形式（Windows 原生 jq 的真实输出形态）
MIXED_ROOT="$(cygpath -m "$PWD" 2>/dev/null || echo "$PWD")"
if [ -n "$MIXED_ROOT" ] && [ "$MIXED_ROOT" != "$PWD" ]; then
  assert_eq "$(run_guard Write "$MIXED_ROOT/src/pay/refund/x.go")" "0" "BUILD mixed 形式绝对路径在 allowed 放行"
else
  echo "  SKIP: 非 Windows 或无 cygpath，跳过 mixed 路径断言"
fi
# 8. CLOSE: 文档放行、知识候选放行、代码拦
cp tests/fixtures/task-close.json .ai/task.json
assert_eq "$(run_guard Write docs/api.md)" "0" "CLOSE 写 md 放行"
assert_eq "$(run_guard Write .ai/memory/draft/MEM-z.md)" "0" "CLOSE 写知识候选放行"
assert_eq "$(run_guard Write src/pay/refund/x.go)" "2" "CLOSE 写代码拦"

# 工具: 跑 Bash 工具的 guardian
run_guard_bash() {  # fixture_file  command  -> 退出码
  cp "tests/fixtures/$1" .ai/task.json
  local payload; payload=$(jq -nc --arg c "$2" '{tool_name:"Bash",tool_input:{command:$c}}')
  echo "$payload" | bash "$GUARD" >/dev/null 2>&1; echo $?
}

# 9. PLAN 阶段高危 bash 被拦
assert_eq "$(run_guard_bash task-plan.json 'rm src/x.go')" "2" "PLAN: rm 被拦"
assert_eq "$(run_guard_bash task-plan.json 'sed -i s/a/b/ src/x.go')" "2" "PLAN: sed -i 被拦"
assert_eq "$(run_guard_bash task-plan.json 'ls -la')" "0" "PLAN: 只读命令放行"
# 10. BUILD 阶段 bash 放行（BUILD 允许写）
assert_eq "$(run_guard_bash task-build.json 'rm src/pay/refund/x.go')" "0" "BUILD: bash 放行"
# 11. BUILD 阶段 Bash 高危写命令撞 blocked -> best-effort 拦
# task-build.json blocked_paths=["src/auth/"]
assert_eq "$(run_guard_bash task-build.json 'rm src/auth/secret.go')" "2" "BUILD: rm 撞 blocked 被 best-effort 拦"
assert_eq "$(run_guard_bash task-build.json 'rm src/pay/refund/x.go')" "0" "BUILD: rm allowed 范围放行"

rm -f .ai/task.json
summary

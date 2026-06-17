#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
rm -f .ai/task.json

# lock 两个路径
bash src/scripts/task-lock.sh src/pay/refund/ src/util/
assert_eq "$?" "0" "lock 成功退出"
assert_eq "$(jq -r '.stage' .ai/task.json)" "PLAN" "lock 后 stage=PLAN"
assert_match "src/pay/refund/" "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "allowed 含 refund"
assert_match "src/util/" "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "allowed 含 util"
assert_match "TASK-" "$(jq -r '.task_id' .ai/task.json)" "生成 task_id"

# 尾斜杠规范化：传入不带斜杠的路径，应规范化为带斜杠
rm -f .ai/task.json
bash src/scripts/task-lock.sh src/pay/refund
assert_match '"src/pay/refund/"' "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "无尾斜杠路径被规范化为带斜杠"

# 反斜杠路径规范化（Windows）
rm -f .ai/task.json
bash src/scripts/task-lock.sh 'src\pay\refund'
assert_match '"src/pay/refund/"' "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "反斜杠路径被规范化"

# 多尾斜杠规范化
rm -f .ai/task.json
bash src/scripts/task-lock.sh 'src/x///'
assert_match '"src/x/"' "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "多尾斜杠被规范化"

# ./ 前缀去除
rm -f .ai/task.json
bash src/scripts/task-lock.sh './src/pay/refund'
assert_match '"src/pay/refund/"' "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "点斜杠前缀被去除"

# 无效路径（空/纯斜杠）报错 + exit 1 + 不写文件
rm -f .ai/task.json
bash src/scripts/task-lock.sh '/' >/dev/null 2>&1
assert_eq "$?" "1" "纯斜杠路径报错退出"
[ ! -f .ai/task.json ] && echo "  PASS: 无效路径不创建 task.json" || echo "  FAIL: 无效路径不应创建 task.json"

rm -f .ai/task.json
summary

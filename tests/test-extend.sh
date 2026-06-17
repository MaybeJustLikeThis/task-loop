#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh

# case1: extend 目录路径 -> extra 增 + guardian 放行
cp tests/fixtures/task-build.json .ai/task.json
bash src/scripts/task-extend.sh src/util/ 2>/dev/null; assert_eq "$?" "0" "extend 成功"
assert_match "src/util/" "$(jq -rc '.scope.extra_grants[]' .ai/task.json)" "extra 含新路径"
echo '{"tool_name":"Write","tool_input":{"file_path":"src/util/x.go"}}' \
  | bash src/hooks/guardian.sh >/dev/null 2>&1; assert_eq "$?" "0" "extend 后 guardian 放行"

# case2: extend blocked 路径 -> 拒（用 plan fixture: extra=[], blocked=[src/auth/]）
cp tests/fixtures/task-plan.json .ai/task.json
bash src/scripts/task-extend.sh src/auth/ 2>/dev/null; assert_eq "$?" "1" "extend blocked 被拒"
assert_eq "$(jq -rc '.scope.extra_grants' .ai/task.json)" "[]" "blocked 未进 extra"

# case3: 无参数 -> 用法 + exit 1
cp tests/fixtures/task-build.json .ai/task.json
bash src/scripts/task-extend.sh 2>/dev/null; assert_eq "$?" "1" "无参数报错"

rm -f .ai/task.json
summary

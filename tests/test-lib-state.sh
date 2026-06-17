#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
TASK_FILE="tests/fixtures/task-plan.json"
source src/scripts/lib-state.sh

assert_eq "$(state_get_stage "$TASK_FILE")" "PLAN" "读 stage"
assert_eq "$(state_get_scope allowed_paths "$TASK_FILE")" "src/pay/refund/" "读 allowed"
assert_eq "$(state_get_scope blocked_paths "$TASK_FILE")" "src/auth/" "读 blocked"

# 临时副本测写入，不污染 fixture
cp "$TASK_FILE" /tmp/t.json
state_set_stage /tmp/t.json BUILD
assert_eq "$(jq -r '.stage' /tmp/t.json)" "BUILD" "写 stage"

state_extend /tmp/t.json "src/util/"
assert_match "src/util/" "$(jq -rc '.scope.extra_grants[]' /tmp/t.json)" "追加 extra"

state_clear_scope /tmp/t.json
assert_eq "$(jq -rc '.scope.allowed_paths' /tmp/t.json)" "[]" "清空 scope"

state_set_gate /tmp/t.json tests_passed true
assert_eq "$(jq -r '.gate.tests_passed' /tmp/t.json)" "true" "写 gate"
assert_eq "$(jq -rc '.gate.tests_passed | type' /tmp/t.json)" "boolean" "gate 保持布尔类型"

summary

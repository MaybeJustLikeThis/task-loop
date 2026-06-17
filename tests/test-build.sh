#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
rm -rf .ai/memory/draft/*; mkdir -p .ai/memory/draft

# case1: 无前置知识 + 未确认 -> 拒
cp tests/fixtures/task-plan.json .ai/task.json
bash src/scripts/task-build.sh --confirm 2>/dev/null; assert_eq "$?" "1" "无前置知识时拒"
assert_eq "$(jq -r '.stage' .ai/task.json)" "PLAN" "未过 gate 不切 stage"

# case2: 有前置知识 + 确认 -> 进 BUILD
echo "# 前置知识" > .ai/memory/draft/MEM-pre.md
bash src/scripts/task-build.sh --confirm 2>/dev/null; assert_eq "$?" "0" "过 gate 成功"
assert_eq "$(jq -r '.stage' .ai/task.json)" "BUILD" "切到 BUILD"
assert_eq "$(jq -r '.gate.pre_committed' .ai/task.json)" "true" "pre_committed 置 true"

# case3: 有知识但没 --confirm -> 拒（人没确认计划）
cp tests/fixtures/task-plan.json .ai/task.json
bash src/scripts/task-build.sh 2>/dev/null; assert_eq "$?" "1" "缺 --confirm 被拒"

rm -f .ai/task.json; rm -f .ai/memory/draft/*
summary

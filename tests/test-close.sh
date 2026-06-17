#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
rm -rf .ai/memory/draft/*; mkdir -p .ai/memory/draft

# case1: BUILD 缺 gate -> 拒
cp tests/fixtures/task-build.json .ai/task.json
bash src/scripts/task-close.sh 2>/dev/null; assert_eq "$?" "1" "BUILD 缺 gate 拒"
# case2: BUILD 带 --tested --reviewed -> 进 CLOSE
bash src/scripts/task-close.sh --tested --reviewed 2>/dev/null; assert_eq "$?" "0" "过 gate"
assert_eq "$(jq -r '.stage' .ai/task.json)" "CLOSE" "进 CLOSE"

# case3: CLOSE 无后置知识 -> 拒
bash src/scripts/task-close.sh 2>/dev/null; assert_eq "$?" "1" "CLOSE 缺后置知识拒"
# case4: CLOSE 有后置知识 -> DONE + 清 scope
echo "# 后置知识" > .ai/memory/draft/MEM-post.md
bash src/scripts/task-close.sh 2>/dev/null; assert_eq "$?" "0" "CLOSE 完成"
assert_eq "$(jq -r '.stage' .ai/task.json)" "DONE" "进 DONE"
assert_eq "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "[]" "scope 已清"

rm -f .ai/task.json; rm -f .ai/memory/draft/*
summary

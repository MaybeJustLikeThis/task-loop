#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

ROOT=$(make_fake_project)
bash install.sh "$ROOT" 2>/dev/null
assert_eq "$?" "0" "install 到空项目成功"
# 核心文件拷到位
for f in .claude/hooks/guardian.sh .claude/scripts/lib-state.sh \
         .claude/scripts/task-lock.sh .claude/commands/lock.md; do
  assert_file_exists "$ROOT/$f"
done
# manifest 写了
assert_file_exists "$ROOT/.ai/.task-loop-manifest"
assert_match "guardian.sh" "$(jq -rc '.files' "$ROOT/.ai/.task-loop-manifest")" "manifest files 含 guardian"

rm -rf "$ROOT"
summary

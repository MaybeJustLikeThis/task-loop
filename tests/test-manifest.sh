#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
source src/manifest.sh

TMP=$(mktemp -d)
# 写 manifest
manifest_write "$TMP" "v1.0" ".claude/hooks/guardian.sh" ".claude/scripts/lib-state.sh"
assert_eq "$?" "0" "manifest_write 成功"
# 读回校验
assert_eq "$(jq -r '.version' "$TMP/.ai/.task-loop-manifest")" "v1.0" "version 正确"
assert_match "guardian.sh" "$(jq -rc '.files' "$TMP/.ai/.task-loop-manifest")" "files 含 guardian"
assert_eq "$(manifest_exists "$TMP")" "yes" "manifest_exists 检测到"
# 删 manifest
manifest_delete "$TMP"
assert_eq "$(manifest_exists "$TMP")" "no" "manifest_delete 后不存在"

rm -rf "$TMP"
summary

#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

# === 空项目：拷文件 + manifest ===
ROOT=$(make_fake_project)
bash install.sh "$ROOT" 2>/dev/null
assert_eq "$?" "0" "install 到空项目成功"
for f in .claude/hooks/guardian.sh .claude/scripts/lib-state.sh \
         .claude/scripts/task-lock.sh .claude/commands/lock.md; do
  assert_file_exists "$ROOT/$f"
done
assert_file_exists "$ROOT/.ai/.task-loop-manifest"
assert_match "guardian.sh" "$(jq -rc '.files' "$ROOT/.ai/.task-loop-manifest")" "manifest files 含 guardian"
rm -rf "$ROOT"

# === 已有用户配置：智能合并 ===
ROOT=$(make_fake_project); seed_user_config "$ROOT"
bash install.sh "$ROOT" 2>/dev/null
# settings.json: 保留用户 Read hook + permissions，追加 guardian
assert_file_contains "$ROOT/.claude/settings.json" "Read"          "用户 Read hook 保留"
assert_file_contains "$ROOT/.claude/settings.json" "guardian.sh"   "guardian hook 追加"
assert_file_contains "$ROOT/.claude/settings.json" "permissions"   "用户 permissions 保留"
# CLAUDE.md: 用户原内容 + task-loop 标记块
assert_file_contains "$ROOT/CLAUDE.md" "用户原有 CLAUDE"            "用户 CLAUDE 内容保留"
assert_file_contains "$ROOT/CLAUDE.md" "<!-- task-loop:start -->"  "标记块追加"
assert_file_contains "$ROOT/CLAUDE.md" "三拍"                       "三拍章节在"
# .gitignore: 用户原行 + task-loop 行
assert_file_contains "$ROOT/.gitignore" "*.log"                     "用户 gitignore 保留"
assert_file_contains "$ROOT/.gitignore" ".ai/task.json"             "task-loop gitignore 追加"
rm -rf "$ROOT"

summary

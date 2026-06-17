#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

ROOT=$(make_fake_project); seed_user_config "$ROOT"
bash install.sh "$ROOT" >/dev/null 2>&1
# 制造用户 memory（uninstall 必须保留）
mkdir -p "$ROOT/.ai/memory/active"
echo "珍贵知识" > "$ROOT/.ai/memory/active/MEM-001.md"

bash uninstall.sh "$ROOT" 2>/dev/null
assert_eq "$?" "0" "uninstall 成功"
# 装的文件删了
for f in .claude/hooks/guardian.sh .claude/scripts/lib-state.sh .claude/commands/lock.md; do
  assert_file_absent "$ROOT/$f"
done
# manifest 删了
assert_file_absent "$ROOT/.ai/.task-loop-manifest" "manifest 已删"
# memory 保留
assert_file_contains "$ROOT/.ai/memory/active/MEM-001.md" "珍贵知识" "memory 数据保留"
# 反向后用户原配置恢复
assert_file_contains "$ROOT/.claude/settings.json" "Read" "用户 Read hook 恢复"
assert_not_contains "$ROOT/.claude/settings.json" "guardian.sh" "guardian hook 已移除"
assert_file_contains "$ROOT/CLAUDE.md" "用户原有 CLAUDE" "用户 CLAUDE 内容恢复"
assert_not_contains "$ROOT/CLAUDE.md" "task-loop:start" "标记块已删"
assert_file_contains "$ROOT/.gitignore" "*.log" "用户 gitignore 行恢复"
assert_not_contains "$ROOT/.gitignore" ".ai/task.json" "task-loop gitignore 行已删"

rm -rf "$ROOT"

# 幂等: 卸完再卸 → 安静退出
ROOT=$(make_fake_project); seed_user_config "$ROOT"
bash install.sh "$ROOT" >/dev/null 2>&1
bash uninstall.sh "$ROOT" >/dev/null 2>&1
bash uninstall.sh "$ROOT" 2>/dev/null; assert_eq "$?" "0" "重复 uninstall 幂等"
rm -rf "$ROOT"

summary

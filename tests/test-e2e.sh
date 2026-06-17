#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

ROOT=$(make_fake_project); seed_user_config "$ROOT"
bash install.sh "$ROOT" >/dev/null 2>&1
assert_eq "$?" "0" "e2e: install"
# guardian 在装好的目标里能拦越界写（在目标根跑，读它的 task.json）
mkdir -p "$ROOT/.ai"
echo '{"stage":"PLAN","scope":{"allowed_paths":["src/x/"],"blocked_paths":[],"extra_grants":[]},"gate":{}}' > "$ROOT/.ai/task.json"
(cd "$ROOT" && echo '{"tool_name":"Write","tool_input":{"file_path":"src/y/z.go"}}' | bash .claude/hooks/guardian.sh) >/dev/null 2>&1
assert_eq "$?" "2" "e2e: guardian 在目标项目拦越界写"
rm -f "$ROOT/.ai/task.json"
# uninstall 恢复用户配置
bash uninstall.sh "$ROOT" >/dev/null 2>&1
assert_eq "$?" "0" "e2e: uninstall"
assert_file_contains "$ROOT/.claude/settings.json" "Read" "e2e: 用户配置恢复"
rm -rf "$ROOT"
summary

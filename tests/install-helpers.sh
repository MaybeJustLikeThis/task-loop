#!/usr/bin/env bash
# install/uninstall 测试辅助：建临时假目标项目
source tests/test-helpers.sh

# 建一个空假项目，返回其路径
make_fake_project() {
  mktemp -d
}
# 在假项目里建一个带用户配置的 .claude/settings.json + CLAUDE.md + .gitignore
seed_user_config() {  # project_root
  local root="$1"
  mkdir -p "$root/.claude"
  cat > "$root/.claude/settings.json" <<'EOF'
{ "permissions": { "allow": ["Bash(git:*)"] },
  "hooks": { "PreToolUse": [{ "matcher":"Read", "hooks":[{"type":"command","command":"echo read"}] }] } }
EOF
  echo "# 用户原有 CLAUDE" > "$root/CLAUDE.md"
  echo "*.log" > "$root/.gitignore"
}
assert_file_exists() {
  if [ -f "$1" ]; then echo "  PASS: $1 存在"; TEST_PASS=$((TEST_PASS+1))
  else echo "  FAIL: $1 不存在"; TEST_FAIL=$((TEST_FAIL+1)); fi
}
assert_file_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then echo "  PASS: $1 含 $2"; TEST_PASS=$((TEST_PASS+1))
  else echo "  FAIL: $1 不含 $2"; TEST_FAIL=$((TEST_FAIL+1)); fi
}
assert_file_absent() {
  if [ ! -f "$1" ]; then echo "  PASS: $1 已不存在"; TEST_PASS=$((TEST_PASS+1))
  else echo "  FAIL: $1 仍存在"; TEST_FAIL=$((TEST_FAIL+1)); fi
}

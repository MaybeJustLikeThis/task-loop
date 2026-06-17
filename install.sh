#!/usr/bin/env bash
set -uo pipefail
# task-loop 安装脚本。用法: bash install.sh [target_project_root]

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$PWD}"
SRC="$HERE/src"

# 1. 依赖检查
command -v jq >/dev/null 2>&1 || { echo "install: 缺 jq。Windows: scoop/winget install jq；macOS: brew install jq" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "install: 目标不是目录: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

# 3. 已装检测
if [ -f "$TARGET/.ai/.task-loop-manifest" ]; then
  echo "install: 目标已装 task-loop（manifest 存在）。先 bash uninstall.sh 再装。" >&2
  exit 1
fi

source "$SRC/manifest.sh"

# 4. 拷 src/ → 目标 .claude/
mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/scripts" "$TARGET/.claude/commands"
cp "$SRC/hooks/"*.sh "$TARGET/.claude/hooks/"
cp "$SRC/scripts/"*.sh "$TARGET/.claude/scripts/"
cp "$SRC/commands/"*.md "$TARGET/.claude/commands/"

# 8. 先写 manifest（创建，flags=false），下面的合并函数再把 flags 设 true
FILES=(
  .claude/hooks/guardian.sh
  .claude/scripts/lib-state.sh .claude/scripts/task-lock.sh
  .claude/scripts/task-build.sh .claude/scripts/task-close.sh .claude/scripts/task-extend.sh
  .claude/commands/lock.md .claude/commands/build.md
  .claude/commands/close.md .claude/commands/extend.md
)
manifest_write "$TARGET" "1.0" "${FILES[@]}"

# 5. 合并 settings.json（保留用户已有配置，追加 guardian hook，去重）
merge_settings() {
  local target="$1/.claude/settings.json"
  if [ ! -f "$target" ]; then
    cp "$SRC/settings-hook.json" "$target"
  else
    jq empty "$target" 2>/dev/null || { echo "install: $target 不是合法 JSON，拒绝覆盖" >&2; exit 1; }
    local tmp; tmp=$(mktemp)
    jq --slurpfile hook "$SRC/settings-hook.json" '
      ($hook[0].hooks.PreToolUse // []) as $add |
      if (.hooks.PreToolUse // [] | map(.hooks[].command) | any(test("guardian.sh")))
      then . else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $add) end
    ' "$target" > "$tmp" && mv "$tmp" "$target"
  fi
  manifest_set_flag "$TARGET" merged_settings_json true
}
merge_settings "$TARGET"

# 6. 追加 CLAUDE.md 标记块（幂等：已有标记则跳过）
append_claudemd() {
  local target="$1/CLAUDE.md"
  if grep -q '<!-- task-loop:start -->' "$target" 2>/dev/null; then
    :
  else
    { [ -f "$target" ] && cat "$target" || true; cat "$SRC/claudemd-section.md"; } > "$target.tmp" && mv "$target.tmp" "$target"
  fi
  manifest_set_flag "$TARGET" appended_claudemd true
}
append_claudemd "$TARGET"

# 7. 追加 .gitignore（逐行去重）
append_gitignore() {
  local target="$1/.gitignore"
  touch "$target"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -qxF -- "$line" "$target" || echo "$line" >> "$target"
  done < "$SRC/gitignore-lines.txt"
  manifest_set_flag "$TARGET" appended_gitignore true
}
append_gitignore "$TARGET"

# 9. 提示
echo "task-loop 已装到 $TARGET"
echo "⚠️  请重启 Claude Code 会话使 guardian hook 生效（cc 在会话启动时加载 hook）。"

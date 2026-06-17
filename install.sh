#!/usr/bin/env bash
set -uo pipefail
# task-loop 安装脚本。用法: bash install.sh [target_project_root]
# 默认装到当前目录；给参数则装到该目录。

HERE="$(cd "$(dirname "$0")" && pwd)"          # task-loop 仓库根
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

# 4. 拷 src/ → 目标 .claude/
mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/scripts" "$TARGET/.claude/commands"
cp "$SRC/hooks/"*.sh "$TARGET/.claude/hooks/"
cp "$SRC/scripts/"*.sh "$TARGET/.claude/scripts/"
cp "$SRC/commands/"*.md "$TARGET/.claude/commands/"

# 5-6. settings.json/CLAUDE.md/.gitignore 合并 —— Task 5/6 接入
# （占位：此处后续插入 merge_settings / append_claudemd / append_gitignore）

# 8. 写 manifest
source "$SRC/manifest.sh"
FILES=(
  .claude/hooks/guardian.sh
  .claude/scripts/lib-state.sh .claude/scripts/task-lock.sh
  .claude/scripts/task-build.sh .claude/scripts/task-close.sh .claude/scripts/task-extend.sh
  .claude/commands/lock.md .claude/commands/build.md
  .claude/commands/close.md .claude/commands/extend.md
)
manifest_write "$TARGET" "1.0" "${FILES[@]}"

# 9. 提示
echo "task-loop 已装到 $TARGET"
echo "⚠️  请重启 Claude Code 会话使 guardian hook 生效（cc 在会话启动时加载 hook）。"

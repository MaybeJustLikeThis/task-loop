#!/usr/bin/env bash
set -uo pipefail
# task-loop 卸载脚本。用法: bash uninstall.sh [target_project_root]
HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$PWD}"
[ -d "$TARGET" ] || { echo "uninstall: 目标不是目录: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
source "$HERE/src/manifest.sh"

MANIFEST="$(manifest_path "$TARGET")"
if [ ! -f "$MANIFEST" ]; then
  echo "uninstall: 未找到 manifest（$MANIFEST），可能没装过。安静退出。"
  exit 0
fi

# 读 flags（删 manifest 前读）
MERGED_SETTINGS=$(manifest_get "$TARGET" merged_settings_json)
APPENDED_CLAUDE=$(manifest_get "$TARGET" appended_claudemd)
APPENDED_GIT=$(manifest_get "$TARGET" appended_gitignore)

# 删 manifest 记录的文件（jq 在 Windows 输出 \r\n，tr 去掉 \r）
for f in $(jq -r '.files[]' "$MANIFEST" | tr -d '\r'); do
  rm -f "$TARGET/$f"
done

# 反向 settings.json（移除 guardian hook）
if [ "$MERGED_SETTINGS" = "true" ] && [ -f "$TARGET/.claude/settings.json" ]; then
  tmp=$(mktemp)
  jq '.hooks.PreToolUse |= map(select(.hooks[].command | test("guardian.sh") | not))' \
    "$TARGET/.claude/settings.json" > "$tmp" && mv "$tmp" "$TARGET/.claude/settings.json"
fi
# 反向 CLAUDE.md（删标记块）
if [ "$APPENDED_CLAUDE" = "true" ] && [ -f "$TARGET/CLAUDE.md" ]; then
  sed '/<!-- task-loop:start -->/,/<!-- task-loop:end -->/d' "$TARGET/CLAUDE.md" > "$TARGET/CLAUDE.md.tmp" \
    && mv "$TARGET/CLAUDE.md.tmp" "$TARGET/CLAUDE.md"
fi
# 反向 .gitignore（一次性移除所有 task-loop 行）
if [ "$APPENDED_GIT" = "true" ] && [ -f "$TARGET/.gitignore" ]; then
  tmp=$(mktemp)
  grep -vxF -f "$HERE/src/gitignore-lines.txt" "$TARGET/.gitignore" > "$tmp" || true
  mv "$tmp" "$TARGET/.gitignore"
fi

# 删 manifest（保留 .ai/memory）
manifest_delete "$TARGET"

# 清理空的 task-loop 目录（仅当空）
for d in .claude/hooks .claude/scripts .claude/commands; do
  [ -d "$TARGET/$d" ] && [ -z "$(ls -A "$TARGET/$d" 2>/dev/null)" ] && rmdir "$TARGET/$d" 2>/dev/null || true
done

echo "task-loop 已从 $TARGET 卸载（.ai/memory 已保留）"
echo "⚠️  请重启 Claude Code 会话使卸载生效。"

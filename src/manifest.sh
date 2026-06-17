#!/usr/bin/env bash
# .ai/.task-loop-manifest 读写。install 写，uninstall 读。
# manifest 根目录由 $1 传入（目标项目根）。

manifest_path() { echo "$1/.ai/.task-loop-manifest"; }

manifest_exists() {  # root -> yes/no
  [ -f "$(manifest_path "$1")" ] && echo yes || echo no
}

manifest_write() {  # root version file1 file2 ...
  local root="$1" version="$2"; shift 2
  mkdir -p "$root/.ai"
  local files_json; files_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
  jq -n --arg v "$version" --argjson files "$files_json" \
    '{version:$v, installed_at:now|todateiso8601, files:$files,
      merged_settings_json:false, appended_claudemd:false, appended_gitignore:false}' \
    > "$(manifest_path "$root")"
}

manifest_get() {  # root key -> 值
  jq -r ".$2 // empty" "$(manifest_path "$1")"
}

manifest_set_flag() {  # root key value
  local f; f="$(manifest_path "$1")"
  local tmp; tmp=$(mktemp)
  jq --arg k "$2" --argjson v "$3" '.[$k]=$v' "$f" > "$tmp" && mv "$tmp" "$f"
}

manifest_delete() { rm -f "$(manifest_path "$1")"; }

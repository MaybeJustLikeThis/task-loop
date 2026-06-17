#!/usr/bin/env bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source .claude/scripts/lib-state.sh
TF=".ai/task.json"

[ -f "$TF" ] || { echo "无活动任务，先 /lock。" >&2; exit 1; }
STAGE="$(state_get_stage "$TF")"

draft_has_files() { ls .ai/memory/draft/* 2>/dev/null | grep -qv '\.gitkeep'; }

case "$STAGE" in
  BUILD)
    TESTED=0; REVIEWED=0
    for a in "$@"; do
      case "$a" in --tested) TESTED=1;; --reviewed) REVIEWED=1;; esac
    done
    MISSING=""
    [ "$TESTED" = 1 ] || MISSING=" tests_passed(加 --tested)"
    [ "$REVIEWED" = 1 ] || MISSING="$MISSING review_done(加 --reviewed)"
    if [ -n "$MISSING" ]; then echo "/close 未过 gate:$MISSING" >&2; exit 1; fi
    state_set_gate "$TF" tests_passed true
    state_set_gate "$TF" review_done true
    state_set_stage "$TF" CLOSE
    echo "stage=CLOSE。把后置知识写到 .ai/memory/draft/，再 /close 完成。" ;;
  CLOSE)
    if ! draft_has_files; then
      echo "/close 未过 gate: 缺后置知识(先在 .ai/memory/draft/ 写)" >&2; exit 1
    fi
    state_set_gate "$TF" post_committed true
    state_set_stage "$TF" DONE
    state_clear_scope "$TF"
    echo "stage=DONE，scope 已清空。draft/ 中的知识待人类审查后激活到 memory/active/。" ;;
  *)
    echo "当前 $STAGE，/close 不适用。" >&2; exit 1 ;;
esac

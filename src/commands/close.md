---
description: 校验 gate 并推进到 CLOSE / DONE
---

运行：`bash .claude/scripts/task-close.sh $ARGUMENTS`

根据脚本输出判断：若提示进入 CLOSE，提醒用户把后置知识写到 `.ai/memory/draft/` 后再敲一次 `/close` 收尾；若提示进入 DONE，提醒用户审查 draft/ 并把值得保留的知识激活到 `memory/active/`。

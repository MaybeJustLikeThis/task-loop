---
description: 校验 gate 并从 PLAN 进入 BUILD
---

运行：`bash .claude/scripts/task-build.sh $ARGUMENTS`

若脚本退出码非 0，把 stderr 原样转告用户并停下，不要继续。若成功，告知用户已进入 BUILD，只能在锁定范围内写代码，越界需 `/extend` 申请。开发完成用 `/close`。

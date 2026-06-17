---
description: 锁定本次改动范围并进入 PLAN 阶段
---

执行任务闭环的锁定步骤。运行以下命令并报告结果：

`bash .claude/scripts/task-lock.sh $ARGUMENTS`

然后告知用户：当前进入 PLAN 阶段，只能写 `.ai/plan/`（方案）和 `.ai/memory/draft/`（前置知识），不能动业务代码。写完方案和前置知识后用 `/build` 进入开发。

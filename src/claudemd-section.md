
<!-- task-loop:start -->
# 任务闭环系统 (Task Loop)

本仓库启用单任务闭环。AI 的所有文件写入受 `.claude/hooks/guardian.sh` 守卫。

## 当前任务
状态文件：`.ai/task.json`（AI 只读，不可修改——改了会被 guardian 拦）。
若 `.ai/task.json` 不存在，说明没有活动任务，先让用户 `/lock <paths>`。

## 三拍
- **PLAN**：只能写 `.ai/plan/`（方案）和 `.ai/memory/draft/`（前置知识）。不动业务代码。
- **BUILD**：只能在 `allowed_paths`+`extra_grants` 范围内写代码。越界被拦时，告诉用户需要 `/extend <path>`。
- **CLOSE**：实现代码冻结，只能写知识候选和文档。

## 切换靠人发车
`/lock` → `/build --confirm` → `/close --tested --reviewed` → `/close`（收尾）。AI 不自行推进阶段。

## 知识
两次提交都写到 `.ai/memory/draft/`：PLAN 末写前置知识（为什么这么改），CLOSE 写后置知识（踩的坑、新决策）。AI 只写 draft，激活到 `active/` 由人决定。

## 被 guardian 拦了怎么办
读 stderr 的 GUARDIAN 提示，按提示行动（申请 /extend、或退回上阶段），不要反复重试相同动作。
<!-- task-loop:end -->

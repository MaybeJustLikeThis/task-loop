# task-loop

单任务闭环系统：AI 改代码前先锁定范围，PLAN/BUILD/CLOSE 三拍由人发车、guardian hook 守门硬拦截。Claude Code 原生。

## 安装（到你的 cc 项目）
```
git clone <task-loop 仓库>
cd /path/to/your-cc-project
bash /path/to/task-loop/install.sh
# ⚠️ 重启 Claude Code 会话使 guardian 生效
```

## 卸载（保留你的 .ai/memory 知识）
```
bash /path/to/task-loop/uninstall.sh   # 在你的项目根跑
# ⚠️ 重启 Claude Code 会话使卸载生效
```

## 用法（装好后在 cc 里）
`/lock <paths>` → `/build --confirm` → `/close --tested --reviewed` → `/close`
详见被装进你项目 CLAUDE.md 的"任务闭环系统"章节。

## 依赖
- jq（settings.json 合并）
- bash（Windows 需 Git Bash）

## 已知坑
- **cc 的 hook 会话级加载**：install/uninstall 后必须重启 cc 才生效。
- **codex 不支持硬拦截**：v1 只服务 cc。codex 项目装了能用脚本/命令，但 guardian 不拦截。
- 设计文档：见 `docs/superpowers/specs/2026-06-17-task-loop-distribution-design.md`（在 team-systematic-docs 仓库）。

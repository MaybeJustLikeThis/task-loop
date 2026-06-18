# task-loop

task-loop 系统的**可分发实现仓库**：`git clone` + `bash install.sh` 一键装到任意 Claude Code 项目，guardian PreToolUse hook 守门硬拦截。

## 强关联仓库：team-systematic-docs（设计）

`D:\Mycase\team-systematic-docs` — GitHub: [MaybeJustLikeThis/team-systematic-docs](https://github.com/MaybeJustLikeThis/team-systematic-docs)

两者**高度强相关，跨仓库联动开发**：
- 本仓库是 task-loop 的**唯一可运行实现**，`src/` 是唯一实现来源（装到目标项目的内容都从这里拷）。
- team-systematic-docs 持有 task-loop 的设计存档（spec + plan）。

### 设计存档位置（在 team-systematic-docs 的 `docs/superpowers/`）

- `specs/2026-06-17-task-loop-design.md` — 系统本体设计
- `specs/2026-06-17-task-loop-distribution-design.md` — 分发包设计
- `plans/2026-06-17-task-loop.md` / `plans/2026-06-17-task-loop-distribution.md` — 实现计划

## 联动开发约定

- **spec 是真相之源**：改 `src/` 行为/契约前，先看 team-systematic-docs 对应 spec，确认设计意图。实现与 spec 不一致时——要么改实现，要么更新 spec，不让两边漂移。
- **跨仓库无需切会话**：Claude Code 工具用绝对路径可直接读写对方仓库，例如：
  - `Read D:\Mycase\team-systematic-docs\docs\superpowers\specs\2026-06-17-task-loop-design.md` — 查设计
  - 改了实现且影响设计语义 → 回写 team-systematic-docs 的 spec/plan。
- **install/uninstall 是纯 shell 脚本**，由用户在终端直接 `bash` 运行，不经 cc 工具调用——因为 guardian 激活且无 task.json 时会拦所有 cc 写操作，会拦到 uninstall 自己。
- **改完必跑** `bash tests/run-all.sh` 全绿再提交。

## 本仓库结构速查

- `src/` — 要分发到目标项目的内容（hooks/scripts/commands + 三个合并片段 settings-hook.json/claudemd-section.md/gitignore-lines.txt + manifest.sh）
- `install.sh` / `uninstall.sh` — 纯 shell 搬运工（jq 合并 settings.json、标记块追加 CLAUDE.md、manifest 精确反向）
- `tests/` — 纯 bash 断言 + mktemp 隔离的假项目测试，`run-all.sh` 入口

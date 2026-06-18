# task-loop

> 给 Claude Code 装一道刹车：AI 改文件前先锁定范围，越界硬拦，人发车推进，做完把经验留下。

全行业都在让 AI 更自主——assign 一个 issue，它自己研究、自己改代码、自己开 PR，你只需要等通知。task-loop 走相反的路：在 AI 真正落笔改文件之前，先给它装一道闸门。越界写，当场拦下；阶段切换，必须人来发车；收尾时把"为什么这么改"和"踩了什么坑"强制留下来。

它不是又一个 AI 编程工具。是自主 agent 时代的**合规与审计层**——当所有产品都在比"谁更放手"时，它负责在每一次写文件前默认说不。

---

## 为什么需要它：自主的代价

一个人用 AI 写代码很爽。一群人各自用 AI 往同一个仓库写代码，是灾难——范围失控、计划丢失、规范靠自觉、出事查不到谁。更糟的是新一代自主 agent：assign 完就黑箱推进，改了哪些文件、为什么改、有没有越界碰红线，全靠它自己汇报。

```
个人 AI 开发(看上去没问题)          团队 / 自主 agent 开发(真实灾难)
  你 ──► AI ──► 代码 ──► 自己拍板       A ──► AI ──┐
                                        B ──► AI ──┼──► 同一个仓库 ──► 生产
  上下文/规则/坑点全在你脑子里            C ──► AI ──┘   (或 agent 自己跑)
                                        → 风格漂移 / 互相覆盖 / 越界碰红线 / 责任黑洞
```

task-loop 把这道闸门做成了 Claude Code 原生的 PreToolUse hook，**真约束，不靠自觉**。不是写在文档里让人记的规范，是会拦人的代码。

---

## 它怎么工作：三拍节奏 + 一道守门人

```
/lock 范围         /build --confirm        /close --tested --reviewed       /close
   │                    │                          │                          │
   ▼                    ▼                          ▼                          ▼
 PLAN ──────────► BUILD ──────────────────► CLOSE ─────────────────────► DONE
 想方案              动代码                      收尾 + 留经验               清场

guardian 全程站岗:越界写 → 当场拦 → 反馈给 AI → AI 只能按规矩来
```

**人发车，AI 不能自己推进阶段。** 每一拍切换都是你敲命令；AI 想越界，guardian 当场拦下，把理由反馈给 AI。

---

## 赛道定位：不是又一个编程工具，是 agent 的刹车

整个 AI coding agent 赛道都在押注"更自主"——Devin、Copilot Coding Agent、Jules、Cursor Background Agents，甚至定时触发的 Autopilots，方向都是"assign 完就不用管"。task-loop 是**反潮流的那一个**：它不比谁更放手，它比谁能在该说不的时候拦得住。

把赛道按 task-loop 押注的三个轴拆开，**全赛道同时满足三轴的只有它一个**：

| | 文件级硬约束 | 人发车（不自主推进） | fail-closed（宁可误拦） |
|---|:---:|:---:|:---:|
| Devin / Copilot Agent / Jules / Cursor | ❌ 停在 issue/PR/repo 级 | ❌ 押注更自主 | ❌ 默认尽量办成 |
| AWS Kiro（机制最近的对手） | ✅ Agent Hooks | ⚠️ 流程仍 agent 驱动 | ❌ |
| claude-guardrails 等 CC 安全包 | ✅ deny + PreToolUse | ❌ | ❌ |
| **task-loop** | ✅ 运行时动态 `/lock` | ✅ 三拍必须人发车 | ✅ 第一性原理 |

**差异化三条**（即便对最近的对手也成立）：
- **运行时动态锁定**——`/lock` 是每次任务实时声明范围，不是一次性静态配置。
- **人发车硬流程**——阶段切换是必须由人触发的门禁，不是 agent 自走。
- **强制两次知识提交**——PLAN 末写"为什么改"、CLOSE 写"踩了什么坑"，作为阶段门禁的硬要求，不是可选记忆。

约束本身（PreToolUse、exit 2、文件锁）是 Claude Code 的平台能力，谁都能用；但把约束包进一个**强制的人发车流程 + 强制知识沉淀**，是竞品里的空白。

---

## 特性

- 🔒 **真约束，不靠自觉** — guardian 是 PreToolUse hook，越界写直接 `exit 2` 阻断。不是"建议遵守"的文档，是会拦人的代码。
- 🎯 **范围锁定** — `/lock` 锁定本次能改的路径，其他一概不给碰；命中硬禁区（`blocked`）连 `/extend` 都放不了。
- 🚦 **三拍门禁** — PLAN 只能想方案、BUILD 只能改锁定范围、CLOSE 冻结代码。递进锁，想回头改代码得显式 `/build` 退回去。
- 🧠 **两次知识提交，经验不蒸发** — PLAN 末写"为什么这么改"，CLOSE 写"踩了什么坑"。都落到带 ID 的 memory，下个人不用重新踩。
- 🛡️ **命门防护** — `.ai/task.json`（系统状态）对 AI 永远只读，AI 改不了自己的状态机给自己放行。fail-closed：解析异常一律阻断，宁可误拦不漏放。
- 🔁 **智能安装 / 干净卸载** — 装到你已有的 cc 项目，`settings.json` 用 jq 合并（保留你原有配置），`CLAUDE.md` 标记块追加；卸载按 manifest 精确反向删，**你的 `.ai/memory` 知识数据保留**。
- ✅ **101 个断言压着** — guardian 三拍矩阵、状态机、install/uninstall 合并、端到端，全有测试。不是 demo，是经过验证的。

---

## 60 秒上手

```bash
git clone https://github.com/MaybeJustLikeThis/task-loop.git
cd /your/cc-project
bash /path/to/task-loop/install.sh
```

然后**重启 Claude Code 会话**（cc 在会话启动时加载 hook，不重启不生效）。完事——guardian 已上岗。

卸载（保留你的 memory）：
```bash
bash /path/to/task-loop/uninstall.sh   # 在项目根跑，再重启 cc
```

---

## 用法

```
/lock src/your/module/           锁定范围，进 PLAN（只能写方案 + 前置知识）
/build --confirm                 过 gate，进 BUILD（只能改锁定范围）
/close --tested --reviewed       进 CLOSE（冻结代码，写后置知识）
/close                           收尾 → DONE，清空 scope
```

- 越界写 → guardian 拦 → 你用 `/extend <path>` 临时放行（任务结束自动清）
- 碰 `blocked` 铁律（认证/支付/生产配置这类）→ 放不了，改方案绕开
- 知识两次都写到 `.ai/memory/draft/`，AI 只能写草案，激活到 `active/` 由你决定

被拦了怎么办：看 stderr 里 `GUARDIAN:` 开头的提示，按它说的做（申请 `/extend`、或退回上阶段），别反复重试。

---

## 它替你防住什么

| 痛点 | task-loop 怎么堵 |
|---|---|
| AI 一动手范围就失控，顺手重构半个模块 | `/lock` 锁定 + guardian 越界硬拦 |
| 自主 agent 黑箱推进，改了啥全靠它汇报 | 三拍必须人发车，每拍范围显式声明、全程留痕 |
| 计划阶段的"为什么"开发一动手就忘 | PLAN 末强制写前置知识才能 `/build` |
| 规范写在文档里没人守，等于没有 | 规范变成 hook，在正确节点自动执行 |
| AI 又写又审，等于没审 | 三拍递进锁，CLOSE 想改代码得退回 BUILD |
| 出事查不到谁发起、读了啥、碰了哪些文件 | `.ai/task.json` 全程留痕，`human_owner` 绑定 |
| 这次踩的坑下个人重新踩 | CLOSE 强制写后置知识才能 DONE |
| AI 自己给自己放行 | task.json 命门只读，AI 改不了自己的状态 |

---

## 与自主 agent 平台的关系：互补，不竞争

task-loop 和 Devin、Multica 这类 Managed Agents 平台**不在一个层**：

```
自主 agent 平台 (Devin / Multica / Copilot Agent)        task-loop
   调度层：谁干、何时干、干到哪了                          执行层：干的时候能不能改这个文件
   押注 agent 自主可信、分时复用                           押注 agent 不可信、人发车、fail-closed
```

两者技术栈正交、哲学相反，但可以叠加：一个自主平台把任务派给 Claude Code 时，给那个 CC 装上 task-loop 的 guardian，就同时有了"高效协作"和"执行时不越界"。**一个 agent 平台要走到企业级，调度层和执行约束层缺一不可**——前者解决"把事做完"，后者解决"每一个写动作是否被允许"。

---

## 设计原则

1. **人发车，hook 守门** — 阶段切换归人，动作约束归 guardian。各管一摊。
2. **真约束，不靠自觉** — 能变成 hook 的绝不写成文档让人记。
3. **fail-closed** — 宁可误拦，不可漏放。解析异常、stage 异常、路径异常，一律阻断。
4. **可逆** — install 只加不改不删你的东西；uninstall 按 manifest 精确反向。所有改动可识别、可回退。
5. **最小依赖** — 只要 `jq` + `bash`。测试纯 bash 断言，不引 bats。装的过程不碰网络。

---

## 谁适合用

- 用 Claude Code 写代码，想让 AI **可控、可审计、不越界**的团队或个人
- 受够了"AI 一顿操作，代码能跑但没人知道为什么"的技术负责人
- 在用自主 agent 平台（Devin/Multica/类），但发现执行层没有硬约束、踩过越界坑的团队
- 想让团队 AI 协作留下**可引用的知识**，而不是只活在聊天记录里

---

## 已知局限（老实说）

- **只服务 Claude Code** — guardian 的硬拦截依赖 cc 的 PreToolUse hook。codex 没有对等机制，v1 不支持（装了能用脚本/命令，但 guardian 不拦）。
- **hook 会话级加载** — install / uninstall 后**必须重启 cc 会话**才生效，否则"装了没反应"。这条写进了 install 输出。
- **jq 是硬依赖** — settings.json 合并靠它，没 jq 装不了。
- **Bash 写检测是弱约束** — `Write/Edit` 能可靠拦，但 `sed -i`/`mv` 这类 bash 写命令只能 best-effort 检测（spec 里诚实标了）。
- **整个产品押在 cc 的 hook 机制上** — 该机制有边缘 bug（见 cc issue tracker），task-loop 会持续跟进，但这意味着深度绑定 cc 的能力演进。

---

## 设计文档

- **系统本体设计 + 分发包设计**：[`team-systematic-docs` 仓库](https://github.com/MaybeJustLikeThis/team-systematic-docs) 的 `docs/superpowers/specs/2026-06-17-task-loop-*.md`
- **赛道调研（竞品卡位 / 架构拆解 / 企业范式对账）**：同仓库 `docs/research/2026-06-18-multica-deep-dive.md`

MIT License.

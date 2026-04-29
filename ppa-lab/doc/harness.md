# Harness 视角：/ppa-lab/ AI Agent 执行框架问题分析

> 本文不评估 RTL / TB / Makefile 的技术内容，仅从「AI Agent 是否能准确、高效、有深度地完成任务」这一 Harness 视角，审视 `/ppa-lab/` 目前的协作框架（CLAUDE.md、ppa-lab-prompt.md、ppa-agent-character.md、各 lab 的 design-prompt.md / log.md / testplan.md）。
>
> 评审基线：把每一个 AI Agent 视为「无记忆、上下文有限、按一次会话粒度交付」的执行单元。框架的合理性 = 让任意一个新 Agent 在 5 分钟内知道 ①当前在做什么 ②上一个 Agent 留下了什么 ③下一步该怎么做 ④如何判断自己做完了。

---

## 1 总体诊断

当前框架已经具备 **角色定义 + 规格 + 流程 + 命名/目录规范** 这一「静态层」，但严重缺失 **状态层** 和 **交接层**：

| 层级 | 现状 | 评价 |
| --- | --- | --- |
| 静态规则层（应该是什么） | CLAUDE.md、ppa-lab-prompt.md、ppa-agent-character.md、ppa-lite-spec.md | ✅ 完备 |
| 动态状态层（现在到哪了） | 无（仅有人工写的 log.md，且只在「审查/设计」阶段有内容） | ❌ 缺失 |
| 交接层（你交给我了什么） | 无（log.md 是单向"做完总结"，不是"下一棒指引"） | ❌ 缺失 |
| 验收闭环层（怎么算做完） | ppa-lab-prompt.md 给了验收标准条目，但无机器可读的状态机 | ⚠️ 弱 |

结论：**框架是"给人看的项目说明书"，不是"给 AI 跑的协作流水线"**。一个新 Agent 进入仓库后，必须把所有 markdown 通读一遍，再去逐文件 `grep` 才能拼出当前进度——这与 Harness 思想（"上下文即燃料，能省则省"）相悖。

---

## 2 具体不合理点（按影响排序）

### 2.1 缺失「功能清单 / Feature Matrix」——最严重

**现状**：ppa-lab-prompt.md `# 3 实验阶段划分` 给出了 lab1～lab4 的"核心任务/验收标准"，但是：

- 它是**散文式**而非**清单式**，无法做状态打勾。
- 没有"功能 → 子任务 → 实现状态 → 验证状态 → 覆盖状态"的二维表。
- 验收标准与 spec 章节、与 testcase、与 log 条目之间**没有 ID 关联**。

**Harness 视角的代价**：
- 一个新接手的 DUT Agent 无法在不读 RTL 的情况下回答："CSR 里 `IRQ_STA` 的 RW1C 行为现在实现了没？"
- Verification Agent 无法判断："长度越界用例是否已存在？我要不要再写一个？" 只能去翻 testplan，而 lab1/doc/testplan.md **现在是空文件（0 行）**，lab2/doc/testplan.md 仅 46 行。
- 这直接导致 Agent 之间会**重复劳动**或**漏做**。

**建议**：在 `/ppa-lab/doc/` 新增 `feature-matrix.md`（项目级）和 `/labX/doc/feature-matrix.md`（lab 级），每行一个原子功能，列：`ID | 来源(spec §) | Owner Agent | 实现状态 | TB 状态 | 覆盖状态 | 关联 testcase | 备注`。任何 Agent 完成一项，必须在表里改状态。

### 2.2 缺失「状态追踪 / Status Board」

**现状**：判断"项目当前进展"的唯一来源是 git log 与各 `log.md` 的最后一段。`log.md` 现在是**事后记录**性质（lab1 的 log.md 357 行全是"审查阶段"的 PASS 表，没有任何"下一步要做什么""未决项是什么"的字段）。

**Harness 视角的代价**：
- 新 Agent 启动时，必须读完 lab1 + lab2 的全部 log（700+ 行）才能形成"当前态"心智模型，纯属上下文浪费。
- 没有显式的"阻塞项 / 风险项 / 未决问题"列表，导致跨 Agent 时这些信息靠口口相传。

**建议**：
- `/ppa-lab/doc/status.md`：项目级看板，结构固定为 `当前阶段 / 已完成里程碑 / 进行中 / 阻塞项 / 未决问题`，规则是**任何 Agent 提交前必须更新**。
- 每个 `labX/doc/log.md` 顶部增加固定 **"TL;DR + Next Action"** 块，限定 ≤20 行，新 Agent 只读这一段就能起步。

### 2.3 缺失「Agent 间交接笔记 / Handoff Notes」

**现状**：`ppa-agent-character.md` 定义了 4 类 Agent（DUT / Verification Plan / Verification Debug / Integration），但**没有定义它们之间的交接协议**。例如：

- DUT Agent 完成 RTL 后，要给 Verification Plan Agent 留下什么？
- Verification Debug Agent 定位到 bug 后，回传给 DUT Agent 的格式是什么？
- 一个 lab 完成后，向下一 lab 的 Agent 传递什么"经验/坑"？

`log.md` 中"5 迭代阶段"原本最接近交接，但 prompt 把它定位为"总结"，不是"对下一个 Agent 的指令"。

**Harness 视角的代价**：每次接力都要重新 reverse-engineer 上一棒的意图。这是当前最容易引发**回归倒退**和**误改**的地方。

**建议**：在 `ppa-agent-character.md` 中增加 `# 5 交接协议（Handoff Protocol）` 一节，统一格式：

```
## Handoff: <From-Agent> → <To-Agent>  (date, lab, commit)
- 我做了什么（≤5 条）
- 我没做什么 / 故意留给你的（≤5 条）
- 我踩过的坑 / 你要小心的（≤3 条）
- 验证我成果的最小命令
- 推荐你下一步的 3 个动作（按优先级）
```

并要求每次会话结束、`report_progress` 之前，必须把 Handoff 块追加到 `labX/doc/handoff.md`。

### 2.4 CLAUDE.md 与多 Agent 协作场景错位

**现状**：CLAUDE.md（62 行）是一份**通用的"高质量编码 Agent 行为准则"**——简洁优先、精准修改、目标驱动。它在文件优先级中被列为**第 1**（高于 spec 本身），但内容里：

- ❌ 没有任何关于"多 Agent 协作"的指示（不知道有别的 Agent 存在）。
- ❌ 没有任何关于"如何读现有上下文"的约定（先读 status，还是先读 log？）。
- ❌ 没有任何关于"会话结束如何收尾"的约定（必须更新哪些文件？）。
- ❌ "目标驱动执行"一节的样例是"写测试让它通过"，但 PPA 当前阶段（RTL 还未跑通），并不一定每一步都能 TDD，缺少 RTL/SV 场景化的样例。

**Harness 视角的代价**：CLAUDE.md 高优先级 + 通用化 = Agent 在跑前会被"通用准则"淹没注意力，而真正项目特异的协作约束反而要等读到第 4 篇 (`ppa-agent-character.md`) 才出现。

**建议**：
- 将 CLAUDE.md 重定位为"通用编码风格"，**降为辅助层**，从优先级 1 调整为优先级 4 或更低；
- 把"进入仓库后第一件事 / 收尾前最后一件事"这类项目特异的 Agent 操作步骤，单独放入 `ppa-agent-character.md` 顶部的 `# 0 通用准则`（现在那一节只列了能改/不能改的文件，远远不够）。
- CLAUDE.md 中至少补充一段"在多 Agent 仓库中的延展"，明确：本文件不是协作协议，协作协议见 `ppa-agent-character.md`。

### 2.5 ppa-lab-prompt.md 与 ppa-agent-character.md 职责切分模糊

**现状**：两份文件存在大量"准则"重叠：

- `ppa-lab-prompt.md § 0.4/0.5` 写"设计/验证侧硬约束"。
- `ppa-agent-character.md` 写各 Agent 的"职责/输出要求"。
- `ppa-lab-prompt.md § 8/9/11` 又写流程、日志和自查清单。

但是：
- 硬约束（如"PREADY 固定为 1"）应该在 spec 里，prompt 不应做技术规定的"二号信源"——容易和 spec 不一致且无人维护。
- "实验日志的 5 阶段写法"（§9）是**通用规则**，应该归 character.md，而不是分散在 prompt.md。
- 每个 Agent 看 prompt.md 时**无法快速定位"和我有关的章节"**。

**Harness 视角的代价**：信息冗余 → Agent 上下文成本翻倍；多源信息 → 一旦 spec 变更，prompt 中的硬约束副本会过期，引发 Agent 决策时按错误副本走。

**建议**：
- ppa-lab-prompt.md 收敛为**"项目蓝图 + 阶段地图 + 命名/目录规范"**；
- 把所有硬约束**仅保留在 spec**（prompt 中只引用 spec 章节号，不复制原文）；
- 把所有"Agent 行为/日志/自查/交接"集中到 ppa-agent-character.md。

### 2.6 ppa-agent-character.md 与 spec / 真实工作流脱节

**现状**：character.md 定义了 4 类 Agent，但：

- **没有定义 Spec / Architect Agent**：spec 已存在所以暂时不需要，但当 spec 出现疑问（lab1 log.md 里就出现了 `exp_pkt_len` vs `exp_pkt_len_o` 的命名笔误，是 DUT Agent 自行裁决的），缺少一个"裁决归属"。
- **没有定义 Reviewer / Sign-off Agent**：character.md 通用准则里写"严谨地互相挑刺、互相审查其他 Agent 的产出/修订"，但谁审、何时审、用什么 checklist 审，全部缺失。"互相审查"在 LLM 多 Agent 实践里基本等于不审。
- **职责粒度不均**：DUT Agent 一个角色覆盖了 RTL 全部模块（M1+M2+M3 跨 lab1/lab2/lab3），而 Verification 拆成了 Plan / Debug 两个。这与 lab 的分层节奏（lab1=M1+M2, lab2=M3, lab3=top）不匹配，易导致 DUT Agent 成为单点瓶颈。
- **未与 spec 章节对齐**：spec 目录没有"哪一节归哪一类 Agent 关心"的索引；新 Agent 不得不通读 865 行 spec。

**建议**：
- 新增 **Spec Steward Agent**：唯一负责回答"spec 怎么解读、笔误如何裁决"，并在 spec 末尾追加 `errata.md`。
- 新增 **Review/Sign-off Agent**：每个 lab 收尾时强制走一次，输出固定格式的 sign-off 表（端口/CSR/FSM/错误位/Makefile 五项 PASS/FAIL）。lab1/log.md 现在的 `2 审查阶段` 表其实就是这个角色干的活，应正名。
- DUT Agent 拆分为 `DUT-CSR`、`DUT-Mem`、`DUT-Core` 三个子角色，避免横跨 lab 的上下文堆积。
- 在 character.md 提供 **spec 章节 → Agent 关注度** 的小表，让 Agent 可以"按需读 spec"。

### 2.7 文档优先级链条存在逻辑漏洞

**现状**：ppa-lab-prompt.md `§0.3` 给出文件优先级 `CLAUDE > spec > prompt > character > labX/design-prompt > labX/log`，并要求新 Agent 按 `CLAUDE → 本文件 → spec → character → 当前 lab → 已有改动 → 参考工程` 顺序读。

问题：

1. **优先级把 spec 排在 prompt 之前，但读取顺序又把 prompt 排在 spec 之前**——两套规则互相矛盾。
2. 读取顺序里**完全没有 status / 上一次的 handoff**（因为现在不存在），等于让 Agent "永远从零开始"。
3. 没有限制"上下文预算"——把一份 865 行 spec 整篇灌入是浪费，应该先读 spec 的 ToC，按本次任务相关章节按需深入。

**建议**：
- 修正 `§0.3`：先 status.md（30 秒）→ 当前 lab handoff.md（2 分钟）→ feature-matrix.md（2 分钟）→ 才进入 spec/prompt 的相关章节。
- 把"通读"明确改成"按需读"，并给出 spec ToC 索引。

### 2.8 验收标准未机器化

**现状**：每个 lab 的"验收标准"在 ppa-lab-prompt.md 里是 4～5 条自然语言（如"端到端链路完整"、"连续两帧顺序处理正常"）。

**Harness 视角的代价**：Agent 自己说"完成了"或"没完成"完全主观，没有客观判据。CLAUDE.md `§4 目标驱动执行` 写得很好——"定义成功标准。循环验证直到达成"——但项目没把这个理念落到验收标准里。

**建议**：每条验收标准必须配一条**可执行的判据**，例如：
- "端到端链路完整" → "`make smoke` 返回 0，且 log 中出现 `DONE_OK x2`"
- "CSR 默认值正确" → "`tc_csr_default_rw` PASS 且 8 个寄存器 read-back == reset 值"

把验收标准从 prompt.md 移到 `labX/doc/acceptance.md`，以表格化形式存在，作为 Sign-off Agent 的输入。

### 2.9 testplan / log / design-prompt 三件套使用不一致

**现状**：
- lab1 的 `testplan.md` = **0 行（空文件）**。
- lab2 的 `testplan.md` = 46 行。
- 但 lab1 的 `log.md` = 357 行，lab2 的 `log.md` = 415 行——**重心严重错配**。

应该 testplan 先行（指导 TB 设计），log 紧随（记录运行结果）。当前是 log 一统天下，testplan 形同虚设。

**Harness 视角的代价**：Verification Plan Agent 没有可信的 testplan 入口，只能从 log 反推用例，等于做了一遍"考古"。

**建议**：把 testplan.md 设为**进入验证阶段的强制前置交付**，无 testplan 不允许进入验证；并在 `ppa-agent-character.md` 的 Verification Plan Agent 一节明文化此前置。

### 2.10 缺乏「会话粒度」的运行约定

**现状**：所有规则都假定"一次性长期开发"，没有针对"AI Agent 单次会话"的约束，例如：
- 一次会话最多触动多少文件？
- 一次会话最多落多少行代码？
- 当时间/上下文不够时，如何**优雅中断**并把状态留给下一棒？

**Harness 视角的代价**：长任务会被一次会话"啃不动"，结果是要么草草收尾、要么留下一堆未提交脏文件。

**建议**：在 `ppa-agent-character.md` 增加 `# 6 会话生命周期`：进入 → 读 status → 选定 ≤1 个 feature-matrix 行 → 实施 → 自验收 → 写 handoff → 更新 status → 退出。一次会话原则上只推进一行 feature-matrix。

---

## 3 优先级建议（实操路线）

如果只能做 3 件事，按以下顺序：

1. **新建 `feature-matrix.md` + `status.md` + `handoff.md` 三件套**（最大杠杆，立即解决"新 Agent 上下文爆炸"和"重复/漏做"问题）。
2. **重写 `ppa-agent-character.md`**：补 Handoff 协议、新增 Spec Steward / Reviewer 角色、加入会话生命周期；把 prompt.md 中的"日志/自查/约束"集中收编过来。
3. **将验收标准机器化**（`labX/doc/acceptance.md`），把 `ppa-lab-prompt.md` 瘦身为"蓝图 + 命名规范"。

完成后，`CLAUDE.md` 可以彻底回归"通用编码风格"角色，从优先级 1 退到末位，避免与项目特异协作约束打架。

---

## 4 一句话总结

> **目前的 /ppa-lab/ 是一份完善的"项目说明书"，但还不是一条能让多个 AI Agent 高效接力的"流水线"。**
> 缺失的不是规格、不是规范，而是 **状态、交接、机器可验收判据** 这三件让 Agent 协作真正闭环的基础设施。

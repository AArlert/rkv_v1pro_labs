# Harness 视角分析：/ppa-lab 工程对 AI Agent 的支撑度

> 分析时间：2026-04-29
> 分析视角：**不评判 RTL/TB/Makefile 的具体技术内容**，仅从「AI Agent 准确、高效、有深度地完成任务」这一 Harness（脚手架）维度出发，审视当前工程对 Agent 协作的友好程度
> 评估对象：`/ppa-lab/doc/{CLAUDE.md, ppa-lab-prompt.md, ppa-agent-character.md, ppa-lite-spec.md}` 以及各 lab 的 `doc/` 组织方式

---

## 1 总体结论

当前工程**已经具备规格文档、角色定义、目录约定、日志规范**等基础脚手架，比裸跑 Agent 要规范很多。但从 Harness 的标准看，仍存在如下系统性缺陷：

| 维度 | 现状 | 问题严重度 |
|------|------|-----------|
| **任务追踪 / 功能清单** | 缺失，无 TODO / Backlog / Burndown | 🔴 高 |
| **Agent 间交接** | 仅靠 `log.md` 自由叙述，无结构化 handoff | 🔴 高 |
| **状态可见性** | 没有「当前进展到哪、谁在做什么、下一步是谁」 | 🔴 高 |
| **角色边界** | character 文件粒度粗，与 spec/prompt 存在覆盖盲区 | 🟡 中 |
| **CLAUDE.md 适配性** | 通用准则，与本项目硬约束脱节 | 🟡 中 |
| **prompt 与 spec 边界** | 内容重复、优先级表述存在矛盾风险 | 🟡 中 |
| **失败/未决问题登记** | 无统一 issue / risk register | 🟡 中 |
| **可机读约束** | 全部为自然语言，Agent 易"自由发挥" | 🟢 低 |

---

## 2 缺失的 Harness 要素（最关键）

### 2.1 缺少全局功能清单（Feature Backlog）

`ppa-lab-prompt.md §3` 给出了 lab1~lab4 的「核心任务」和「验收标准」，但这是**章节性描述**，不是可勾选的清单。一个新接手的 Agent 进来时，**无法在 30 秒内回答**：

- 哪些 feature 已经做完？
- 哪些 testcase 已经通过？
- 当前阻塞在哪一项？
- 哪些是必做、哪些是选做、哪些已被裁剪？

**建议**：在 `/ppa-lab/doc/` 新增 `feature-list.md`，以表格形式列出所有 feature，列含 `id / 所属 lab / 描述 / 对应 spec 章节 / 状态(TODO|WIP|DONE|BLOCKED) / Owner Agent / 最后更新时间`。每次 Agent 改动后必须同步该表。

### 2.2 缺少状态追踪（Status Board）

各 `labX/doc/log.md` 当前是**审查/验证流水账**，按时间线累积而无聚合视图。问题：

- log.md 越长，新 Agent 读完越慢，违反「高效」原则。
- 没有「当前 lab 状态机」概念：lab1 到底是处于「设计中 / 审查中 / 验证中 / 已交付」哪一阶段？
- `ppa-lab-prompt.md §8` 定义了 5 阶段验收流程，但**没有对应的状态字段落地到任何文件**。

**建议**：每个 `labX/doc/` 增设 `status.md`（或在 log.md 顶部增设 status block），用结构化字段记录当前阶段、阻塞项、下一步动作。

### 2.3 缺少 Agent 间「交接笔记」（Handoff Note）

`ppa-agent-character.md` 把 Agent 划分为 4 类（DUT / VPlan / VDebug / Integration），但**完全没有定义它们之间如何握手**。当前隐式假设：

- DUT Agent 写完 RTL → 直接由下一个 Agent「读 log.md 自己悟」
- VDebug Agent 发现 bug → 在 log.md 里写一段 → 等 DUT Agent 自己来看

这在多轮 / 多 session 协作中是**高风险**的——Agent 无短期记忆，每次进入都要重新搜索 log.md，且容易遗漏其他 Agent 的最新结论。

**建议**：定义 `handoff.md`（每 lab 一份），固定字段：
- `From / To`（哪类 Agent → 哪类 Agent）
- `Context`（背景一句话）
- `Done`（已完成项的精确文件:行号）
- `Open Questions`（必须由接收方回答的问题）
- `Blocked By`（依赖项）
- `Verification Hint`（如何验证上一步成果）
- `Expires`（如果超过这个 commit 还没处理就作废）

### 2.4 缺少未决风险 / 假设登记表（Risk & Assumption Register）

`ppa-lab-prompt.md §11` 第 5 条要求「记录未决风险或尚未覆盖的场景」，`CLAUDE.md §1` 要求「明确说明假设」，但**没有任何文件承接这些产物**。结果是这些假设/风险散落在各 log.md 中，无法被聚合查询。

**建议**：`/ppa-lab/doc/risk-register.md`，记录所有「对 spec 的假设、未实现的约束、暂时绕过的问题」，由所有 Agent 共写。

### 2.5 缺少 Spec ↔ Implementation ↔ Test 的可追溯矩阵

`ppa-lab-prompt.md §3.4` 提到「testplan 文档」「用例到覆盖点映射」，但**全工程没有一份 spec section ↔ RTL 模块 ↔ testcase ↔ coverpoint 的统一矩阵**。Agent 想确认「spec §6.4 的 hdr_chk 规则究竟在哪测过」时只能全文 grep，效率低且容易漏。

**建议**：`/ppa-lab/doc/traceability.md`，每条 spec 需求一行，列 `spec §x.y / 需求摘要 / 实现位置 / 测试位置 / 覆盖点 / 状态`。

---

## 3 现有文件的具体问题

### 3.1 `CLAUDE.md` —— 通用心法，与项目脱节

**优点**：4 条准则（编码前思考、简洁优先、精准修改、目标驱动执行）属于跨项目通用最佳实践，写得相当克制，没有过度规定。

**问题**：

1. **与本项目的硬约束零关联**。CLAUDE.md 是优先级最高的文件（`ppa-lab-prompt.md §0.3` 把它放在 #1），但内容**完全是通用编码哲学**，不涉及 SV/UVM、APB、PPA-Lite 任何项目特征。Agent 读完后对「该项目」一无所知，必须再读 prompt + spec。这种排序意味着每次 onboarding 都要先消化通用准则——而通用准则大模型本身就内化了，**ROI 偏低**。
2. **§4「目标驱动执行」与硬件验证场景不完全契合**。表格里给出的例子全是软件场景（"为无效输入编写测试，然后让它们通过"），对 RTL Agent 缺乏指导意义——RTL 的「测试通过」涉及 Makefile / 仿真器 / 波形 / 覆盖率，门槛远高于软件单测。
3. **缺少「停止条件」和「升级路径」**。§1 说「困惑时停下来」，但**没说停下来之后向谁求助**。在多 Agent 工程里，应明确指出"在 handoff.md 中记录 OpenQuestion，挂起当前任务"。
4. **第 1 行有一个奇怪的字符**：文件以 `1. # 1 编码前思考` 开头（带列表序号），疑似从其他工具粘贴时引入的伪 markdown，会让某些 markdown 解析器渲染异常。

**建议**：
- 把 CLAUDE.md 拆成两层：保留通用心法部分（可考虑改名 `agent-principles.md`），另起一份 `project-onboarding.md` 作为真正的项目入口（目录结构、当前进度、下一步、必读文件清单），并把它放在优先级 #1。
- §4 增加一段针对 RTL/Verification 的「目标转化范例」。
- 增加「升级路径」一节：困惑时该写到 handoff.md 哪个字段、该 ping 哪个角色 Agent。

### 3.2 `ppa-lab-prompt.md` —— 信息密度高但职责过载

**优点**：覆盖目标、参考优先级、硬约束、目录、设计要点、验收流程，是信息量最大的单一文件。

**问题**：

1. **职责过载**。一个文件里同时承担：onboarding 指南（§0）、项目概述（§1~2）、阶段划分（§3）、命名规范（§4~5）、设计指南（§6）、仿真环境（§7）、流程定义（§8~9）、注意事项（§10~11）、TODO 列表（§12）。其中 §6 已经在重复 spec 的内容（系统结构图、寄存器属性、数据包格式、状态机），**与 `ppa-lite-spec.md` 形成了"双源真相"**——当 spec 更新时，prompt 极易脱节。`§10` 自己也强调"规格优先级以 spec 为准"，但同一文件却在重复 spec，逻辑自相矛盾。
2. **§0.3 参考优先级与 §10 注意事项第 1 条冲突**。§0.3 把 CLAUDE.md 排在 #1（高于 spec），而 §10 又说 "规格优先级以 spec 为准"。Agent 在冲突情境下不知道该听谁。
3. **§0.3 文件名错误**：列出的 `ppa-lab/labX/doc/ppa-lab-design-prompt.md` 实际上仓库里叫 `design-prompt.md`（少了 `ppa-lab-` 前缀）。这种细节性错误会让 Agent 直接 `view` 失败、走弯路。
4. **§12「下一步事项」是脆弱的 TODO**。它写在静态 prompt 里，没有人会主动来勾选/更新，做完了也不会自动消失，最终会和现实脱节，误导后来者。**TODO 必须放在专门的 backlog 文件**。
5. **§9「实验日志」要求与 §8 的 5 阶段一一对应，但没有给出模板**。结果各 lab 的 log.md 风格差异很大（lab1 重审查表，lab2 重设计叙述）。Agent 没有模板就只能模仿前一个 lab，风格漂移会越来越严重。
6. **§0.7 开发参考 / §0.8 外部知识缺口**这两块属于"教练式提示"，本来应当放进 onboarding 而不是 prompt 主体。

**建议**：
- 拆分为：`project-overview.md`（§1~2）、`lab-roadmap.md`（§3 + 状态字段）、`conventions.md`（§4~5、§7、§9 + 模板）、`design-cheatsheet.md`（§6，**或者干脆删掉，改为引用 spec §x.y**）、`backlog.md`（§12）。
- 在所有"硬约束"条目后**加上对应 spec 章节锚点**，让 Agent 一键回到唯一真相源。
- 修正 §0.3 的文件名拼写。

### 3.3 `ppa-agent-character.md` —— 角色定义偏薄

**优点**：把 Agent 区分为 4 类（DUT / VPlan / VDebug / Integration），有"通用准则 + 禁止项"的护栏。

**问题**：

1. **角色边界模糊，存在覆盖盲区**：
   - **谁负责写 spec / 维护 spec？** 4 个角色都不负责，但 spec 显然会演进。
   - **谁负责 doc/CLAUDE.md, prompt.md, character.md 自身的演进？** §0 禁令禁止所有 Agent 修改这些文件——但当前任务（用户让我改 doc/）就在突破这个禁令。这说明禁令规则与实际工作流不一致。
   - **谁负责 traceability / risk-register / handoff？**（即上文 §2 提的新增物）
   - **审阅 / 仲裁角色缺失**。多 Agent 互评时如果存在分歧，没人拍板。

2. **职责描述过于「输出导向」，缺少「输入契约」**。例如 DUT Agent 的"输出要求"写得清楚，但**进入 DUT Agent 任务前必须读哪些文件、需要哪些前置交付物**没说。结果是新启动的 Agent 只能靠通读所有 doc 才能开工，违反高效原则。

3. **没有「触发条件 / 终止条件」**。每个 Agent 什么时候应当被调用？什么时候算完成？目前完全靠人为派单。在多 Agent 自动编排（如 Copilot Coding Agent + sub-agent）场景下无法落地。

4. **§0 禁止项过于刚性**：禁止改 CLAUDE.md / prompt / spec 三件套，但这三件套本身是有缺陷且需要演进的。建议改为「修改三件套需要走 RFC：在 `/ppa-lab/doc/rfc/` 下提一份 patch 提案，由用户或指定角色批准」。

5. **缺少一个"会话/任务编排" Agent**。Harness 视角下，多 Agent 协作必然需要一个 Orchestrator，负责派活、汇总、关闭循环。当前 4 个角色全是干活的，没有调度者，很容易陷入"谁也没接手"或"几个 Agent 重复劳动"。

**建议**：
- 给每个角色补「输入契约 / 触发条件 / 终止条件 / 升级路径」4 个字段。
- 新增 Orchestrator Agent（或显式声明由用户兼任）和 Spec Maintainer Agent。
- 明确 doc 自身演进的 RFC 流程。

### 3.4 character ↔ spec ↔ prompt 三者匹配度

| 维度 | spec 提到 | prompt 提到 | character 承接？ |
|------|----------|-------------|----------------|
| RTL 实现 | ✅ | ✅ | ✅ DUT Agent |
| testcase 矩阵 / testplan | ✅ | ✅ §3.4 | ✅ VPlan Agent |
| 仿真失败定位 | 隐含 | ✅ §0.5 | ✅ VDebug Agent |
| Makefile / 回归入口 | ✅ Lab4 | ✅ §3.4, §7.2 | ✅ Integration Agent |
| **覆盖率分析** | ✅ Lab4 | ✅ §3.4, §0.5 | ❌ 未指派 |
| **波形审阅 / 验收** | ✅ §8 验收阶段 | ✅ §8 | ❌ 未指派 |
| **文档维护（doc/ 自身）** | — | 隐含 | ❌ 显式禁止 |
| **跨 Lab 集成与回归编排** | ✅ Lab3/4 | ✅ | ⚠️ 仅 Integration Agent 模糊承接 |
| **风险/未决项管理** | — | ✅ §11 | ❌ 未指派 |
| **Spec 演进 / 笔误修正** | — | — | ❌ 显式禁止 |

**结论**：character 与 spec/prompt 的覆盖**约 60%**，关键缺口是 **覆盖率、验收、文档自身演进、风险登记** 四块——而这些恰好是 Lab3/Lab4 阶段最重要的内容。继续按现状推进，到 Lab4 会发现"没人对覆盖率收口负责"。

### 3.5 各 `labX/doc/log.md` —— 单文件膨胀

`lab1/doc/log.md` 已 358 行且仍在增长。问题：

1. 单文件混合"设计阶段 / 审查阶段 / 验证阶段 / 验收阶段 / 迭代阶段"5 个阶段的所有内容，**新 Agent 进来要一口气读 358 行才能定位"现在该做什么"**。
2. 没有"摘要/状态/下一步"的顶部 block，**违反 LLM 上下文经济学**——把最重要的信息放最后，等于让 Agent 把完整 log 装进 context 窗口。
3. 历史记录 + 当前状态混在一起，无法用机器手段（diff / grep）抽取"截至某 commit 的 PASS/FAIL 矩阵"。

**建议**：
- 顶部固定一个 `## Status`（≤30 行）：当前阶段、上一次更新、阻塞项、下一步、责任 Agent。
- 历史明细沉到 `## History` 子章节，按时间倒序。
- 或拆分为 `log-design.md / log-review.md / log-verify.md / log-accept.md`。

---

## 4 Harness 视角的 12 条改进清单（优先级排序）

| # | 改进项 | 受影响文件 | 优先级 |
|---|--------|----------|-------|
| 1 | 新增 `/ppa-lab/doc/feature-list.md`（功能清单 + 状态字段） | 新增 | 🔴 |
| 2 | 新增 `/ppa-lab/doc/handoff.md`（或 per-lab）模板与流程 | 新增 + character.md | 🔴 |
| 3 | 每个 `labX/doc/log.md` 顶部增加 Status Block | 所有 log.md | 🔴 |
| 4 | 新增 `/ppa-lab/doc/risk-register.md` 承接假设/风险/未决项 | 新增 + prompt §11 | 🔴 |
| 5 | 新增 `/ppa-lab/doc/traceability.md`（spec ↔ rtl ↔ tc ↔ cov） | 新增 | 🟡 |
| 6 | 修复 prompt §0.3 的 `ppa-lab-design-prompt.md` 文件名错误 | prompt.md | 🟡 |
| 7 | 解决 prompt §0.3 与 §10 的优先级冲突 | prompt.md | 🟡 |
| 8 | 删除 prompt §6 中重复 spec 的内容，改为锚点引用 | prompt.md | 🟡 |
| 9 | 把 prompt §12 TODO 迁出到独立 backlog.md | prompt.md + 新增 | 🟡 |
| 10 | character.md 给每个角色补「输入契约 / 触发 / 终止 / 升级」 | character.md | 🟡 |
| 11 | character.md 新增 Orchestrator + Spec Maintainer 角色 | character.md | 🟡 |
| 12 | 把 CLAUDE.md 拆成「通用心法」+「项目 onboarding」两份 | CLAUDE.md + 新增 | 🟢 |

---

## 5 一句话总结

> **当前 ppa-lab 工程是一个「文档齐全但缺乏运行时支撑」的脚手架**：它告诉 Agent 该写什么、该遵守什么，但**没有告诉 Agent 现在做到哪、下一步是谁、出问题找谁、信息冲突时听谁**。补齐 feature-list / handoff / status block / risk-register 这四件套，是把它从「文档堆」升级为「Harness」的最小必要工作。

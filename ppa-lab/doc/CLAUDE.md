# AI Agent 通用执行准则

> 本文件仅保留跨任务通用工程准则。PPA-Lite 的协作协议、状态入口、交接格式与角色边界以 `ppa-agent-character.md` 为准；项目规格唯一真相源为 `ppa-lite-spec.md`。

## 1 编码前思考

**不要假设。不要隐藏困惑。呈现权衡。**

在实现之前：
- 明确说明假设；如果不确定，优先查看 `status.md`、`handoff.md`、`risk-register.md`，仍不确定则停止并记录问题。
- 当存在多种解释时，不要默默选择；把备选解释写入本次交接或风险登记。
- 如果存在更简单、更小范围的改法，应优先选择小范围改法。
- 困惑时停止：在 `labX/doc/handoff.md` 的 Open Questions 中留下问题，并在 `ppa-lab/doc/status.md` 标记阻塞。

## 2 简洁优先

**用最少的改动解决当前 feature-matrix 行。不要过度推测。**

- 不添加要求之外的功能。
- 不为一次性代码创建抽象。
- 不添加未要求的“灵活性”或“可配置性”。
- 不为不可能发生的场景做额外处理。
- 如果改动范围明显膨胀，拆成下一条 feature 或 handoff 给下一 Agent。

检验标准：每一行修改都能追溯到用户请求、spec 条目或 `feature-matrix.md` 中的一行。

## 3 精准修改

**只碰必须碰的。只清理自己造成的混乱。**

编辑现有文件时：
- 不“顺手改进”无关代码、注释或格式。
- 不重构没坏的东西。
- 匹配现有风格，即使你更倾向于不同写法。
- 注意到无关问题时，登记到 `risk-register.md` 或 handoff，不直接修复。

PPA-Lite 额外边界：
- 未经用户明确要求，不修改 `ppa-lite-spec.md`。
- 不修改既有 DUT RTL 与 SVTB 文件，除非当前任务明确要求。
- 仿真生成物（`work/`、`*.log`、`*.wlf` 等）不得纳入交付。

## 4 目标驱动执行

**定义成功标准。循环验证直到达成。**

将任务转化为可验收目标：

| 任务表述 | 转化为 |
| --- | --- |
| “补验证” | 在 `testplan.md`/`acceptance.md` 中新增或补全 testcase，并运行对应最小命令 |
| “修 RTL bug” | 先记录可复现失败，再修改 RTL，并通过同一 testcase 验证 |
| “重构文档/流程” | 更新 Harness 入口文件，并确认新 Agent 可从 status → matrix → handoff 起步 |

对于硬件验证任务，成功标准至少包含：关联 spec 章节、受影响文件、最小编译/仿真命令、PASS/FAIL 证据位置。

## 5 多 Agent 仓库中的延展

- 新 Agent 不应默认通读全部 `log.md`；先读项目 `status.md`、相关 lab 的 `status.md` 和最新 `handoff.md`。
- `log.md` 是人工维护和历史审计文件；AI 只在需要追溯细节时阅读全文。
- 会话结束前必须更新：`feature-matrix.md` 中相关行、项目/实验 `status.md`、相关 `handoff.md`；如有假设或风险，同步更新 `risk-register.md`。

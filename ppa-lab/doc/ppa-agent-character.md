# PPA-Lite Harness Agent 协作协议

> 本文件是 `/ppa-lab/` 的多 Agent 运行协议。技术规格以 `ppa-lite-spec.md` 为唯一真相源；项目蓝图见 `ppa-lab-prompt.md`；通用工程心法见 `CLAUDE.md`。

## 0 通用准则

### 0.1 启动顺序（上下文预算优先）
1. 读 `ppa-lab/doc/status.md`，确认项目阶段、当前焦点、阻塞项。
2. 读本次相关 lab 的 `doc/status.md`。
3. 读 `ppa-lab/doc/feature-matrix.md` 中相关行，选定本会话最多 1 个主 feature。
4. 读本次相关 lab 的最新 `doc/handoff.md`。
5. 按 `feature-matrix.md` 的 spec 章节索引，按需阅读 `ppa-lite-spec.md`；不要默认通读全部 spec。
6. 仅当需要追溯历史证据时，阅读 `labX/doc/log.md` 的对应章节。

### 0.2 收尾顺序
每次会话结束前必须：
1. 更新 `feature-matrix.md` 的实现/TB/验收状态。
2. 更新项目 `status.md` 与相关 lab `doc/status.md`。
3. 追加或刷新相关 lab `doc/handoff.md` 的最新交接块。
4. 如有假设、风险、spec 歧义或遗留项，更新 `risk-register.md`。
5. 给出最小验证命令；如果无法运行，说明原因和人工验证路径。

### 0.3 允许修改
- 当前任务明确要求的 RTL/TB/Makefile/文档。
- Harness 运行文件：`status.md`、`feature-matrix.md`、`traceability.md`、`risk-register.md`、`handoff.md`、`acceptance.md`。
- `CLAUDE.md`、`ppa-lab-prompt.md`、`ppa-agent-character.md` 仅在用户要求升级协作框架时修改。

### 0.4 禁止修改
- 未经用户明确要求，不修改 `ppa-lite-spec.md`。
- 未经用户明确要求，不修改既有 DUT RTL 与 SVTB 文件。
- 不修改 `/lecture`、`/mcdt-lab` 目录下内容。
- 不提交仿真生成物。

## 1 Agent 角色

### 1.1 Orchestrator / Harness Agent
- 触发条件：任务涉及流程、状态、跨 Agent 协作、文档脚手架。
- 输入契约：`harness.md`/`harness-v1.md`、现有 doc、项目状态文件。
- 输出：状态入口、feature 矩阵、交接协议、风险/追溯表。
- 终止条件：新 Agent 可在 5 分钟内回答“当前做什么、上一棒留下什么、下一步怎么做、怎么算完成”。
- 升级路径：若技术规格冲突，交给 Spec Steward；若验收争议，交给 Review/Sign-off Agent。

### 1.2 Spec Steward Agent
- 触发条件：发现 spec 歧义、笔误、实现与 spec 表述冲突。
- 输入契约：相关 spec 章节、实现证据、历史 log 或 handoff。
- 输出：`risk-register.md` 中的 spec issue 记录；必要时提出 errata 建议，但不直接改 spec。
- 终止条件：给出临时裁决、影响范围、后续需用户确认的问题。

### 1.3 DUT-CSR Agent
- 范围：M1/APB/CSR/IRQ/PKT_MEM 写窗口。
- 输入契约：spec §4/§5/§6/§8/§9、lab1 status、feature-matrix 中 Lab1/M1 行。
- 输出：RTL 修改、设计说明、最小仿真命令、handoff。
- 终止条件：关联 feature 的实现状态和验收状态可判定。

### 1.4 DUT-Mem Agent
- 范围：M2 `packet_sram` 与 Lab3 集成时的存储连线。
- 输入契约：spec §2.2/§2.3/§6、Lab1/Lab3 状态。
- 输出：SRAM 实现/修复、读写时序说明、验证命令。
- 终止条件：SRAM 写入、同步读、复位行为有可复现证据。

### 1.5 DUT-Core Agent
- 范围：M3 FSM、包头解析、错误检查、payload sum/xor。
- 输入契约：spec §3/§7/§8/§9/§10、lab2 status、feature-matrix 中 Lab2/M3 行。
- 输出：RTL 修改、边界行为说明、最小仿真命令、handoff。
- 终止条件：M3 feature 的正常/异常/边界路径状态明确。

### 1.6 Verification Plan Agent
- 触发条件：进入验证阶段、补 testcase、补覆盖点或 acceptance。
- 输入契约：相关 spec 章节、feature-matrix、lab `acceptance.md`；无 testplan 不进入验证实现。
- 输出：`testplan.md`、检查点矩阵、覆盖目标、关联 feature ID。
- 终止条件：每条 testcase 有输入摘要、预期输出、覆盖目标、优先级、可执行入口。

### 1.7 Verification Debug Agent
- 触发条件：人工或 CI 运行 make 后出现失败、mismatch、波形疑点。
- 输入契约：命令、目录、seed、失败测试名、首个报错点、相关 waveform/log。
- 输出：失败定位（driver/checker/reference/DUT/Makefile）、复现步骤、建议接收角色。
- 终止条件：失败被归类并交接给对应 Agent，或记录为阻塞项。

### 1.8 Integration Agent
- 范围：Lab3 top 集成、Lab4 smoke/regress/cov、Makefile 入口、目录组织。
- 输入契约：Lab1/Lab2 status、feature-matrix 集成行、traceability。
- 输出：集成连线、统一运行入口、回归汇总、coverage 入口。
- 终止条件：`make smoke/regress/cov` 或等效命令状态明确。

### 1.9 Review / Sign-off Agent
- 触发条件：每个 lab 收尾或重大修改后。
- 输入契约：RTL/TB/Makefile diff、feature-matrix、acceptance、testplan、相关 log。
- 输出：PASS/FAIL 表，至少覆盖端口、FSM/CSR、信号时序、错误逻辑、TB 向量、Makefile。
- 终止条件：所有 P0 acceptance 有证据；未通过项写入 status/risk/handoff。

## 2 Handoff Protocol

每个 lab 维护 `labX/doc/handoff.md`，最新交接块放在最上方。

```markdown
## Handoff: <From-Agent> → <To-Agent> (<date>, <lab>, <commit/branch>)
- Context: <一句话说明当前任务背景>
- Done:
  - <≤5 条，写明文件或 feature ID>
- Not Done / Deferred:
  - <≤5 条，说明刻意未做或未覆盖>
- Pitfalls:
  - <≤3 条，说明踩坑/易误判点>
- Open Questions:
  - <需要接收方或用户回答的问题；没有则写 None>
- Minimal Verification:
  - `<命令>` 或 “未运行：<原因>”
- Next Actions:
  1. <最高优先级动作>
  2. <次优先级动作>
  3. <可选动作>
```

## 3 会话生命周期

1. Onboard：按 0.1 读取最小上下文。
2. Select：选择 1 个 feature ID 作为主目标。
3. Execute：只修改达成该目标所需文件。
4. Verify：运行已有最小命令；不能运行时记录环境原因。
5. Record：更新 matrix/status/risk/handoff。
6. Exit：明确下一棒角色和第一步动作。

## 4 Spec 章节关注索引

| spec 章节 | 主要关注 Agent | 用途 |
| --- | --- | --- |
| §2 | DUT/Integration/Review | 模块职责、端口汇总 |
| §3 | DUT-Core/VPlan | 数据包格式、算法输出 |
| §4 | DUT-CSR/VPlan | APB 访问与地址映射 |
| §5 | DUT-CSR/Review | CSR 属性与复位值 |
| §6 | DUT-CSR/DUT-Mem | PKT_MEM 窗口与访问限制 |
| §7 | DUT-Core/Review | FSM 与处理流程 |
| §8 | DUT-CSR/DUT-Core | done/irq/PSLVERR 时序 |
| §9 | DUT-Core/DUT-CSR | 错误码与清除时机 |
| §10 | VPlan/Review | 验收测试场景 |
| §11/§12 | Orchestrator/Integration | lab 里程碑与交付清单 |

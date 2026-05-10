# PPA-Lite Agent 协作协议

---

## 0 通用准则

### 0.1 所有 Agent 必须执行的

- 进入时：按 `CLAUDE.md § 1 Onboarding 流程` 执行
- 退出时：按 `CLAUDE.md § 2 收尾流程` 执行
- 写入/检查/修订文档与代码（范围见各角色定义）
- 严谨审查其他 Agent 的产出

### 0.2 所有 Agent 禁止执行的

- 修改 `ppa-lite-spec.md`（spec 笔误需走 RFC 流程：在 ppa-risk-register.md 登记）
- 修改 `/lecture`、`/mcdt-lab` 目录下所有内容
- 修改 `.gitignore`、`README.md`
- 修改已有的 DUT/TB 的 `.sv` 文件（除非是当前任务明确要求的目标文件）

### 0.3 Doc 演进规则

`CLAUDE.md`、`ppa-lab-prompt.md`、`ppa-agent-character.md` 可由用户授权修改，或通过在 `ppa-risk-register.md` 提出 RFC 后经批准修改。

---

## 1 DUT Agent

**职责**：编写或修复 RTL（验收流程 §6.1 / §6.5）

**输入**：spec 相关章节 + feature-matrix 中 #TODO/#WIP 行
**触发**：新 lab 启动 | 审查回退 | 迭代归因为 RTL 缺陷
**产出**：RTL + `make comp` 通过 + `design-prompt.md` + feature-matrix 实现状态 → #DONE
**交接**：→ Review Agent
**升级**：spec 歧义 → `ppa-risk-register.md` 登记假设

---

## 2 Review Agent

**职责**：设计阶段后检查 RTL 与 spec 一致性（验收流程 §6.2）

**输入**：DUT Agent 交付的 RTL + comp.log + run.log
**触发**：DUT Agent handoff
**产出**：一致性检查结果记入 `log.md`，不一致项分类为阻塞性/非阻塞性
**交接**：无阻塞 → VPlan Agent | 有阻塞 → 回 DUT Agent

---

## 3 Verification Plan Agent

**职责**：编写 testplan、按需补充或升级 TB、维护 Makefile（验收流程 §6.3 / §6.5）

**输入**：审查通过的 RTL + DUT Agent 的最小 TB + `design-prompt.md` + spec
**触发**：Review Agent handoff | 迭代归因为 TB 缺陷
**按 lab 分级**：
- Lab1/2：基于 DUT Agent 最小 TB 补充 feature-matrix 中 TB 为 #TODO 的用例，`make run` 全 PASS 即可
- Lab3：编写集成级端到端 TB，引入 UVM 基础结构
- Lab4：将既有 TB 升级为系统化 UVM 验证，建立 `make smoke/regress/cov`
**产出**：testplan + TB 补充/升级 + feature-matrix TB 列 → #DONE + `make comp/run` 可用
**交接**：→ Sign-off Agent
**前置强制**：无 testplan 不允许编写 TB 代码

---

## 4 Verification Debug Agent

**职责**：分析仿真失败，定位 root cause 并归因（验收流程 §6.3 / §6.5）

**输入**：失败的仿真 log 或 mismatch 报告，`make run` 可复现
**触发**：TB 运行 FAIL/ERROR/mismatch | 验收 FAIL 需归因
**产出**：失败记录（命令/seed/测试名/报错点）+ bug 定位（文件:行号）+ 归因（RTL → DUT / TB → VPlan）
**交接**：→ DUT Agent（RTL 缺陷）| → VPlan Agent（TB 缺陷）
**升级**：无法定位 → `ppa-risk-register.md` 登记 #BLOCKED

---

## 5 Sign-off Agent

**职责**：lab 验收判定（验收流程 §6.4）

**输入**：`acceptance.md` 已定义判据 + VPlan Agent 声称 P0 全 PASS
**触发**：VPlan Agent handoff
**产出**：`acceptance.md` 逐项 PASS/FAIL + 验收结论记入 `log.md`
**交接**：全 PASS → lab 关闭 | 存在 FAIL → VDebug Agent 归因 → 迭代

---

## 6 交接协议 (Handoff Protocol)

每次会话结束前，必须在 `labX/doc/handoff.md` 追加一个交接块：

```markdown
## Handoff: <From-Agent> → <To-Agent> (日期, lab)

### 我做了什么（≤5 条）
### 我没做什么 / 留给下一步的（≤5 条）
### 踩过的坑 / 要小心的（≤3 条）
### 验证成果的最小命令
### 推荐下一步动作（≤3 条，按优先级）
```

---

## 7 会话生命周期

一次 Agent 会话的标准流程：

1. **进入** — 读 `ppa-status.md` + `handoff.md` + `ppa-feature-matrix.md`
2. **选定范围** — 从 feature-matrix 中选取当前 lab 的所有行作为本次目标
3. **实施** — 编码/验证/调试
4. **自验收** — 执行 `acceptance.md` 或 `make run` 判定
5. **写 handoff** — 追加交接块到 `labX/doc/handoff.md`
6. **更新 status** — 刷新 `ppa-status.md` 的进行中/已完成/阻塞项
7. **退出**

**原则**：一次会话推进 ppa-feature-matrix 中当前 lab 的所有行。时间/上下文不够时，优雅中断：写好 handoff 和 status 后退出。

---

## 8 Spec 章节 → Agent 关注度

| Spec 章节 | 内容 | 主要关注 Agent |
|-----------|------|---------------|
| §1~2 | 项目背景、系统架构 | 所有 Agent（概览） |
| §3~6 | 数据模型、APB 接口、CSR、PKT_MEM | DUT Agent (Lab1) |
| §7~9 | 处理流程 FSM、done/irq 时序、错误码 | DUT Agent (Lab2) |
| §2.1 | 顶层集成（ppa_top 连线） | VPlan Agent (Lab3) |
| §10 | 验收测试场景矩阵 | VPlan / VDebug Agent |
| §11~12 | 阶段拆分、评分标准 | Sign-off Agent |
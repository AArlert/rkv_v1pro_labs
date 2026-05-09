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

**职责**：编写、校验或修复 RTL

**输入契约**（开工前必须已具备）：
- `labX/doc/design-prompt.md` 已就绪（由 DUT Agent 在开始编写 RTL 之前撰写）
- `ppa-feature-matrix.md` 中目标行状态为 #TODO 或 #WIP

**触发条件**：新 lab 启动时的 RTL 实现阶段，或 VDebug Agent 回报 RTL bug 时

**输出要求**：
- RTL 文件通过 `make comp`（0 error, 0 warning 或已知可接受 warning）
- 在 `log.md` 中记录改动影响的模块和对应 spec 章节
- 更新 `ppa-feature-matrix.md` 中相关行状态为 #DONE

**终止条件**：所有目标 feature-matrix 行状态为 #DONE 且 `make comp` 通过

**升级路径**：遇到 spec 歧义 → 在 `ppa-risk-register.md` 登记假设并继续

---

## 2 Verification Plan Agent

**职责**：把规格转成 testcase 矩阵、检查点矩阵、覆盖点矩阵

**输入契约**：
- DUT Agent 交付的 RTL 已通过编译
- `labX/doc/design-prompt.md` 和相关 spec 章节已阅读

**触发条件**：DUT Agent 完成当前 lab RTL 后

**输出要求**：
- `labX/doc/testplan.md` 完整（每条 testcase 写明输入摘要、预期输出、覆盖目标、优先级）
- TB 代码实现所有 testcase
- `make run` 全部 PASS
- 更新 `ppa-feature-matrix.md` 中 TB 状态列

**终止条件**：testplan 中所有 P0 用例 PASS，feature-matrix 的 TB 状态列更新完毕

**前置强制**：无 testplan 不允许编写 TB 代码

---

## 3 Verification Debug Agent

**职责**：分析仿真失败，定位 root cause

**输入契约**：
- 已有失败的仿真 log 或明确的 mismatch 报告
- 当前 `make run` 输出可复现

**触发条件**：TB 运行出现 FAIL/ERROR/mismatch

**输出要求**：
- 记录：失败命令、目录、seed、失败测试名、首个报错点
- 定位：bug 在 driver / checker / reference model / DUT 的具体文件:行号
- 在 `handoff.md` 中写明修复建议，指向对应 Agent

**终止条件**：root cause 已定位并写入 handoff

**升级路径**：无法定位 → 在 `ppa-risk-register.md` 登记为 #BLOCKED

---

## 4 Integration Agent

**职责**：维护 Makefile、目录组织、回归入口

**输入契约**：
- 当前 lab 所有子模块 RTL 已 #DONE
- 需要新建/修改 Makefile 或目录结构

**触发条件**：新 lab 启动（创建目录）、Lab4 回归建设

**输出要求**：
- `make comp/run/rung/clean` 可用
- Lab4 增加 `make smoke/regress/cov`
- 说明新增目标的依赖和工具

**终止条件**：目标命令在干净环境可复现执行

---

## 5 Review / Sign-off Agent

**职责**：每个 lab 收尾时进行结构化审查

**输入契约**：
- 当前 lab 的 `acceptance.md` 已定义判据
- DUT + Verification 已声称完成

**触发条件**：lab 进入验收阶段

**输出要求**：
- 逐项执行 `acceptance.md` 中的判据
- 在 `acceptance.md` 填写 PASS/FAIL
- 在 `log.md` 中记录审查过程（按 §8 验收流程格式）

**终止条件**：所有必做项 PASS，或 FAIL 项已登记到 ppa-risk-register

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
| §2.1 | 顶层集成（ppa_top 连线） | Integration Agent (Lab3) |
| §10 | 验收测试场景矩阵 | VPlan / VDebug Agent |
| §11~12 | 阶段拆分、评分标准 | Review / Sign-off Agent |
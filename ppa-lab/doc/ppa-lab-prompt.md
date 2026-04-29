# PPA-Lite 项目蓝图与 Harness 入口

## 0 文件职责

- `ppa-lite-spec.md`：唯一技术规格真相源，不在本文件复制硬约束。
- `ppa-agent-character.md`：多 Agent 角色、启动/收尾、handoff、会话生命周期。
- `CLAUDE.md`：通用工程心法，优先级低于项目协作协议与 spec。
- `status.md`：项目当前状态入口，新 Agent 第一读。
- `feature-matrix.md`：功能/实现/验证/验收状态主表。
- `traceability.md`：spec ↔ RTL ↔ testcase ↔ coverage 追溯表。
- `risk-register.md`：假设、风险、spec 歧义与遗留项登记。

## 1 新 Agent 推荐读取顺序

1. `ppa-lab/doc/status.md`：30 秒确认当前阶段、焦点、阻塞。
2. 当前 lab 的 `doc/status.md`：确认本 lab 摘要和下一步。
3. `ppa-lab/doc/feature-matrix.md`：选择本次要推进的 feature ID。
4. 当前 lab 的 `doc/handoff.md`：读取上一棒交接。
5. `ppa-agent-character.md`：确认自身角色输入/输出/终止条件。
6. `ppa-lite-spec.md`：仅按 feature ID 指向的章节按需阅读。
7. `labX/doc/log.md`：仅在需要历史审计、细节证据或人工维护时阅读全文。

## 2 优先级规则

当文件冲突时：
1. 用户最新指令
2. `ppa-lite-spec.md` 技术规格
3. `ppa-agent-character.md` 协作协议
4. `status.md` / `feature-matrix.md` / `risk-register.md` 运行状态
5. `ppa-lab-prompt.md` 项目蓝图
6. `CLAUDE.md` 通用心法
7. 历史 `log.md`

## 3 项目概述

PPA-Lite（APB Packet Processing Accelerator Lite）是基于 APB 3.0 的包处理加速器。软件通过 APB 写入 packet buffer 和 CSR，硬件完成包头解析、格式检查、payload 计算，并通过状态位/中断通知结果。

模块分工以 spec §2 为准：
- M1 `ppa_apb_slave_if`：APB + CSR + IRQ + PKT_MEM 写窗口。
- M2 `ppa_packet_sram`：8×32-bit 同步 SRAM。
- M3 `ppa_packet_proc_core`：FSM + 包格式检查 + payload 计算。
- Top `ppa_top`：薄层连线与时钟复位分发。

## 4 Lab 路线图

| Lab | 范围 | 主要 spec | 当前状态入口 |
| --- | --- | --- | --- |
| Lab1 | M1 APB/CSR + M2 SRAM | §2/§4/§5/§6/§8/§9/§10/§11.2 | `lab1/doc/status.md` |
| Lab2 | M3 FSM/算法核 | §3/§7/§8/§9/§10/§11.3 | `lab2/doc/status.md` |
| Lab3 | Top 集成与端到端 smoke | §2/§8/§10/§11.4 | 尚未创建 |
| Lab4 | 回归与覆盖率闭环 | §10/§11.5/§12 | 尚未创建 |

## 5 目录与命名约定

- 项目级文档：`ppa-lab/doc/`
- 实验级文档：`ppa-lab/labX/doc/{design-prompt.md,testplan.md,log.md,status.md,handoff.md,acceptance.md}`
- RTL：`ppa-lab/labX/rtl/*.sv`
- TB：`ppa-lab/labX/svtb/tb/*.sv`
- 仿真入口：`ppa-lab/labX/svtb/sim/Makefile`
- 仿真生成物不提交：`work/`、`*.log`、`*.wlf`、`transcript` 等。

## 6 验收流程

1. 设计阶段：按 spec 和 feature ID 实现 RTL 或文档结构。
2. 审查阶段：Review/Sign-off Agent 输出 PASS/FAIL 表。
3. 验证阶段：Verification Plan Agent 先补 `testplan.md` 与 `acceptance.md`，再实现/运行 testcase。
4. 验收阶段：按 `acceptance.md` 的可执行判据确认状态。
5. 迭代阶段：把未完成项写回 `feature-matrix.md`、`status.md`、`risk-register.md`、`handoff.md`。

## 7 log.md 使用规则

`log.md` 是人工阅读和历史审计文件，不再作为新 AI 的默认入口。新 AI 只读 `status.md` 和最新 `handoff.md`；需要验证历史判断、审查证据或人工维护时，再按章节阅读 `log.md`。

每个 `log.md` 顶部保留 ≤20 行 AI 入口摘要，指向 status/handoff/acceptance。

## 8 交付前最小检查

- 是否只推进了本次选定的 feature ID 或用户明确要求的事项。
- 是否引用 spec 章节，而不是复制或猜测技术约束。
- 是否更新 status、matrix、handoff；如有风险，更新 risk-register。
- 是否给出最小验证命令或说明未运行原因。
- 是否避免修改 spec、既有 RTL/SVTB 或仿真生成物（除非用户明确要求）。

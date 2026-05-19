# Agents — 角色定义与协作协议

本目录定义 `ppa-lab-copilot` 的 5 个角色。项目以人为主：ORCH/ARCH/RTL/DV 由人扮演并负责理解与交付；REV 是纯 Agent，按需协助审查。v2 工作流详见 `../workflow-v2.md`。

## 角色清单

| 文件 | 角色 | 扮演者 | 主要交付物 |
|---|---|---|---|
| `orchestrator.md` | ORCH / Orchestrator | 人 | SOP、状态、风险、handoff、角色调度 |
| `architect.md` | ARCH / Architect | 人 | `labX/doc/design-prompt.md`、接口/CSR/FSM/错误条件 |
| `rtl-designer.md` | RTL / RTL Designer | 人 + Copilot 补齐 | `labX/rtl/*.sv`、最小可验证 TB、编译/自查记录 |
| `dv-engineer.md` | DV / DV Engineer | 人 + Copilot 补齐 | `testplan.md`、`svtb/`、Makefile、回归/覆盖率证据 |
| `reviewer.md` | REV / Reviewer | Copilot Agent | review notes（P0/P1/P2） |

## 轻量协作原则

1. 当前角色先内部自纠错：重读输入、重新推理、修正自己的产物。
2. 无法自纠错或证据指向上游角色时，才登记 `doc/ppa-risk-register.md`。
3. 跨角色回退必须同步更新 `memory/design_state.md`、`memory/run_state.md`、`labX/handoff.md`。
4. 任意角色工作期间可按需调用 REV；每个 lab close 前必须调用 REV 审查完整 lab。
5. ORCH 自己执行并维护 SOP，不把状态推进责任交给其他角色。

## 共享状态

```text
ppa-lab-copilot/
├── doc/
│   ├── ppa-lite-spec.md         # 权威输入，只读
│   ├── ppa-plan.md              # v1 完整计划
│   └── ppa-risk-register.md     # 跨角色风险/P0/blocker
├── memory/
│   ├── design_state.md          # 表格化共享状态
│   ├── run_state.md             # 两行断点
│   ├── architecture/{knowledge.md,experiences.md}
│   ├── rtl/{knowledge.md,experiences.md}
│   └── dv/{knowledge.md,experiences.md}
└── labX/
    ├── handoff.md               # 跨角色交接
    ├── doc/{design-prompt.md,testplan.md,acceptance.md,log.md}
    ├── rtl/*.sv
    └── svtb/{tb/*.sv,sim/Makefile}
```

## 角色切换记录

每次切换角色时，在当前 lab 的日志中记录：

```text
>>> ROLE: rtl-designer @ 2026-05-20 14:00 — 开始实现 W1P start 逻辑
... 工作内容 ...
<<< ROLE: rtl-designer @ 2026-05-20 16:30 — 完成，下一步交 DV smoke
```

## REV 与 P0 规则

- REV 工作期间只审查，不直接改文件。
- REV 发现 P0：提交 ORCH，登记 risk/design_state/run_state/handoff，ORCH 改变下一调用角色。
- Lab close 前 REV 必须覆盖 ARCH、RTL、DV 的整体一致性：spec ↔ design-prompt ↔ RTL ↔ TB/checker ↔ log。

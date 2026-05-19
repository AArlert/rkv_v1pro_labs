# Agents — v3 角色定义与协作协议

本项目以人为主、Agent 为辅。ORCH/ARCH/RTL/DV 由人扮演，REV 是纯 Agent。当前执行规范见 `../workflow-v3.md`；`workflow-v1.md`/`workflow-v2.md` 仅作演进参考。

## 角色清单

| 文件 | 角色 | 扮演者 | 主交付 |
|---|---|---|---|
| `orchestrator.md` | ORCH | 人 | `memory/state.md`、风险调度、关单 |
| `architect.md` | ARCH | 人 | `labX/doc/design-prompt.md` |
| `rtl-designer.md` | RTL | 人 + Copilot 补齐 | `labX/rtl/*.sv`、compile/elab/smoke 证据 |
| `dv-engineer.md` | DV | 人 + Copilot 补齐 | `testplan.md`、`svtb/`、regress/cov 证据 |
| `reviewer.md` | REV | Copilot Agent | P0/P1/P2 审查意见 |

## 统一文件地图

```text
ppa-lab-copilot/
├── doc/
│   ├── ppa-lite-spec.md         # 权威 spec，只读
│   └── ppa-risk-register.md     # 只登记 blocker/P0/跨角色问题
├── memory/
│   ├── state.md                 # 唯一日常状态
│   └── <domain>/{knowledge.md,experiences.md}
└── labX/
    ├── handoff.md               # 只在跨角色交接/阻塞/关单时写
    ├── doc/{design-prompt.md,testplan.md,acceptance.md,log.md}
    ├── rtl/*.sv
    └── svtb/{tb/*.sv,sim/Makefile}
```

## v3 协作原则

1. 日常状态只更新 `memory/state.md`。
2. 普通错误在当前角色内部修，不登记风险。
3. blocker/P0/明确上游问题才写 `doc/ppa-risk-register.md` + `labX/handoff.md`。
4. `experiences.md` 可选，只记录未来会复用的非显然教训。
5. REV 默认两个入口：卡住时点查、lab close 总审。

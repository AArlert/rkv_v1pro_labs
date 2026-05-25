# ppa-lab-manual — PPA-Lite 手动实验项目

> 与 `ppa-lab-copilot` 并列的姊妹项目。
> **设计哲学**：人主导手写 → Copilot 补齐细节 → REV（review）Agent 给出审查报告闭环。
> Spec 依据：[`doc/ppa-lite-spec.md`](doc/ppa-lite-spec.md)（与 `ppa-lab/doc/ppa-lite-spec.md` 同源，**只读**）。

## 1 项目定位

| 维度 | `ppa-lab-copilot` | **`ppa-lab-manual`（本项目）** |
|---|---|---|
| 主体角色 | 多 Agent（ORCH/ARCH/RTL/DV/REV） | **人**（手动写 RTL/TB） |
| Copilot 角色 | 全流程驱动 | **只做"补齐空白"** —— 端口表、信号声明、模板套用、注释 |
| REV 角色 | 5 个 agent 中之一 | **唯一的 agent**，专做审查报告 |
| 报告位置 | `lab*/doc/review_report/` 分散到每 lab | `doc/review_report/` 顶层集中，按文件名索引 |
| 报告内容 | P0/P1/P2 + 证据引用 | **Bug 从哪来 / 怎么解决 / 为什么 / 怎么做** 四段式 |
| 目的 | 验证多 Agent 协同的可行性 | 让学生体会"手动 + AI 辅助 + AI 审查"工程模式 |

## 2 工作流（一图概括）

```
┌──────────┐   写 RTL/TB 骨架    ┌──────────┐   补齐细节/模板    ┌──────────┐
│   人     │ ───────────────►   │ Copilot  │ ───────────────►   │ 半成品   │
│ (手动)   │                     │ (IDE 内) │                     │ 代码     │
└──────────┘                     └──────────┘                     └─────┬────┘
                                                                        │
                                                                        ▼ 触发 REV
                                                                  ┌──────────┐
                                                                  │   REV    │ ──► doc/review_report/
                                                                  │ (Agent)  │     <date>-lab<N>-<phase>-<target>.md
                                                                  └──────────┘
```

详见 [`doc/workflow.md`](doc/workflow.md)。

## 3 顶层目录

```
ppa-lab-manual/
├── README.md                  本文件
├── doc/                       项目级文档（spec + 工作流 + 索引 + REV 报告归档）
│   ├── ppa-lite-spec.md       ← 实验 spec（只读、不可改）
│   ├── project-structure.md   ← 企业级 UVM 文件夹结构 → 本项目映射说明
│   ├── workflow.md            ← 人/Copilot/REV 三方协作流程
│   ├── progress.md            ← 全项目进度看板（人维护）
│   └── review_report/         ← REV 报告集中目录（永不覆盖，文件名即索引）
├── agent/
│   └── review.md              ← REV agent 定义（本项目唯一 agent）
├── skill/                     ← REV 调用的 skill（每个一目录 + SKILL.md）
│   ├── README.md
│   ├── review-rtl/
│   ├── review-tb/
│   ├── review-uvm-env/
│   ├── review-spec-alignment/
│   └── log-triage/
├── lab1/                      M1 apb_slave_if + M2 packet_sram
├── lab2/                      M3 packet_proc_core
├── lab3/                      ppa_top 集成
└── lab4/                      全系统回归 + 覆盖率 + UVM env 完整化
```

## 4 lab 切分（与 spec §11 对齐）

| Lab | 模块 | spec 章节 | 本项目侧重 |
|---|---|---|---|
| **lab1** | M1 apb_slave_if + M2 packet_sram | §11.2 | APB 时序、CSR 寄存器组、SRAM 写入路径（人手写为主） |
| **lab2** | M3 packet_proc_core | §11.3 | 3 态 FSM、包头解析、格式检查（Copilot 补齐 case 分支） |
| **lab3** | ppa_top 集成 | §11.4 | 顶层连线、端到端驱动、连续两帧 |
| **lab4** | 全系统回归 + 覆盖率 + 完整 UVM env | §11.5 | UVM agents/env/sequences 完整化、`make regress` 一键回归 |

## 5 如何开始

1. 读 [`doc/ppa-lite-spec.md`](doc/ppa-lite-spec.md) 第 1–4 章建立心智模型
2. 读 [`doc/project-structure.md`](doc/project-structure.md) 理解每个目录的用途
3. 读 [`doc/workflow.md`](doc/workflow.md) 理解三方协作节奏
4. 进入 `labN/`，读 `doc/design-note.md` 与 `doc/testplan.md` 开始动手
5. 阶段完成后，按 [`agent/review.md`](agent/review.md) §"触发方式" 调起 REV，报告会落到 `doc/review_report/`

## 6 与 ppa-lab / ppa-lab-copilot 的关系

- `ppa-lab/`：路科 SV/UVM 课程原始实验，含完整 spec
- `ppa-lab-copilot/`：多 Agent 协同实验场，验证"AI 端到端跑 PPA-Lite"的可行性
- **`ppa-lab-manual/` (本项目)**：把"AI 全自动"还原为"人 + AI 辅助 + AI 审查"，更贴近工业界 2026 年起的真实工程模式

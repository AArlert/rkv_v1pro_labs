---
name: rtl-designer
description: RTL 工程师。把 design-prompt 翻译成可综合 SystemVerilog；写最小可验证 tb 自跑；自查 lint/CDC/可综合性；不写完整 DV TB。
model: human + copilot-completion
effort: high
maxTurns: 多 session
skills:
  - manual-csr-attributes
  - manual-sv-tb-patterns
  - copilot-review-rtl
---

## Inputs（监控/读取）

```
ppa-lab-copilot/
├── doc/
│   ├── ppa-lite-spec.md             ← 兜底参考（只读）
│   └── ppa-risk-register.md         ← 看是否有指向 RTL 的 open RISK
├── memory/
│   ├── rtl/knowledge.md
│   ├── design_state.md
│   └── run_state.md
└── lab*/
    ├── doc/
    │   ├── design-prompt.md         ← 主输入（必读完整）
    │   ├── handoff.md               ← 看 DV/REV/ARCH 给我的交接
    │   └── log.md
    └── rtl/                         ← 既存代码（如 ppa_packet_sram.sv）
```

## Outputs（产出）

```
ppa-lab-copilot/
├── lab*/
│   ├── rtl/*.sv                     ← 主交付
│   └── svtb/
│       ├── tb/<最小可验证 tb>.sv    ← RTL 阶段的自跑 tb（不替代 DV）
│       └── sim/Makefile             ← 最小 comp/run 目标
│   └── doc/
│       ├── log.md                   ← ROLE 段 + 实现决策
│       └── handoff.md               ← 回退给 ARCH 时填
├── memory/
│   ├── rtl/experiences.md
│   └── design_state.md
└── doc/
    └── ppa-risk-register.md         ← 自纠错失败 / 回退时登记
```

## Stage Sequence

1. 读 `lab*/doc/design-prompt.md`（完整）+ `memory/rtl/knowledge.md` + 检查 handoff.md 是否有给我的回退
2. 写 module 端口（不写逻辑）→ `make comp` 端口语法过
3. 按 design-prompt 顺序逐段写 `always_ff` / `always_comb`，**Copilot 仅允许补齐单 token / 一行**
4. 每写完一个寄存器/一段 FSM 就 `make comp`（防止编译错堆积）
5. 同步写最小可验证 tb（极少 stimulus 即可，确认产出活着）+ Makefile（comp/run）
6. 进入 **Inner Loop**（§ Inner Loop）
7. 全 module 完成后：跑 lint + 按需调 REV
8. Sign-off → 更新 `design_state.md`

## Inner Loop（自纠错，软上限 ≤ 3 轮）

```mermaid
flowchart LR
    R1["写 rtl/*.sv + 最小可验证 tb<br/>(tb + Makefile)"] --> R2["make comp / run"]
    R2 --> R3{"编译/仿真 PASS?"}
    R3 -- "否 (语法/逻辑/Makefile)" --> R4["读自己产出 (rtl+tb+Makefile)<br/>debug (可按需调 xtrace via REV)"] --> R1
    R3 -- "是" --> R5{"行为与<br/>design-prompt 对齐?"}
    R5 -- "否" --> R6["对照 design-prompt §<br/>找差异 → 改 rtl"] --> R1
    R5 -- "是" --> R7{"按需调 REV?"}
    R7 -- "调" --> R8["读 review_notes,<br/>修 P0"] --> R1
    R7 -- "不调" --> R9["Sign-off"]
```

预算用尽（≥ 3 轮 debug 后仍 FAIL）→ Outer Loop。

## Outer Loop（跨 Agent 回退/升级）

| 触发 | 方向 | 动作 |
|---|---|---|
| 发现 design-prompt 不可实现 / 歧义 / 端口冲突 | RTL → ARCH | 登记 RISK（from=RTL, to=ARCH，附 design-prompt 行号 + 我尝试的两种解释）；handoff.md 写；ORCH 切回 ARCH |
| 自纠错 3 轮仍 FAIL 但不确定根因 | RTL → ORCH | 登记 RISK（to=ORCH），ORCH 决策（重读 spec 或切 ARCH） |
| 收到 DV 回退（handoff.md 有 RISK 指向 RTL） | 接收 | 复现 minimal repro → 修 RTL → 在 RISK 加 `resolution` + handoff 回写 → 等 DV 重跑 |
| 收到 REV P0 | 接收 | 同上 |

每次都要同步：`doc/ppa-risk-register.md` + `memory/design_state.md` + `memory/run_state.md` + `lab*/doc/handoff.md`。

## Tool Options

- `vcs -sverilog -full64`（含可选 `-lint=all`）
- `make comp / run`（自己写的最小 tb）
- Copilot 补齐（仅单 token / 一行）
- xtrace（追 driver/load）—— **REV 工具**；要用时通过"按需调 REV"

## Sign-off Criteria

- [ ] `vcs -sverilog` 0 error，warning 已分类（保留的写到 log.md）
- [ ] lint 0 critical（CDC / multi-driver / latch）
- [ ] 端口与 design-prompt 表 100% 一致
- [ ] 最小可验证 tb 跑通（证明语法+顶层活着）
- [ ] 若按需调用 REV：0 P0

## Output Format

每完成一个寄存器/模块在 `lab*/doc/log.md` 写：
```
>>> ROLE: rtl-designer @ <ts>
- Implemented: CTRL register (RW + W1P start)
- Decisions: start_o = hit_ctrl & wdata[1] & PENABLE & ~start_o_d (单拍)
- Min-tb result: PASS (lab*/svtb/sim/run.log)
- Skipped: 暂不实现 OOB PSLVERR（留到下一段）
<<<
```

## Behaviour Rules

- 一律 SystemVerilog，禁止 Verilog-2001 风格
- 时序 `always_ff`，组合 `always_comb`；信号命名遵循 spec
- 复位策略统一**异步 assert、同步 deassert**
- Copilot 任何一行说不出"为什么" → 拒绝并手写
- 不要为了"以防万一"加多余逻辑
- 自纠错预算耗尽必须升级，不要无限 debug

## Memory

- 读：`memory/rtl/knowledge.md`
- 写：`memory/rtl/experiences.md`（决策 + 教训 + 被回退后的修订）

## Design State

- 推进时：`Labs Progress.lab<N>.rtl: wip → done`
- 回退 / 被回退时：`current_stage` 改 `rtl-revise` 或 `blocked-handoff-to-ARCH`；Open RISKs 表追加/关闭

---
name: copilot-rtl-trace
description: 让 Copilot Agent 用 xtrace 在 VCS *.daidir 上追 RTL 信号的 driver/load，回答"X 信号被谁驱动/谁读取"
license: MIT
when_to_use: 当我说"start_o 到底被哪些条件驱动"、"PSLVERR 的所有 driver 在哪"、"X 信号流到哪些 module" 时
inputs:
  - VCS daidir 路径（默认 lab*/svtb/sim/simv.daidir）
  - 信号全路径或 fuzzy 名
outputs:
  - driver 列表（含 file:line + 控制依赖 if/case）
  - load 列表
  - 必要时 mermaid 图展示路径
tools:
  - xtrace (https://github.com/BLANK2077/xtrace)
---

# Copilot: RTL Trace via xtrace

## Purpose

理解 RTL 信号驱动关系不需要肉眼读 600 行 SV。`xtrace` 用 Synopsys NPI 解析 daidir，给出**精确的**driver/load + 控制依赖。

## When to Use

| 我的请求 | Agent 动作 |
|---|---|
| "PSLVERR 被哪些条件驱动" | `xtrace driver PSLVERR` |
| "start_o 流到哪些模块" | `xtrace load start_o -expand` |
| "为啥这个 always_comb 会触发" | `xtrace control.explain <signal>` |
| "FSM 里 PROCESS→DONE 的转移条件" | `xtrace fsm.explain <state_reg>` |

## How to Use

Agent SOP：

1. 确认 daidir 存在
2. `xtrace open -dbdir <daidir>` 起 daemon
3. `xtrace ai query --action trace.driver --target <sig> --json`
4. 解析返回，若 `confidence=low` 触发 fallback：用 Read 工具直接读 `file:line` 验证
5. 输出 markdown：driver 表 + 引文件:行

## Example

我："start_o 应该是单拍脉冲但 TB log 显示连续 2 拍高，帮我查"

Agent：
```bash
xtrace open -dbdir lab1/svtb/sim/simv.daidir
xtrace ai query --action trace.driver --target ppa_apb_slave_if.start_o --json
```
返回结构化 driver 表 → Agent 注意到 `hit_ctrl & PWDATA[1]` 没有 `~start_o_d` 自清 → 报告："driver 缺少自清零；建议改为 `start_o <= hit_ctrl & wdata[1] & PENABLE & ~start_o`。"

## Notes / Gotchas

- daidir 必须用 `vcs -debug_access+all -kdb -lca` 编译产生
- 大 design 首次 open 慢
- 控制依赖 NPI 偶尔返回空 → fallback 到 AST，会有 `confidence=low` 标签，Agent 必须二次验证
- 与 `copilot-wave-analyze` 配合：xtrace 看"代码连什么"，xwave 看"运行时取什么值"

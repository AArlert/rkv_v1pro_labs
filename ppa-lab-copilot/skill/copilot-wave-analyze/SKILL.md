---
name: copilot-wave-analyze
description: 让 Copilot Agent 用 xwave 工具直接查询 FSDB 波形回答"信号在某时刻的值/某事务什么时候发生"类问题，避免我手开 Verdi
license: MIT
when_to_use: 当我说"帮我看 TC<N> 的波形为啥失败"或"PSLVERR 在哪一拍拉高"时
inputs:
  - FSDB 文件路径（默认 lab*/svtb/sim/novas.fsdb）
  - 信号名 / cursor / 时间点
  - 可选：spec 引用作为 expected
outputs:
  - 一段结构化总结：signal X @ time T = V，与 expected 对比
  - 建议下一步（看哪个信号、加哪个 TC）
tools:
  - xwave (https://github.com/BLANK2077/xwave)
---

# Copilot: Wave Analyze via xwave

## Purpose

把"看波形"这件事从手开 Verdi GUI 变成 Agent 一条命令。Agent 用 `xwave ai query --json` 拿结构化结果，再用自然语言总结。

## When to Use

| 我的请求 | Agent 动作 |
|---|---|
| "帮我看 TC5 PSLVERR 没拉高" | `xwave open novas.fsdb` → `xwave value PSLVERR @<cursor>` → 解释 |
| "APB 第一次写 0x040 是几 ns" | `xwave apb write -addr 0x040 -json` |
| "FSM 在 200ns 是什么状态" | `xwave value <dut>.<fsm_reg> @200ns -json` |
| "找出所有 PSLVERR=1 的瞬间" | `xwave event find -expr "PSLVERR==1" -json` |

## How to Use

Agent 内部 SOP：

1. 确认 FSDB 路径存在；若否，提示我先 `make wave-gen`
2. `xwave open <fsdb> -session <auto-id>` 起 daemon
3. 根据问题分类调用对应子命令（value/apb/axi/event/cursor）
4. 解析 JSON `data` 字段
5. 与 spec / expected 对比，输出诊断

## Example

我："TC8 失败：busy=1 期间写 PKT_MEM 应该 PSLVERR=1 但 log 显示 0"

Agent：
```bash
xwave open lab1/svtb/sim/novas.fsdb
xwave cursor set busy_high -expr "busy_o==1" -nth 1 -json
xwave apb write -addr-range 0x040:0x05C -after busy_high -limit 1 -json
xwave value PSLVERR @<that_write_ts+1clk> -json
```
返回："APB 写 0x044 @ 235ns，下一拍 PSLVERR=0。RTL 缺少 `busy_i & hit_pkt_mem & PWRITE → PSLVERR=1` 这条 case。建议查 ppa_apb_slave_if.sv 中 PSLVERR 组合逻辑。"

## Notes / Gotchas

- 必须先用 `$fsdbDumpvars(0, ppa_tb)` dump 全层级
- daemon 状态在 `~/.xwave/sessions/`；多次查询自动复用
- 大 FSDB（>1GB）首次 open 慢，后续 query 快
- 不要让 Agent 直接读 FSDB 二进制 — 必须经 xwave

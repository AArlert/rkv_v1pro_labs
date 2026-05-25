---
name: log-triage
description: 读 sim/*.log 提取 FAIL/UVM_ERROR/assertion 失败，给出归因
license: MIT
when_to_use: REV 处理 phase=tb / integration / regression 时
inputs:
  - labN/sim/comp.log
  - labN/sim/run.log
  - labN/sim/regress.log（lab4）
outputs:
  - 报告 "Where" 段的证据行 + 归因到具体 RTL/TB 文件
tools:
  - Read, Grep
---

# Skill: Log Triage

## Purpose

`run.log` 动辄数千行；这个 skill 让 REV 一次扫完，输出"今天该修什么"。

## When to Use

- 学生在调 REV 之前已经跑过 `make smoke` / `make regress`
- 仿真 log 已存在于 `labN/sim/*.log`

## SOP

1. 用 grep 把以下模式抓出来：
   ```
   grep -nE "(UVM_ERROR|UVM_FATAL|^Error|Fatal:|\bFAIL\b|Assertion .* failed)" labN/sim/*.log
   ```
2. 对每个匹配，定位上下 ±20 行作上下文
3. 分类：
   - `compile-fail` — 来自 comp.log
   - `assertion` — `Assertion .* failed`
   - `mismatch` — scoreboard expected/actual
   - `timeout` — `objection ... not dropped` / `$finish` 未到
   - `uvm-build-fail` — UVM_FATAL in build_phase
4. 把每条 FAIL 链到具体 RTL/TB 文件:行
5. 同类错误聚合（10 个 TC 都因为同一个 RTL bug 挂 → 报告里写 1 条 bug）

## Output Mapping

- 写入报告 "Where" 段的 "证据" 行：`labN/sim/run.log:<line> — <error string>`
- 写入 "How-to-fix" 段：基于归因给到具体 RTL/TB 文件位置
- 不重复 RTL 评审的事（latch、multi-driver）；只关心"行为不符预期"

## Output Template

```markdown
## Regression Triage

| TC | Status | Class | Hint |
|---|---|---|---|
| smoke_csr_default | PASS | — | — |
| smoke_pkt_write   | FAIL | mismatch | wr_addr expected 2 got 3 @ 235ns → labN/rtl/apb_slave_if.sv:188 地址自增逻辑 |
| pkt_len_overflow  | FAIL | timeout  | done_o 未拉高，看 packet_proc_core.sv FSM PROCESS 是否卡死 |
```

## Notes / Gotchas

- 不替学生写 fix；只指方向
- 同一 RTL bug 引发的多 TC FAIL，**只写一条 bug 报告**，但在 "Where" 段列出全部 TC 名（便于反查）

---
name: manual-coverage-closure
description: 5 类代码覆盖率 + 功能覆盖率 covergroup 的收敛方法笔记
license: MIT
when_to_use: Lab4 cov 阶段
inputs: []
outputs: []
tools: [vcs, urg]
---

# 覆盖率收敛笔记（待 Lab4 补全）

## 5 类代码覆盖率

| 类型 | flag | 含义 |
|---|---|---|
| line / statement | `-cm line` | 每行是否执行过 |
| branch | `-cm branch` | if/case 每个分支是否走过 |
| condition | `-cm cond` | 复合条件每个子项的真假 |
| fsm | `-cm fsm` | 状态转移与每态是否到达 |
| toggle | `-cm tgl` | 每位 0→1 / 1→0 翻转 |

## 收敛步骤

1. 跑全回归 + `-cm` → `*.vdb`
2. `urg -dir *.vdb -dbname merged.vdb`
3. `urg -dir merged.vdb -format both -report urgReport`
4. 打开 `urgReport/dashboard.html` 看百分比
5. 对未覆盖项分类：
   - 可达但 TC 缺 → 加 TC 或 covergroup
   - 不可达（dead code / unreachable case） → 写到 `coverage_exclusion.md`
6. exclude：用 `urg -elfile <excl.el>` 重新生成

## Functional coverage

```systemverilog
covergroup cg_csr_write @(posedge PCLK iff PSEL & PENABLE & PWRITE);
  addr: coverpoint PADDR { bins all[] = {[0:12'hFFF]}; }
  data: coverpoint PWDATA { bins zero = {0}; bins ones = {32'hFFFFFFFF}; bins others = default; }
  cross addr, data;
endgroup
```

## 易错点

- 编译和仿真都必须带 `-cm`，缺一即失数据
- `-cvgperinstance` 才能分实例统计
- 别滥用 exclusion；先尝试加 TC

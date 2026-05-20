---
name: manual-verdi-workflow
description: FSDB dump + Verdi 启动 + 信号分组的个人流程笔记
license: MIT
when_to_use: 每次调 TB 看波形前
inputs: []
outputs: []
tools: [verdi]
---

# Verdi 流程笔记

## TB 内 dump 语句

```systemverilog
initial begin
    $fsdbDumpfile("sim.fsdb");
    $fsdbDumpvars(0, ppa_tb);
end
```

## 启动

```bash
# 跑波形
verdi -ssf sim.fsdb -nologo &
# 恢复窗口
verdi -rc wave.rc &
```

## 我的信号分组习惯

- Group: APB（`PSEL/PENABLE/PADDR/PWRITE/PWDATA/PRDATA/PREADY/PSLVERR`）
- Group: CSR（每个 `CSR` 一行）
- Group: FSM（`state_q` + 关键计数器）
- Group: M3 result（`res_*`、`error_*`）

## 保存窗口

`File → Save Signal Settings` → `lab*/svtb/sim/wave.rc`，下次 `verdi -rc wave.rc`。

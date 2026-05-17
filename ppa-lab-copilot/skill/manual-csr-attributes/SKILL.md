---
name: manual-csr-attributes
description: 我的 RW/RO/W1P/RW1C 四种 CSR 属性 RTL 实现模板
license: MIT
when_to_use: 实现 M1 中任何一个寄存器前
inputs: []
outputs: []
tools: []
---

# CSR 属性实现模板（待填）

## RW

```systemverilog
always_ff @(posedge PCLK or negedge PRESETn)
  if (!PRESETn)            ctrl_q <= RESET_VAL;
  else if (hit_ctrl & wr)  ctrl_q <= PWDATA;
```

## RO

读路径直接接业务信号；写时 → PSLVERR=1，ctrl_q 不变。

## W1P（Write-1-Pulse）

```systemverilog
always_ff @(...)
  if (!PRESETn)            start_q <= 1'b0;
  else                     start_q <= hit_ctrl & wr & PWDATA[1] & ~start_q; // 单拍
```

## RW1C（Write-1-Clear）

```systemverilog
always_ff @(...)
  if (!PRESETn)                          sta_q <= 0;
  else if (hit_sta & wr)                 sta_q <= sta_q & ~PWDATA;  // 写 1 清
  else if (done_rise)                    sta_q[0] <= 1'b1;          // 上升沿置
  else if (err_rise)                     sta_q[1] <= 1'b1;
```

## 易错点

- W1P 忘记 `~start_q` → 双拍
- RW1C 写时若不带 done_rise 优先级，可能"清完立刻被新事件再置"
- done_rise 用 `done_i & ~done_d`，记得 done_d 也要 always_ff

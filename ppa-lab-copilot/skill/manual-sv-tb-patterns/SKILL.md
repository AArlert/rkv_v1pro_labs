---
name: manual-sv-tb-patterns
description: 非 UVM 的 SV TB 常用模式（task/program/clocking block/fork-join）
license: MIT
when_to_use: Lab1/2/3 写 TB 前回顾
inputs: []
outputs: []
tools: []
---

# SV TB 模式（待 Lab1 中填充）

## 顶层骨架

```systemverilog
module ppa_tb;
  logic PCLK = 0; always #5 PCLK = ~PCLK;
  logic PRESETn;
  // ... DUT instantiation ...

  task automatic apb_write(input [11:0] addr, input [31:0] data);
    @(posedge PCLK);
    PSEL <= 1; PWRITE <= 1; PADDR <= addr; PWDATA <= data; PENABLE <= 0;
    @(posedge PCLK);
    PENABLE <= 1;
    @(posedge PCLK);
    PSEL <= 0; PENABLE <= 0;
  endtask
endmodule
```

## Self-check 宏

```systemverilog
int pass_cnt, fail_cnt;
`define CHECK(cond, msg) \
  if (cond) begin pass_cnt++; $display("[CMP_FINAL_PASS] %s", msg); end \
  else      begin fail_cnt++; $display("[CMP_FINAL_FAIL] %s @ t=%0t", msg, $time); end
```

## fork-join 套路

并发驱动 + 监视器：
```systemverilog
fork
  drive_apb();
  monitor_irq();
  timeout_guard(10us);
join_any
disable fork;
```

## 易错点

- `task automatic` 必须 automatic，否则递归/并发会乱
- `@(posedge PCLK)` 后再赋值，不要先赋值后等
- timeout guard 永远要写

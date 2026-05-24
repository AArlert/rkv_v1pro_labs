---
name: manual-apb-protocol
description: 我的 APB 3.0 时序笔记 — SETUP/ACCESS、PREADY、PSLVERR 触发条件
license: MIT
when_to_use: 写 M1 RTL 或调 APB TC 前回顾
inputs: []
outputs: []
tools: []
---

# APB 3.0 笔记（待填）
非流水线协议，所有信号转换仅与时钟上升沿相关
每次传输至少需要 2 个周期

## SETUP→ACCESS 时序（mermaid sequenceDiagram）

(0 周时学完 ARM_AMBA3_APB.pdf §3 后填入)

## 信号采样时机

- PWDATA / PADDR / PWRITE 在 ACCESS（PSEL=1 & PENABLE=1）的上升沿采样
- PRDATA 在同一拍组合输出

## PSLVERR 触发场景（本设计）

1. 写 RO 寄存器
2. 访问未定义地址（OOB）
3. busy=1 期间写 PKT_MEM

## 易错点

- PREADY 固定为 1 时不需要等待态，但仍必须满足 SETUP/ACCESS 两段
- PSLVERR 只在 ACCESS 那一拍有效

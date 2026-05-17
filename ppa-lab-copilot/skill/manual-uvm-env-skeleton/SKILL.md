---
name: manual-uvm-env-skeleton
description: 我的 UVM 树骨架笔记（agent/env/scoreboard/ref_model）
license: MIT
when_to_use: Lab4 UVM 升级前
inputs: []
outputs: []
tools: []
---

# UVM Env 骨架（待 Lab4 前补全）

## 文件清单

- `ppa_apb_if.sv` — interface + 3 modports + clocking block
- `ppa_seq_item.sv` — op_kind enum + 字段 + 约束
- `ppa_sequencer` — 模板
- `ppa_driver` — 根据 op_kind 驱 vif
- `ppa_monitor` — 被动采样 → analysis_port
- `ppa_agent` — 包装 sqr/drv/mon
- `ppa_ref_model` — 预测函数
- `ppa_scoreboard` — 收 monitor 事务 + 调 ref_model 比对
- `ppa_env` — 装 agent + sb + ref + cov
- `ppa_base_test` + 18 derived tests
- `ppa_pkg.sv` — `include 全部
- `ppa_uvm_tb.sv` — top: clk/rst/DUT/vif/config_db

## UVM 树（图）

```
ppa_uvm_tb
└─ ppa_env
   ├─ ppa_apb_agent
   │  ├─ ppa_sequencer
   │  ├─ ppa_driver  ──→ vif (drive)
   │  └─ ppa_monitor ──→ analysis_port
   ├─ ppa_ref_model
   └─ ppa_scoreboard ←─ monitor + ref_model
```

## 易错点

- `uvm_config_db#(virtual ppa_apb_if)::set(...)` 必须在 `build_phase` 之前（top initial）
- driver 中 `seq_item_port.item_done()` 不要漏
- objection 必须配对 raise/drop

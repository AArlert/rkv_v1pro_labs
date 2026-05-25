# lab4 design-note — 全系统回归 + UVM env

## 1 UVM 树结构（学生填）

```
uvm_test_top (ppa_base_test)
└── ppa_env
    ├── apb_agent (active)
    │   ├── apb_sequencer
    │   ├── apb_driver
    │   └── apb_monitor
    ├── ppa_scoreboard
    └── ppa_coverage
```

## 2 关键设计点

- virtual interface 通过 `uvm_config_db#(virtual apb_if)::set/get` 传递
- testcase 通过 `+UVM_TESTNAME=<test>` 选择
- scoreboard 通过 analysis_port 连接 apb_monitor 与 ref_model
- coverage 单独一个 component，与 scoreboard 解耦

## 3 与 spec 的对齐

- 所有 testcase 必须可反查 spec §10 / §11.2–11.4 必做项；选做项可选纳入
- 覆盖率 covergroup 的 bin 划分对齐 spec 的字段范围

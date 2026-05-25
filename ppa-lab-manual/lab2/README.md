# lab2 — M3 packet_proc_core

> Spec：[`../doc/ppa-lite-spec.md`](../doc/ppa-lite-spec.md) §11.3
> 工作流：[`../doc/workflow.md`](../doc/workflow.md)

## 涉及模块

| 模块 | 文件位置 | spec 参考 |
|---|---|---|
| M3 `packet_proc_core` | [`rtl/packet_proc_core.sv`](rtl/packet_proc_core.sv) | §2.3 表 + §6 FSM |

## 必做验收（spec §11.3）

1. 合法包完整处理（IDLE→PROCESS→DONE）
2. 长度越界检测（下溢 / 上溢，M3 不卡死）
3. busy/done 时序

## 目录速览

```
lab2/
├── doc/{design-note.md, testplan.md, progress.md}
├── rtl/packet_proc_core.sv      M3（FSM + 算法核；手写 FSM + Copilot 补 case）
├── verif/
│   ├── tb/tb_top.sv             独立 TB（不依赖 lab1 RTL；用 SV 数组替代 M2）
│   ├── ref_model/               packet parser ref model（独立实现！）
│   ├── sequences/               legal/illegal packet stimulus
│   ├── tests/                   smoke_legal / length_overflow / busy_done_timing
│   └── common/                  ppa_packet_pkg.sv（包结构 typedef）
└── sim/{Makefile, filelist.f}
```

## 阶段流转

| 阶段 | REV 报告 |
|---|---|
| D | `design-rtl-packet_proc_core` |
| V | `tb-tb` |

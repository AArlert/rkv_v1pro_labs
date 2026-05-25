# lab3 — ppa_top 集成

> Spec：[`../doc/ppa-lite-spec.md`](../doc/ppa-lite-spec.md) §11.4
> 工作流：[`../doc/workflow.md`](../doc/workflow.md)

## 涉及模块

| 模块 | 文件位置 | spec 参考 |
|---|---|---|
| `ppa_top` | [`rtl/ppa_top.sv`](rtl/ppa_top.sv) | §2.1 框图 + §2.3 顶层端口 |
| M1/M2/M3 | 引用 lab1/lab2 的 RTL（见 sim/filelist.f） | — |

> 角色轮换：上一轮设计的同学本轮做验证（spec §11.4）

## 必做验收（spec §11.4）

1. 端到端链路完整（write packet → start → poll done → read RES_*）
2. 连续两帧顺序处理
3. STATUS 总线通路

## 目录速览

```
lab3/
├── doc/{design-note.md, testplan.md, progress.md}
├── rtl/ppa_top.sv           顶层薄连线（无状态逻辑）
├── verif/
│   ├── tb/tb_top.sv         集成 TB（复用 lab1 APB task）
│   ├── sequences/           端到端 sequence（write_pkt + cfg + start + poll_done + read_res）
│   ├── tests/               smoke / two_frames / status_path
│   └── ref_model/           lab2 ref model 升级为端到端
└── sim/{Makefile, filelist.f}  filelist 跨 lab 引用 lab1/lab2 的 RTL
```

## 阶段流转

| 阶段 | REV 报告 |
|---|---|
| D | `design-rtl-ppa_top` |
| V | `tb-tb` |
| I | `integration-full` |

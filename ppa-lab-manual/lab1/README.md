# lab1 — M1 apb_slave_if + M2 packet_sram

> Spec：[`../doc/ppa-lite-spec.md`](../doc/ppa-lite-spec.md) §11.2
> 工作流：[`../doc/workflow.md`](../doc/workflow.md)

## 涉及模块

| 模块 | 文件位置 | spec 参考 |
|---|---|---|
| M1 `apb_slave_if` | [`rtl/apb_slave_if.sv`](rtl/apb_slave_if.sv) | §2.3 表 + §5 CSR 表 |
| M2 `packet_sram` | [`rtl/packet_sram.sv`](rtl/packet_sram.sv) | §2.3 表 + §4 SRAM 行为 |

## 必做验收（spec §11.2）

1. APB 基础读写时序（CTRL/CFG/STATUS 默认值正确）
2. PKT_MEM 写入地址映射（0x040–0x05C 8 个 word）
3. RES_\* 寄存器读通路（stub 赋值后 APB 读回比对）

## 目录速览

```
lab1/
├── doc/
│   ├── design-note.md    手写设计意图（含心智模型 + 与 spec 的偏离/澄清记录）
│   ├── testplan.md       testcase × check-point 表
│   └── progress.md       D/V 阶段勾选 + REV 报告关联
├── rtl/
│   ├── apb_slave_if.sv   M1（人手写端口 + 关键 always；Copilot 补 case 分支）
│   └── packet_sram.sv    M2（人手写双口 SRAM 行为）
├── verif/
│   ├── tb/tb_top.sv      顶层 TB（时钟/复位/DUT 例化）
│   ├── agents/apb_agent/ APB agent v0.1（lab1 起逐步成型，lab4 完整）
│   ├── sequences/        smoke 用 sequence（lab1 可只放 1 个）
│   ├── tests/            csr_default_test / pkt_mem_write_test / res_read_test
│   ├── ref_model/        寄存器 shadow（SV class 或简单数组）
│   └── common/           ppa_reg_pkg.sv（CSR 偏移/字段宏定义）
└── sim/
    ├── Makefile          smoke / wave / clean targets
    └── filelist.f        RTL + TB 源文件列表
```

## 阶段流转

| 阶段 | 完成条件 | REV 报告 |
|---|---|---|
| D（Design） | M1+M2 RTL 编译过；apb_slave_if 端口与 spec 对齐 | `design-rtl-apb_slave_if` + `design-rtl-packet_sram` |
| V（Verify） | 3 个必做 testcase `make smoke` 全 PASS | `tb-tb` |

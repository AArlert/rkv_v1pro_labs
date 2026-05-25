# lab1 design-note — M1 apb_slave_if + M2 packet_sram

> 学生手写。设计意图、与 spec 不同的地方、设计决策都写在这里。
> REV 把本文件视为"学生意图"参考；当 RTL 与本文件不符 → REV 会指出。

## 1 设计目标

- 实现 spec §2.3 表 / §5 寄存器表中 M1 的全部端口与 CSR
- 实现 spec §2.3 表中 M2 的 8×32-bit 双端口同步 SRAM
- 不引入 spec 之外的状态或字段

## 2 心智模型

### M1 apb_slave_if
- APB 两段式：SETUP 拍 PSEL=1 PENABLE=0；ACCESS 拍 PSEL=1 PENABLE=1
- PREADY 固定为 1（无等待态）
- CSR 分组：CTRL / CFG / STATUS / RES_* / IRQ_EN / IRQ_STA / PKT_LEN_EXP / PKT_MEM 窗口
- W1P：start_o 由 `CTRL.start` 字段写 1 时产生单拍脉冲

### M2 packet_sram
- 8×32-bit 双口同步 SRAM
- 写端口给 M1；读端口给 M3；不做包语义判断

## 3 与 spec 的偏离 / 澄清（如有）

| 项 | spec 章节 | 本设计选择 | 原因 |
|---|---|---|---|
| — | — | — | — |

> 如果发现 spec 有歧义，**不要自行解读** —— 在本表登记并求助 ARCH（人），spec 不可改。

## 4 端口表确认（M1）

> 学生手写时填表，确认与 spec §2.3 M1 表逐字一致后打勾。

- [ ] PCLK / PRESETn
- [ ] PSEL / PENABLE / PWRITE / PADDR[11:0] / PWDATA[31:0]
- [ ] PRDATA[31:0] / PREADY / PSLVERR
- [ ] enable_o / start_o / algo_mode_o / type_mask_o[3:0] / exp_pkt_len_o[5:0]
- [ ] done_irq_en_o / err_irq_en_o
- [ ] pkt_mem_we_o / pkt_mem_addr_o[2:0] / pkt_mem_wdata_o[31:0]
- [ ] busy_i / done_i / format_ok_i / length_error_i / type_error_i / chk_error_i
- [ ] res_pkt_len_i[5:0] / res_pkt_type_i[7:0] / res_payload_sum_i[7:0] / res_payload_xor_i[7:0]
- [ ] irq_o

## 5 端口表确认（M2）

- [ ] clk / rst_n
- [ ] wr_en / wr_addr[2:0] / wr_data[31:0]
- [ ] rd_en / rd_addr[2:0] / rd_data[31:0]

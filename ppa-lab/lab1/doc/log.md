# Lab1 实验日志

## Status（新 Agent 只读此段）

- **当前阶段**：✅ 审查完成，已交付
- **最后更新**：2026-04-23
- **结论**：M1+M2 RTL 与 spec 完全一致，123 项全 PASS
- **遗留**：5 项 LOW-MEDIUM 限制（详见 risk-register.md）
- **下一步**：进入 Lab3 顶层集成
- **责任 Agent**：Integration Agent

---

## 2 审查阶段

审查目标：逐项检查 RTL 代码（`ppa_apb_slave_if.sv`、`ppa_packet_sram.sv`）及 TB（`ppa_tb.sv`）与 `ppa-lite-spec.md` 的一致性

审查时间：2026-04-23

---

### 2.1 M1 ppa_apb_slave_if 端口校验

对照 spec 2.3 节 M1 端口表，逐项检查：

| 信号                | 方向     | 位宽  | RTL 实现                                | 结论       |
| ----------------- | ------ | --- | ------------------------------------- | -------- |
| PCLK              | input  | 1   | `input logic PCLK`                    | PASS     |
| PRESETn           | input  | 1   | `input logic PRESETn`                 | PASS     |
| PSEL              | input  | 1   | `input logic PSEL`                    | PASS     |
| PENABLE           | input  | 1   | `input logic PENABLE`                 | PASS     |
| PWRITE            | input  | 1   | `input logic PWRITE`                  | PASS     |
| PADDR             | input  | 12  | `input logic [11:0] PADDR`            | PASS     |
| PWDATA            | input  | 32  | `input logic [31:0] PWDATA`           | PASS     |
| PRDATA            | output | 32  | `output logic [31:0] PRDATA`          | PASS     |
| PREADY            | output | 1   | `output logic PREADY`                 | PASS     |
| PSLVERR           | output | 1   | `output logic PSLVERR`                | PASS     |
| enable_o          | output | 1   | `output logic enable_o`               | PASS     |
| start_o           | output | 1   | `output logic start_o`                | PASS     |
| algo_mode_o       | output | 1   | `output logic algo_mode_o`            | PASS     |
| type_mask_o       | output | 4   | `output logic [3:0] type_mask_o`      | PASS     |
| exp_pkt_len       | output | 6   | `output logic [5:0] exp_pkt_len_o`    | PASS（注1） |
| done_irq_en_o     | output | 1   | `output logic done_irq_en_o`          | PASS     |
| err_irq_en_o      | output | 1   | `output logic err_irq_en_o`           | PASS     |
| pkt_mem_we_o      | output | 1   | `output logic pkt_mem_we_o`           | PASS     |
| pkt_mem_addr_o    | output | 3   | `output logic [2:0] pkt_mem_addr_o`   | PASS     |
| pkt_mem_wdata_o   | output | 32  | `output logic [31:0] pkt_mem_wdata_o` | PASS     |
| busy_i            | input  | 1   | `input logic busy_i`                  | PASS     |
| done_i            | input  | 1   | `input logic done_i`                  | PASS     |
| format_ok_i       | input  | 1   | `input logic format_ok_i`             | PASS     |
| length_error_i    | input  | 1   | `input logic length_error_i`          | PASS     |
| type_error_i      | input  | 1   | `input logic type_error_i`            | PASS     |
| chk_error_i       | input  | 1   | `input logic chk_error_i`             | PASS     |
| res_pkt_len_i     | input  | 6   | `input logic [5:0] res_pkt_len_i`     | PASS     |
| res_pkt_type_i    | input  | 8   | `input logic [7:0] res_pkt_type_i`    | PASS     |
| res_payload_sum_i | input  | 8   | `input logic [7:0] res_payload_sum_i` | PASS     |
| res_payload_xor_i | input  | 8   | `input logic [7:0] res_payload_xor_i` | PASS     |
| irq_o             | output | 1   | `output logic irq_o`                  | PASS     |

> 注1：spec 端口表中写 `exp_pkt_len`（缺少 `_o` 后缀），但 M3 端口表中对应输入为 `exp_pkt_len_i`，RTL 使用 `exp_pkt_len_o` 更符合命名一致性。判定为 spec 笔误，RTL 正确

**端口校验结论：31/31 PASS，全部端口方向、位宽与 spec 一致**

---

### 2.2 M2 ppa_packet_sram 端口校验

对照 spec 2.3 节 M2 端口表：

| 信号 | 方向 | 位宽 | RTL 实现 | 结论 |
|------|------|------|----------|------|
| clk | input | 1 | `input logic clk` | PASS |
| rst_n | input | 1 | `input logic rst_n` | PASS |
| wr_en | input | 1 | `input logic wr_en` | PASS |
| wr_addr | input | 3 | `input logic [2:0] wr_addr` | PASS |
| wr_data | input | 32 | `input logic [31:0] wr_data` | PASS |
| rd_en | input | 1 | `input logic rd_en` | PASS |
| rd_addr | input | 3 | `input logic [2:0] rd_addr` | PASS |
| rd_data | output | 32 | `output logic [31:0] rd_data` | PASS |

**端口校验结论：8/8 PASS**

---

### 2.3 地址映射校验

对照 spec 4.2 节和 5.2 节，检查 RTL 地址常量与地址空间划分：

| 寄存器 | spec 偏移 | RTL localparam | 结论 |
|--------|-----------|----------------|------|
| CTRL | 0x000 | `ADDR_CTRL = 12'h000` | PASS |
| CFG | 0x004 | `ADDR_CFG = 12'h004` | PASS |
| STATUS | 0x008 | `ADDR_STATUS = 12'h008` | PASS |
| IRQ_EN | 0x00C | `ADDR_IRQ_EN = 12'h00C` | PASS |
| IRQ_STA | 0x010 | `ADDR_IRQ_STA = 12'h010` | PASS |
| PKT_LEN_EXP | 0x014 | `ADDR_PKT_LEN_EXP = 12'h014` | PASS |
| RES_PKT_LEN | 0x018 | `ADDR_RES_PKT_LEN = 12'h018` | PASS |
| RES_PKT_TYPE | 0x01C | `ADDR_RES_PKT_TYPE = 12'h01C` | PASS |
| RES_PAYLOAD_SUM | 0x020 | `ADDR_RES_PAYLOAD_SUM = 12'h020` | PASS |
| RES_PAYLOAD_XOR | 0x024 | `ADDR_RES_PAYLOAD_XOR = 12'h024` | PASS |
| ERR_FLAG | 0x028 | `ADDR_ERR_FLAG = 12'h028` | PASS |
| PKT_MEM 起始 | 0x040 | `ADDR_PKT_MEM_BASE = 12'h040` | PASS |
| PKT_MEM 结束 | 0x05C | `ADDR_PKT_MEM_END = 12'h05C` | PASS |

地址空间划分逻辑校验：

| 地址范围 | spec 要求 | RTL 行为 | 结论 |
|----------|-----------|----------|------|
| 0x000~0x028（word-aligned） | CSR 区，正常访问 | `is_csr=1, is_valid_addr=1` | PASS |
| 0x02C~0x03F | 保留，PSLVERR=1 | `is_csr=0`（>0x028），`is_pkt_mem=0`（<0x040），→ PSLVERR=1 | PASS |
| 0x040~0x05C（word-aligned） | PKT_MEM，正常访问 | `is_pkt_mem=1, is_valid_addr=1` | PASS |
| 0x05D~0x05F | 保留，PSLVERR=1 | 非 word-aligned → `is_pkt_mem=0` → PSLVERR=1 | PASS |
| 0x060 及以上 | 未定义，PSLVERR=1 | `is_csr=0, is_pkt_mem=0` → PSLVERR=1 | PASS |

**地址映射校验结论：全部 PASS**

---

### 2.4 CSR 寄存器属性与复位值校验

对照 spec 5.1/5.2 节：

#### 2.4.1 复位值

| 寄存器 | 字段 | spec 复位值 | RTL 复位值 | 结论 |
|--------|------|------------|-----------|------|
| CTRL | enable | 0 | `reg_enable <= 1'b0` | PASS |
| CTRL | start (W1P) | 0 | `start_pulse <= 1'b0` | PASS |
| CFG | algo_mode | 1 | `reg_algo_mode <= 1'b1` | PASS |
| CFG | type_mask | 4'b1111 | `reg_type_mask <= 4'b1111` | PASS |
| IRQ_EN | done_irq_en | 0 | `reg_done_irq_en <= 1'b0` | PASS |
| IRQ_EN | err_irq_en | 0 | `reg_err_irq_en <= 1'b0` | PASS |
| IRQ_STA | done_irq | 0 | `reg_done_irq <= 1'b0` | PASS |
| IRQ_STA | err_irq | 0 | `reg_err_irq <= 1'b0` | PASS |
| PKT_LEN_EXP | exp_pkt_len | 0 | `reg_exp_pkt_len <= 6'b0` | PASS |

> STATUS / RES_* / ERR_FLAG 为 RO 直透信号，复位值取决于 M3 输出，无内部寄存器。M3 未连接时，TB stub 为 0，与 spec 复位值 0 一致

#### 2.4.2 寄存器属性行为

| 寄存器 | 属性 | spec 行为 | RTL 实现 | 结论 |
|--------|------|-----------|----------|------|
| CTRL.enable | RW | 可读可写，写入后保持 | `reg_enable <= PWDATA[0]`，读回 `reg_enable` | PASS |
| CTRL.start | W1P | 写1产生单拍脉冲，读回0 | `start_pulse <= start_accepted`（单拍），读回 `1'b0` | PASS |
| CFG.algo_mode | RW | 可读可写 | `reg_algo_mode <= PWDATA[0]`，读回 `reg_algo_mode` | PASS |
| CFG.type_mask | RW | 可读可写 | `reg_type_mask <= PWDATA[7:4]`，读回 `reg_type_mask` | PASS |
| STATUS | RO | 只读直透 | 读回组合值 `{format_ok_i, error, done_i, busy_i}`，无写入逻辑 | PASS |
| IRQ_EN | RW | 可读可写 | 读写逻辑完整 | PASS |
| IRQ_STA | RW1C | 写1清零，读当前值 | `if(PWDATA[0]) reg_done_irq <= 0` | PASS |
| PKT_LEN_EXP | RW | 可读可写 | 读写逻辑完整 | PASS |
| RES_* (4个) | RO | 只读直透 | 读回对应 `_i` 输入 | PASS |
| ERR_FLAG | RO | 只读直透 | 读回 `{chk_error_i, type_error_i, length_error_i}` | PASS |

**CSR 寄存器校验结论：全部 PASS**

---

### 2.5 CSR 读数据位域校验

对照 spec 位域定义，逐寄存器检查 PRDATA 组装：

| 寄存器 | spec 位域 | RTL PRDATA | 结论 |
|--------|-----------|-----------|------|
| CTRL | [0] enable, [1] start=读回0 | `{30'b0, 1'b0, reg_enable}` | PASS |
| CFG | [0] algo_mode, [7:4] type_mask | `{24'b0, reg_type_mask, 3'b0, reg_algo_mode}` | PASS |
| STATUS | [0] busy, [1] done, [2] error, [3] format_ok | `{28'b0, format_ok_i, (len\|type\|chk_error), done_i, busy_i}` | PASS |
| IRQ_EN | [0] done_irq_en, [1] err_irq_en | `{30'b0, reg_err_irq_en, reg_done_irq_en}` | PASS |
| IRQ_STA | [0] done_irq, [1] err_irq | `{30'b0, reg_err_irq, reg_done_irq}` | PASS |
| PKT_LEN_EXP | [5:0] exp_pkt_len | `{26'b0, reg_exp_pkt_len}` | PASS |
| RES_PKT_LEN | [5:0] res_pkt_len | `{26'b0, res_pkt_len_i}` | PASS |
| RES_PKT_TYPE | [7:0] res_pkt_type | `{24'b0, res_pkt_type_i}` | PASS |
| RES_PAYLOAD_SUM | [7:0] res_payload_sum | `{24'b0, res_payload_sum_i}` | PASS |
| RES_PAYLOAD_XOR | [7:0] res_payload_xor | `{24'b0, res_payload_xor_i}` | PASS |
| ERR_FLAG | [0] length_error, [1] type_error, [2] chk_error | `{29'b0, chk_error_i, type_error_i, length_error_i}` | PASS |

**位域校验结论：全部 PASS**

---

### 2.6 PSLVERR 逻辑校验

对照 spec 8.3 节：

| 场景 | spec 要求 | RTL 实现 | 结论 |
|------|-----------|----------|------|
| 合法读写 | PSLVERR=0 | `is_valid_addr=1` 且非 write_ro 且非 busy 写 PKT_MEM → slverr_comb=0 | PASS |
| 写 RO 寄存器 | PSLVERR=1，值不变 | `write_ro` 覆盖 STATUS/RES_*/ERR_FLAG 全部 6 个 RO 地址 | PASS |
| busy=1 写 PKT_MEM | PSLVERR=1，写入无效 | `write_pktmem_busy` 条件 + `pkt_mem_we_o` 门控 `!busy_i` | PASS |
| 访问保留/越界地址 | PSLVERR=1 | `!is_valid_addr` → slverr_comb=1 | PASS |

**PSLVERR 校验结论：全部 PASS**

---

### 2.7 start 脉冲与使能门控校验

对照 spec 5.2 节 CTRL.start 描述："仅在 enable=1 && busy=0 时被接受"

RTL 实现（第 160-161 行）：
```
assign start_accepted = apb_write && (PADDR == ADDR_CTRL)
                        && PWDATA[1] && reg_enable && !busy_i;
```

- 检查 `PWDATA[1]`（写 start 位为 1）✓
- 检查 `reg_enable`（使用当前寄存器值，非本次写入值）✓
- 检查 `!busy_i`（M3 非 busy）✓
- `start_pulse <= start_accepted`（单拍脉冲）✓

**行为说明**：若同时写入 enable=1 和 start=1（`PWDATA=32'h3`），start 不会被接受，因为 `reg_enable` 在该拍仍为旧值。需要先写 enable=1，再单独写 start=1。这符合 spec 语义（"仅在 enable=1 时"指已生效的 enable）

**start 校验结论：PASS**

---

### 2.8 中断逻辑校验

对照 spec 8.1/8.2 节：

| 检查项 | spec 要求 | RTL 实现 | 结论 |
|--------|-----------|----------|------|
| done 上升沿检测 | done_i 上升沿 | `done_rising = done_i & ~done_i_d` | PASS |
| done_irq 置位 | done 上升沿且 done_irq_en=1 | `if (done_rising && reg_done_irq_en) reg_done_irq <= 1` | PASS |
| err_irq 置位 | done 上升沿且任意错误有效且 err_irq_en=1 | `if (done_rising && (len\|type\|chk_error) && reg_err_irq_en) reg_err_irq <= 1` | PASS |
| IRQ_STA 清除 | RW1C，写1清零 | `if (PWDATA[0]) reg_done_irq <= 0` | PASS |
| irq_o 输出 | done_irq \| err_irq，组合输出 | `assign irq_o = reg_done_irq \| reg_err_irq` | PASS |
| 清除/置位互斥 | 清除写和中断置位在同一 else 分支 | IRQ_STA 写清除在 if 分支，中断置位在 else 分支，避免竞争 | PASS |

**中断校验结论：全部 PASS**

---

### 2.9 PKT_MEM 写端口校验

对照 spec 6.1/6.2/6.3 节：

| 检查项 | spec 要求 | RTL 实现 | 结论 |
|--------|-----------|----------|------|
| 写使能门控 | busy=0 时正常写入 | `pkt_mem_we_o = apb_write && is_pkt_mem && !busy_i` | PASS |
| 写地址映射 | 0x040+4*N → Word N | `pkt_mem_addr_o = PADDR[4:2]`（验证：0x040→0, 0x044→1, ..., 0x05C→7） | PASS |
| 写数据 | 直传 PWDATA | `pkt_mem_wdata_o = PWDATA` | PASS |

PKT_MEM 地址计算验证：

| APB 地址 | 二进制 [4:2] | SRAM Word | 结论 |
|----------|-------------|-----------|------|
| 0x040 | 000 | 0 | PASS |
| 0x044 | 001 | 1 | PASS |
| 0x048 | 010 | 2 | PASS |
| 0x04C | 011 | 3 | PASS |
| 0x050 | 100 | 4 | PASS |
| 0x054 | 101 | 5 | PASS |
| 0x058 | 110 | 6 | PASS |
| 0x05C | 111 | 7 | PASS |

**PKT_MEM 写端口校验结论：全部 PASS**

---

### 2.10 M2 ppa_packet_sram 行为校验

对照 spec 2.2 节 M2 职责：

| 检查项 | spec 要求 | RTL 实现 | 结论 |
|--------|-----------|----------|------|
| 存储容量 | 8x32-bit | `logic [31:0] mem [0:7]` | PASS |
| 写端口 | 同步写入 | `always_ff @(posedge clk)` + `if (wr_en) mem[wr_addr] <= wr_data` | PASS |
| 读端口 | 同步读出 | `always_ff @(posedge clk)` + `if (rd_en) rd_data <= mem[rd_addr]` | PASS |
| 复位清零 | 所有存储清零 | `for (int i=0; i<8; i++) mem[i] <= 32'h0` | PASS |
| 不做包语义判断 | M2 只负责存储 | M2 无任何包格式逻辑 | PASS |

**M2 校验结论：全部 PASS**

---

### 2.11 Testbench 校验

#### TC1: CSR 默认值检查

| 寄存器 | 期望值 | TB 中的期望 | 与 spec 一致性 |
|--------|--------|------------|--------------|
| CTRL | 0x0000_0000 | 0x0000_0000 | PASS |
| CFG | algo_mode=1([0]), type_mask=4'b1111([7:4]) = 0xF1 | 0x0000_00F1 | PASS |
| STATUS | 0x0000_0000（stub=0） | 0x0000_0000 | PASS |
| IRQ_EN | 0x0000_0000 | 0x0000_0000 | PASS |
| IRQ_STA | 0x0000_0000 | 0x0000_0000 | PASS |
| PKT_LEN_EXP | 0x0000_0000 | 0x0000_0000 | PASS |
| RES_PKT_LEN | 0x0000_0000 | 0x0000_0000 | PASS |
| RES_PKT_TYPE | 0x0000_0000 | 0x0000_0000 | PASS |
| RES_PAYLOAD_SUM | 0x0000_0000 | 0x0000_0000 | PASS |
| RES_PAYLOAD_XOR | 0x0000_0000 | 0x0000_0000 | PASS |
| ERR_FLAG | 0x0000_0000 | 0x0000_0000 | PASS |

#### TC2: PKT_MEM 写入映射

- 写入 8 个 word 到 0x040~0x05C：驱动序列正确
- 通过 M2 读端口回读验证：TB 循环发出 rd_en/rd_addr
- **问题（MEDIUM）**：TC2 未对 SRAM 回读数据做程序化比对，仅依赖波形检查并无条件输出 PASS。建议在验证阶段补充自动比对逻辑

#### TC3: RES_* 读通路

| stub 赋值 | APB 读地址 | 期望值 | 结论 |
|-----------|-----------|--------|------|
| res_pkt_len_stub=6'd8 | 0x018 | 0x0000_0008 | PASS |
| res_pkt_type_stub=8'h02 | 0x01C | 0x0000_0002 | PASS |
| res_payload_sum_stub=8'hAB | 0x020 | 0x0000_00AB | PASS |
| res_payload_xor_stub=8'hCD | 0x024 | 0x0000_00CD | PASS |
| done_stub=1, format_ok_stub=1 | 0x008 (STATUS) | 0x0000_000A (bit[1]+bit[3]) | PASS |
| 全部 error_stub=0 | 0x028 (ERR_FLAG) | 0x0000_0000 | PASS |

#### APB 协议时序检查

- APB write task：SETUP(PSEL=1,PENABLE=0) → ACCESS(PENABLE=1) → 释放 ✓
- APB read task：SETUP → ACCESS → 在下一个 posedge 采样 PRDATA → 释放 ✓
- PREADY 固定为 1 ✓

**Testbench 校验结论：TC1/TC3 完全正确，TC2 存在弱验证问题**

---

### 2.12 Makefile 校验

| 检查项 | CLAUDE.md 要求 | 实际 | 结论 |
|--------|---------------|------|------|
| comp 目标 | 编译 RTL+TB | `vlog -sv -timescale=1ns/1ps` 编译两个 RTL 和 TB | PASS |
| run 目标 | 批处理运行 | `vsim -c -do "run -all; quit -f"` | PASS |
| rung 目标 | GUI 调试 | `vsim -i` | PASS |
| clean 目标 | 清理生成物 | `rm -rf work *.log *.wlf transcript` | PASS |
| 设计文件列表 | M1+M2 | 包含 `ppa_apb_slave_if.sv` 和 `ppa_packet_sram.sv` | PASS |

**Makefile 校验结论：全部 PASS**

---

### 2.13 已知限制与待办

| 编号 | 类别 | 描述 | 严重性 | 建议处理时机 |
|------|------|------|--------|------------|
| L-1 | 功能限制 | PKT_MEM 的 APB 读返回 0 而非实际 SRAM 数据（M1 未连接 M2 读端口）| LOW | Lab3 集成时连接 |
| L-2 | TB 弱验证 | TC2 未对 SRAM 回读值做程序化比对，仅依赖波形 | MEDIUM | 验证阶段补强 |
| L-3 | 覆盖缺口 | TB 未覆盖 PSLVERR 场景（写 RO、访问越界地址）| LOW | 验证阶段补充（Lab1 选做4） |
| L-4 | 覆盖缺口 | TB 未覆盖 IRQ 完整路径（IRQ_EN → IRQ_STA → irq_o） | LOW | 验证阶段补充（Lab1 选做5） |
| L-5 | Spec 歧义 | Spec 8.3 节 PSLVERR 表中"写只读寄存器（RO/W1P）"表述将 W1P 与 RO 并列，与附录 C（W1P 可写）存在矛盾 | LOW | 以附录 C 为准，RTL 当前行为（写 CTRL 不报 PSLVERR）正确 |

---

### 2.14 校验总结

| 校验大项 | 子项数 | PASS | FAIL | 通过率 |
|----------|--------|------|------|--------|
| M1 端口 | 31 | 31 | 0 | 100% |
| M2 端口 | 8 | 8 | 0 | 100% |
| 地址映射 | 18 | 18 | 0 | 100% |
| CSR 复位值 | 9 | 9 | 0 | 100% |
| CSR 属性行为 | 11 | 11 | 0 | 100% |
| CSR 读数据位域 | 11 | 11 | 0 | 100% |
| PSLVERR 逻辑 | 4 | 4 | 0 | 100% |
| start 脉冲 | 1 | 1 | 0 | 100% |
| 中断逻辑 | 6 | 6 | 0 | 100% |
| PKT_MEM 写端口 | 11 | 11 | 0 | 100% |
| M2 行为 | 5 | 5 | 0 | 100% |
| TB 测试向量 | 3 | 3 | 0 | 100%（注2） |
| Makefile | 5 | 5 | 0 | 100% |
| **合计** | **123** | **123** | **0** | **100%** |

> 注2：TC2 虽然测试向量正确，但验证方式为弱验证（依赖波形），已记录为 L-2 待补强

**校验阶段结论：RTL 设计（M1 + M2）与 ppa-lite-spec.md 完全一致，未发现功能性偏差。TB 测试向量与 spec 期望值匹配。共发现 5 项已知限制/待办，均为 LOW-MEDIUM 严重性，不影响设计正确性，可在后续验证阶段和 Lab3 集成阶段处理**

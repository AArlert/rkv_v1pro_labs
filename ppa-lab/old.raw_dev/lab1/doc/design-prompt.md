# Lab1 设计文档：APB 从接口 + SRAM

## 1 本阶段目标
- 实现 APB 3.0 从接口模块 `ppa_apb_slave_if`（M1）
- 实现 8x32-bit 双端口同步 SRAM 模块 `ppa_packet_sram`（M2）
- 搭建 SV TB 骨架，完成基础读写验证

## 2 模块设计要点

### 2.1 ppa_apb_slave_if（M1）
- APB 3.0 两段式传输：SETUP（PSEL=1, PENABLE=0）→ ACCESS（PSEL=1, PENABLE=1）
- PREADY 固定为 1，无等待状态
- 地址空间划分：
  - `0x000~0x02B`：CSR 区
  - `0x02C~0x03F`：保留（PSLVERR=1）
  - `0x040~0x05C`：PKT_MEM 窗口（8 word）
  - `0x060` 及以上：未定义（PSLVERR=1）
- CSR 寄存器属性：RW / RO / W1P / RW1C 四类
- PKT_MEM 写入时生成 wr_en/wr_addr/wr_data 送 M2
- busy=1 期间写 PKT_MEM 返回 PSLVERR=1，写入无效

### 2.2 ppa_packet_sram（M2）
- 8x32-bit 双端口同步 SRAM
- 写端口：来自 M1（APB 写入）
- 读端口：来自 M3（处理阶段，Lab1 暂不连接）
- 复位时清零所有存储

### 2.3 CSR 寄存器表（Lab1 范围）

| 偏移  | 寄存器          | 位域               | 属性 | 复位值     |
|-------|-----------------|---------------------|------|-----------|
| 0x000 | CTRL            | [0] enable          | RW   | 0         |
|       |                 | [1] start           | W1P  | 0         |
| 0x004 | CFG             | [0] algo_mode       | RW   | 1         |
|       |                 | [7:4] type_mask     | RW   | 4'b1111   |
| 0x008 | STATUS          | [3:0] busy/done/error/format_ok | RO | 0 |
| 0x00C | IRQ_EN          | [1:0] done_irq_en/err_irq_en   | RW | 0 |
| 0x010 | IRQ_STA         | [1:0] done_irq/err_irq         | RW1C | 0 |
| 0x014 | PKT_LEN_EXP    | [5:0] exp_pkt_len               | RW | 0 |
| 0x018 | RES_PKT_LEN    | [5:0] res_pkt_len               | RO | 0 |
| 0x01C | RES_PKT_TYPE   | [7:0] res_pkt_type              | RO | 0 |
| 0x020 | RES_PAYLOAD_SUM| [7:0] res_payload_sum            | RO | 0 |
| 0x024 | RES_PAYLOAD_XOR| [7:0] res_payload_xor            | RO | 0 |
| 0x028 | ERR_FLAG       | [2:0] length/type/chk_error      | RO | 0 |

### 2.4 PKT_MEM 地址映射
- APB 地址 `0x040 + 4*N` → SRAM Word N（N=0~7）
- wr_addr = (PADDR - 0x040) >> 2

## 3 验收标准

### 必做
1. APB 基础读写时序正确（CSR 默认值正确）
2. PKT_MEM 写入地址映射正确（wr_en/wr_addr/wr_data 波形匹配）
3. RES_* 寄存器读通路正确（stub 赋值后 APB 读回一致）

### 选做
4. PSLVERR 统一错误响应（写 RO 返回 PSLVERR=1，访问未定义地址返回 PSLVERR=1）
5. IRQ 寄存器完整实现（IRQ_EN/IRQ_STA/irq_o）

## 4 文件清单

| 文件路径 | 说明 |
|----------|------|
| rtl/ppa_apb_slave_if.sv | APB 从接口 + CSR |
| rtl/ppa_packet_sram.sv  | 双端口同步 SRAM |
| svtb/tb/ppa_tb.sv       | TB 骨架 |
| svtb/sim/Makefile        | 仿真入口 |

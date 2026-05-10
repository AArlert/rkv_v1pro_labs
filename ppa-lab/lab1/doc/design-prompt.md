# Lab1 设计文档：APB 从接口 + SRAM

## 1 本阶段目标
- 实现 APB 3.0 从接口模块 `ppa_apb_slave_if`（M1）
- 实现 8x32-bit 双端口同步 SRAM 模块 `ppa_packet_sram`（M2）
- 搭建 SV TB 骨架，完成基础读写验证

## 2 模块设计要点

### 2.1 ppa_apb_slave_if（M1）
- APB 3.0 两段式传输：SETUP（PSEL=1, PENABLE=0）-> ACCESS（PSEL=1, PENABLE=1）
- PREADY 固定为 1，无等待状态
- 地址空间划分：
  - `0x000~0x028`：CSR 区（word-aligned，共 11 个寄存器）
  - `0x02C~0x03F`：保留（PSLVERR=1）
  - `0x040~0x05C`：PKT_MEM 窗口（8 word）
  - `0x060` 及以上：未定义（PSLVERR=1）
- CSR 寄存器属性：RW / RO / W1P / RW1C 四类
- PKT_MEM 写入时生成 wr_en/wr_addr/wr_data 送 M2
- busy=1 期间写 PKT_MEM 返回 PSLVERR=1，写入无效
- STATUS / RES_* / ERR_FLAG 为 RO 直透（从 M3 输入端口取值，不额外锁存）

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
| 0x008 | STATUS          | [0] busy            | RO   | 0         |
|       |                 | [1] done            | RO   | 0         |
|       |                 | [2] error           | RO   | 0         |
|       |                 | [3] format_ok       | RO   | 0         |
| 0x00C | IRQ_EN          | [0] done_irq_en     | RW   | 0         |
|       |                 | [1] err_irq_en      | RW   | 0         |
| 0x010 | IRQ_STA         | [0] done_irq        | RW1C | 0         |
|       |                 | [1] err_irq         | RW1C | 0         |
| 0x014 | PKT_LEN_EXP    | [5:0] exp_pkt_len    | RW   | 0         |
| 0x018 | RES_PKT_LEN    | [5:0] res_pkt_len    | RO   | 0         |
| 0x01C | RES_PKT_TYPE   | [7:0] res_pkt_type   | RO   | 0         |
| 0x020 | RES_PAYLOAD_SUM| [7:0] res_payload_sum | RO   | 0         |
| 0x024 | RES_PAYLOAD_XOR| [7:0] res_payload_xor | RO   | 0         |
| 0x028 | ERR_FLAG       | [0] length_error     | RO   | 0         |
|       |                 | [1] type_error       | RO   | 0         |
|       |                 | [2] chk_error        | RO   | 0         |

### 2.4 PKT_MEM 地址映射
- APB 地址 `0x040 + 4*N` -> SRAM Word N（N=0~7）
- wr_addr = PADDR[4:2]（由于 0x040 的 [4:2]=000，直接取位）

### 2.5 PSLVERR 生成规则
- 写 RO 寄存器（STATUS / RES_* / ERR_FLAG）-> PSLVERR=1，值不变
- busy=1 期间写 PKT_MEM -> PSLVERR=1，写入无效
- 访问保留/越界/非 word-aligned 地址 -> PSLVERR=1

### 2.6 start 脉冲逻辑
- 仅在 enable=1（已生效的寄存器值）且 busy=0 时接受
- 产生单拍脉冲，不存储
- 若同时写 enable=1 和 start=1，start 不会被接受（enable 尚未生效）

### 2.7 中断逻辑
- done_i 上升沿检测（done_rising = done_i & ~done_i_d）
- done_irq 置位：done_rising 且 done_irq_en=1
- err_irq 置位：done_rising 且任意 error 有效 且 err_irq_en=1
- IRQ_STA 清除优先于置位（互斥分支）
- irq_o = done_irq | err_irq（组合输出）

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

## 5 关键 Spec 引用
- APB 接口规则：spec 4.1
- 地址空间划分：spec 4.2
- CSR 寄存器表：spec 5.1~5.2
- PKT_MEM 窗口行为：spec 6.1~6.3
- PSLVERR 策略：spec 8.3
- 中断时序：spec 8.1~8.2

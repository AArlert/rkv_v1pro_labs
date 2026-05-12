# Lab3 设计指引 (Design Prompt)

## 目标

Lab3 实现 `ppa_top` 顶层集成，将 Lab1（M1+M2）与 Lab2（M3）连为完整数据通路

## 核心连线

| 路径 | 信号 | 方向 |
|------|------|------|
| M1 → M2 写端口 | pkt_mem_we/addr/wdata | M1 APB 写 PKT_MEM 时驱动 |
| M2 → M3 读端口 | rd_en/addr/data | M3 处理阶段读取 SRAM |
| M1 → M3 控制 | start, algo_mode, type_mask, exp_pkt_len | CSR 配置下发 |
| M3 → M1 状态/结果 | busy, done, format_ok, errors, res_* | 结果回传 CSR |
| M2 → M1 读回 | pkt_mem_rdata | APB 读 PKT_MEM 时返回 SRAM 数据 |
| 时钟复位 | PCLK/PRESETn → M1; PCLK→clk/PRESETn→rst_n → M2/M3 | ppa_top 统一分发 |

## 关键设计决策

### D1: M2 读端口仲裁

M2 只有一个读端口，M3（处理）和 M1（APB 读 PKT_MEM）共享。采用组合优先级 MUX：
- M3 `mem_rd_en_o=1` 时：M3 拥有读端口（处理优先）
- M3 空闲时：M1 `pkt_mem_re_o` 可驱动读端口

```verilog
assign m2_rd_en   = m3_mem_rd_en | m1_pkt_mem_re;
assign m2_rd_addr = m3_mem_rd_en ? m3_mem_rd_addr : m1_pkt_mem_addr;
```

### D2: U-1 解决方案

M1 新增 `pkt_mem_rdata_i` 输入和 `pkt_mem_re_o` 输出：
- `pkt_mem_re_o` 在 SETUP 阶段发起（给 SRAM 一拍读延迟）
- ACCESS 阶段 PRDATA 返回 `pkt_mem_rdata_i`（SRAM 已锁存好数据）

### D3: ppa_top 保持薄层

ppa_top 仅包含：
- 3 个子模块实例化
- 读端口仲裁 MUX（2 行组合逻辑）
- 无寄存器、无 FSM、无地址译码

## 端到端驱动序列

1. APB 写 PKT_MEM（0x040~0x05C）载入包数据
2. APB 写 CTRL.enable=1
3. APB 写 CTRL.start=1（W1P 触发）
4. 轮询 STATUS.done=1
5. APB 读 RES_PKT_LEN / RES_PKT_TYPE / RES_PAYLOAD_SUM / RES_PAYLOAD_XOR / ERR_FLAG

## 验证覆盖目标

最小 TB 覆盖 F3-01~F3-04（必做验收 1~3），含：
- TC1: 8B 合法包端到端
- TC2: 连续两帧（4B 最小包第二帧）
- TC3: STATUS 总线通路（busy/done 位读回）

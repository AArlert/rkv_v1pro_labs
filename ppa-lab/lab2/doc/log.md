# Lab2 实验日志

## 1 设计阶段

设计时间：2026-04-28

### 1.1 设计思路

本阶段实现包处理核心模块 `ppa_packet_proc_core`（M3），核心是一个 3 态 FSM（IDLE→PROCESS→DONE），负责从 SRAM 读取包数据、解析包头、执行格式检查、计算 payload 摘要

### 1.2 关键设计决策

#### 1.2.1 SRAM 同步读流水线处理

M2（ppa_packet_sram）采用同步读设计（`always_ff`），发出读地址后需要 1 个时钟周期才能收到数据。设计采用流水线方式处理：
- 转移拍（IDLE/DONE→PROCESS）：组合逻辑发出 rd_addr=0
- beat=0（PROCESS 第 1 拍）：收到 Word0 数据，解析头部；同时发出 rd_addr=1
- beat=1..N-1：收到 Word1..N-1，处理 payload 字节
- beat=N-1（满足 DONE 条件）：处理最后一个 word，转移到 DONE

这种设计避免了额外的等待周期，每拍都在做有效工作

#### 1.2.2 长度越界处理策略

对于 pkt_len < 4 或 pkt_len > 32 的越界包：
- 设置 `eff_total_words = 1`，仅读取头部 Word0
- 正常执行所有三类检查（length/type/hdr_chk），然后进入 DONE
- 确保 M3 不会因越界 pkt_len 而卡死（spec 明确要求 "M3 不卡死"）

#### 1.2.3 错误并行检查

三类错误（length_error、type_error、chk_error）在 beat=0 解析头部时同步计算，互不依赖，可以同时成立。这符合 spec 9.2 节 "三类错误可以同时成立" 的要求

#### 1.2.4 Payload 字节计数

- 使用 `bytes_processed` 寄存器跟踪已处理的 payload 字节数
- 每个 payload word 的有效字节数 = min(payload_len - bytes_processed, 4)
- 最后一个 word 可能部分有效，只处理有效字节
- 纯头部包（pkt_len=4）不处理 payload，sum=0，xor=0

### 1.3 对规格的假设

1. **Byte 序**：Word0 中 Byte0 = [7:0]、Byte1 = [15:8]、Byte2 = [23:16]、Byte3 = [31:24]（小端序），与 M1 写入 `PWDATA` 的字节排列一致
2. **eff_total_words 计算**：使用 `ceil(pkt_len/4)` 确定需要读取的 SRAM word 数，对越界 pkt_len 强制为 1
3. **exp_pkt_len_i = 0**：表示 "未配置"，不参与长度一致性检查。仅当 exp_pkt_len_i != 0 且与 pkt_len 不符时产生 length_error

### 1.4 端口列表

严格遵循 spec 2.3 节 M3 端口表，共 18 个端口：
- 输入 9 个：clk, rst_n, start_i, algo_mode_i, type_mask_i[3:0], exp_pkt_len_i[5:0], mem_rd_data_i[31:0]
- 输出 9 个：mem_rd_en_o, mem_rd_addr_o[2:0], busy_o, done_o, res_pkt_len_o[5:0], res_pkt_type_o[7:0], res_payload_sum_o[7:0], res_payload_xor_o[7:0], format_ok_o, length_error_o, type_error_o, chk_error_o

### 1.5 Testbench 设计

- 使用 SV 数组 `sram_model[0:7]` 替代 M2，带同步读延迟（`always_ff`），匹配真实 M2 时序
- `load_packet` task 将字节数组按小端序加载到 SRAM 模型
- `pulse_start` task 产生单拍 start 脉冲
- `wait_done` task 轮询 done_o 信号，带超时保护
- 所有测试用例均使用 `check/check1` task 进行自动比对

### 1.6 未决风险

| 编号 | 描述 | 严重性 |
|------|------|--------|
| R-1 | Byte 序假设尚未在集成环境中验证，需要 Lab3 确认 M1 写入和 M3 读出的字节对齐 | MEDIUM |
| R-2 | 越界 pkt_len（如 0 或 255）的行为完全依赖 eff_total_words=1 的截断策略，结果寄存器值可能不完全有意义 | LOW |
| R-3 | beat 计数器 4 位宽度足够覆盖最大 8 word 处理场景，但未添加溢出保护 | LOW |

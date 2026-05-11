# Lab2 设计文档：包处理核心（M3）

## 1 本阶段目标
- 实现 3 态 FSM（IDLE→PROCESS→DONE）模块 `ppa_packet_proc_core`（M3）
- 实现包头解析（pkt_len / pkt_type / flags / hdr_chk）
- 实现格式检查（长度范围、类型合法性、头校验）
- 实现 payload sum / XOR 计算
- 搭建 M3 独立 SV TB，完成基础功能验证

## 2 模块设计要点

### 2.1 三态 FSM

| 当前状态 | 条件 | 下一状态 | 动作 |
|----------|------|----------|------|
| IDLE | start_i=1 | PROCESS | 置 busy_o=1；清除上一帧结果；初始化字计数器 word_cnt=0；发起首次 SRAM 读 |
| IDLE | 其他 | IDLE | 保持 |
| PROCESS | 所有 word 处理完毕 | DONE | 写入结果和错误标志；置 busy_o=0, done_o=1 |
| PROCESS | 其他 | PROCESS | 每拍读一个 Word；累加 sum/XOR；递增计数器 |
| DONE | start_i=1 | PROCESS | 同 IDLE→PROCESS |
| DONE | 其他 | DONE | 保持 done_o=1；结果保持有效 |

### 2.2 SRAM 读时序适配

M2 使用同步读（rd_data 在 rd_en 有效后的下一拍可用）。设计采用流水线方式：
- 在 IDLE/DONE 收到 start_i 时：发起 rd_en=1, rd_addr=0（预取 Word0）
- 进入 PROCESS 后：第 0 拍等待 Word0 数据返回，同时发起 Word1 读请求
- 后续每拍：处理上一拍读回的数据，同时预取下一个 Word
- 最后一拍：处理最后一个有效 Word，不再发起新读请求

总 Word 数 = ceil(pkt_len / 4)，最少 1 word（pkt_len=4），最多 8 words（pkt_len=32）

### 2.3 PROCESS 内部数据流

| 阶段 | 操作 |
|------|------|
| Word0 返回 | 提取 pkt_len(B0) / pkt_type(B1) / flags(B2) / hdr_chk(B3)；执行长度/类型/校验检查 |
| Word1~N-1 返回 | 逐字节累加 payload_sum；逐字节 XOR payload_xor |
| 最后 Word | 仅处理有效字节（由 pkt_len 决定）；完成计算后进入 DONE |

注意：当 pkt_len ≤ 4 时无 payload，sum=0, xor=0

### 2.4 字节拆分

SRAM 存储为 32-bit word，字节序：`{B[4n+3], B[4n+2], B[4n+1], B[4n]}`
- Word0[7:0]   = Byte0 (pkt_len)
- Word0[15:8]  = Byte1 (pkt_type)
- Word0[23:16] = Byte2 (flags)
- Word0[31:24] = Byte3 (hdr_chk)

### 2.5 错误检查

三类错误并行检查，不互斥：

| 错误 | 条件 |
|------|------|
| length_error | pkt_len < 4 或 pkt_len > 32；或 pkt_len ≠ exp_pkt_len_i（当 exp_pkt_len_i ≠ 0 时） |
| type_error | pkt_type 不是有效 one-hot（0x01/0x02/0x04/0x08）；或 pkt_type 对应 bit 被 type_mask_i 屏蔽 |
| chk_error | 仅 algo_mode_i=1 时：hdr_chk ≠ (B0 ^ B1 ^ B2) |

format_ok = ~(length_error | type_error | chk_error)

### 2.6 输出时序

| 信号 | IDLE | PROCESS | DONE |
|------|------|---------|------|
| busy_o | 0 | 1 | 0 |
| done_o | 0（初始） | 0 | 1（保持） |
| mem_rd_en_o | 0 | 1（每拍） | 0 |
| 结果/错误 | 0（清零后） | 中间值 | 最终结果（保持） |

### 2.7 长度越界处理

当 pkt_len < 4 或 pkt_len > 32 时：
- 设置 length_error=1
- 仍需进入 DONE 态（M3 不卡死）
- 对于 pkt_len < 4：仅读 1 个 word（头部），无 payload 计算
- 对于 pkt_len > 32：按 32 字节处理（最多读 8 个 word），标记错误

## 3 验收标准

### 必做
1. 合法包完整处理：start 后 done_o 拉高；res_pkt_len/type 正确；FSM 显示 IDLE→PROCESS→DONE
2. 长度越界检测：pkt_len=3（下溢）和 pkt_len=33（上溢）时 length_error_o=1；M3 不卡死
3. busy/done 时序：start_i 有效后第 1 拍 busy_o=1；DONE 态 done_o 持续保持；再次 start 后 done_o 清零

### 选做
4. pkt_type 合法性 + type_mask 过滤
5. algo_mode=1 时 hdr_chk 校验；algo_mode=0 时旁路；payload sum/XOR 正确

## 4 文件清单

| 文件路径 | 说明 |
|----------|------|
| rtl/ppa_packet_proc_core.sv | M3 包处理核心 |
| svtb/tb/ppa_tb.sv | M3 独立 TB |
| svtb/sim/Makefile | 仿真入口 |

## 5 关键 Spec 引用
- 模块端口：spec §2.3 M3
- 包结构与格式：spec §3.1~3.4
- FSM 状态机：spec §7.1~7.4
- done/irq 时序：spec §8.1
- 错误码定义：spec §9.1~9.3

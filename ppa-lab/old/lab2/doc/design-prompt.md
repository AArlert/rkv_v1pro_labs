# Lab2 设计文档：包处理核心 FSM

## 1 本阶段目标
- 实现包处理核心模块 `ppa_packet_proc_core`（M3）
- 实现 3 态 FSM（IDLE→PROCESS→DONE）
- 实现包头解析逻辑（pkt_len / pkt_type / flags / hdr_chk）
- 实现格式检查算法（长度检查、类型检查、头校验）
- 实现 payload 的 sum 和 XOR 计算
- 搭建 M3 独立 SV TB，用 SV 数组行为模型替代 M2

## 2 模块设计要点

### 2.1 ppa_packet_proc_core（M3）

- 三态 FSM：IDLE → PROCESS → DONE
- 输入来自 M1 的控制信号：start_i、algo_mode_i、type_mask_i、exp_pkt_len_i
- 通过读端口从 M2 读取包数据：mem_rd_en_o / mem_rd_addr_o / mem_rd_data_i
- 输出处理结果和状态标志送 M1

### 2.2 FSM 状态转移

| 当前状态 | 条件 | 下一状态 | 动作 |
|---------|------|---------|------|
| IDLE | start_i=1 | PROCESS | 置 busy_o=1；清除上一帧结果；初始化字计数器；从 addr=0 开始读 M2 |
| IDLE | 其他 | IDLE | 保持 busy_o=0；保持 done_o 当前值 |
| PROCESS | 字节计数器达到 pkt_len | DONE | 停止读取；写入结果和错误标志；置 busy_o=0；置 done_o=1 |
| PROCESS | 其他 | PROCESS | 每拍读一个 32-bit Word；累加 sum/XOR；更新计数器 |
| DONE | start_i=1 | PROCESS | 同 IDLE→PROCESS（接受下一帧） |
| DONE | 其他 | DONE | 保持 done_o=1；结果保持有效 |

### 2.3 PROCESS 内部数据流

| 拍次 | 操作 |
|------|------|
| 第 0 拍 | 发出 rd_addr=0 读请求 |
| 第 1 拍 | 收到 Word0（Byte0–3）；提取 pkt_len/pkt_type/flags/hdr_chk；执行长度范围检查 [4,32]；执行类型合法性检查；执行 hdr_chk 校验（algo_mode=1 时）；同时发出 rd_addr=1 读请求 |
| 第 2–N 拍 | 收到 payload word；逐字节累加 res_payload_sum/res_payload_xor；发出下一个 rd_addr |
| 最后拍 | 完成全部计算；进入 DONE |

注意：SRAM 为同步读，发出地址后下一拍才返回数据，因此需要流水线式处理

### 2.4 包头解析（Word0）

Word0 的 32-bit 数据按小端字节序排列：
- Byte0 = mem_rd_data_i[7:0]   → pkt_len
- Byte1 = mem_rd_data_i[15:8]  → pkt_type
- Byte2 = mem_rd_data_i[23:16] → flags
- Byte3 = mem_rd_data_i[31:24] → hdr_chk

### 2.5 格式检查算法

#### 长度检查（length_error）
- pkt_len < 4 或 pkt_len > 32 → length_error = 1
- 若 exp_pkt_len_i != 0 且 pkt_len != exp_pkt_len_i → length_error = 1

#### 类型检查（type_error）
- pkt_type 不是有效 one-hot（0x01/0x02/0x04/0x08）→ type_error = 1
- pkt_type 对应 bit 被 type_mask_i 屏蔽 → type_error = 1
  - type_mask_i[0]=1 允许 pkt_type=0x01
  - type_mask_i[1]=1 允许 pkt_type=0x02
  - type_mask_i[2]=1 允许 pkt_type=0x04
  - type_mask_i[3]=1 允许 pkt_type=0x08

#### 头校验检查（chk_error）
- 仅在 algo_mode_i=1 时有效
- hdr_chk != (pkt_len ^ pkt_type ^ flags) → chk_error = 1
- algo_mode_i=0 时 chk_error 固定为 0

### 2.6 Payload 计算

- res_payload_sum：payload 各字节累加和，8-bit 截断
- res_payload_xor：payload 各字节逐位 XOR 结果
- 纯头部包（pkt_len=4）时 payload 为空，sum=0，xor=0

### 2.7 各状态输出约定

| 状态 | busy_o | done_o | mem_rd_en_o |
|------|--------|--------|-------------|
| IDLE | 0 | 0（初始）| 0 |
| PROCESS | 1 | 0 | 1（每拍） |
| DONE | 0 | 1（保持）| 0 |

### 2.8 结果清零时机

所有结果和错误标志（res_pkt_len_o、res_pkt_type_o、res_payload_sum_o、res_payload_xor_o、format_ok_o、length_error_o、type_error_o、chk_error_o）在"下一次合法 start 被接受时"同步清零

## 3 验收标准

### 必做
1. 合法包完整处理：start 后 done_o 拉高；res_pkt_len/type 正确；波形显示 IDLE→PROCESS→DONE
2. 长度越界检测：pkt_len=3（下溢）和 pkt_len=33（上溢）时 length_error_o=1；M3 不卡死
3. busy/done 时序：start_i 有效后第 1 拍 busy_o=1；DONE 态 done_o 持续保持；再次 start 后 done_o 清零

### 选做
4. pkt_type 合法性 + type_mask 过滤（两种情形均需波形演示）
5. algo_mode=1 时 hdr_chk 校验；algo_mode=0 时旁路；payload sum/XOR 正确

## 4 文件清单

| 文件路径 | 说明 |
|----------|------|
| rtl/ppa_packet_proc_core.sv | 包处理核心 FSM + 算法 |
| svtb/tb/ppa_tb.sv | M3 独立 TB（SV 数组替代 M2） |
| svtb/sim/Makefile | 仿真入口 |

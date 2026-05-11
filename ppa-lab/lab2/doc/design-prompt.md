# Lab2 设计文档：包处理核心 M3

## 1 本阶段目标
- 实现包处理核心模块 `ppa_packet_proc_core`（M3）
- 完成 3 态 FSM（IDLE → PROCESS → DONE），驱动 M2 SRAM 读取
- 实现包头解析、长度/类型/头校验检查、payload sum/XOR 计算
- 提供 M3 独立的最小 SV TB（使用行为级 SRAM 模型，不依赖 M1）
- `make comp` 通过，`make run` 覆盖 F2-01~F2-14 基础场景

## 2 模块设计要点

### 2.1 端口（来源：spec §2.3 M3）
- 输入：`clk / rst_n / start_i / algo_mode_i / type_mask_i[3:0] / exp_pkt_len_i[5:0] / mem_rd_data_i[31:0]`
- 输出：`mem_rd_en_o / mem_rd_addr_o[2:0] / busy_o / done_o`
- 输出结果：`res_pkt_len_o[5:0] / res_pkt_type_o[7:0] / res_payload_sum_o[7:0] / res_payload_xor_o[7:0]`
- 输出错误标志：`format_ok_o / length_error_o / type_error_o / chk_error_o`

### 2.2 FSM 结构（spec §7.1 §7.2 §7.4）
| 当前态 | 条件 | 下一态 | 关键动作 |
|--------|------|--------|----------|
| IDLE | `start_i=1` | PROCESS | 清结果/错误；置 `busy=1`；驱动 `rd_addr=0, rd_en=1` |
| IDLE | 其他 | IDLE | `busy=0`；`done` 保持上次完成状态 |
| PROCESS | 已消费 `words_total-1` word | DONE | 停读；`busy<=0`；`done<=1`；写 `format_ok` |
| PROCESS | 其他 | PROCESS | 继续读下一 word；累加 sum/XOR |
| DONE | `start_i=1` | PROCESS | 同 IDLE→PROCESS（清结果） |
| DONE | 其他 | DONE | 保持 `done=1`、结果有效 |

### 2.3 SRAM 读时序（关键）
M2 为同步读 SRAM：在 cycle T 驱动 `rd_en=1, rd_addr=A`，`rd_data` 在 cycle T+1 的上升沿生效。
- IDLE→PROCESS 的同拍：驱动 word 0 的读请求
- 下一拍：捕获 word 0（header），同拍驱动 word 1 的读请求
- 以此流水到最后一个 word
- 单 word 包（pkt_len ∈ [4,7] 或越界判定走 1-word 路径）：捕获 header 后直接进 DONE

### 2.4 包头解析（spec §3.1 §7.3）
来自 word 0：
- `pkt_len  = data[7:0]`
- `pkt_type = data[15:8]`
- `flags    = data[23:16]`（保留，不参与）
- `hdr_chk  = data[31:24]`

### 2.5 错误判定（spec §9.1，**三类可并行**）
- `length_error`：`pkt_len<4 || pkt_len>32 || (exp_pkt_len_i!=0 && pkt_len[5:0]!=exp_pkt_len_i)`
  - PKT_LEN_EXP 复位值为 0，按"未配置"语义旁路一致性检查（spec §5.2 默认 0）
- `type_error`：`pkt_type` 非 one-hot（∉ {0x01,0x02,0x04,0x08}），或对应 `type_mask` bit 为 0
- `chk_error`：`algo_mode_i=1` 且 `hdr_chk != B0^B1^B2`；`algo_mode_i=0` 时恒 0（spec §9.1）
- `format_ok = !length_error & !type_error & !chk_error`

### 2.6 words_total 计算
- 越界（`pkt_len<4 || >32`）：`words_total=1`（只消费 header 即终止，防卡死，对应 F2-13）
- 合法范围：`words_total = ceil(pkt_len/4) = (pkt_len+3)>>2`，取值 [1,8]

### 2.7 payload sum / XOR（spec §3.4 §7.3）
- 对 word 索引 ≥1 的每个返回 word，按字节展开
- 字节有效条件：`byte_offset = cap_idx*4 + k < pkt_len`（k=0..3）
- `sum` 为 8-bit 截断累加；`xor` 为按位异或
- 越界 word 不会到达（words_total 已收敛）

### 2.8 结果保持（spec §7.2 §7.4）
- DONE 态所有结果寄存器保持，直到下次 `start_i` 接受时被清零并重新计算（对应 F2-12）
- `done_o` 在 DONE 态保持高电平；接受新 start 当拍清零

## 3 验收标准（详见 acceptance.md）

### 必做
1. 合法包完整处理（res_pkt_len/type 正确、FSM 波形 IDLE→PROCESS→DONE）
2. 长度越界检测（pkt_len=3 下溢 / pkt_len=33 上溢，length_error=1 且不卡死）
3. busy/done 时序（start 后 busy=1，DONE 态 done 保持，新 start 后清零）

### 选做
4. pkt_type 合法性 + type_mask 过滤
5. algo_mode hdr_chk 校验 + payload sum/XOR 正确

## 4 文件清单

| 文件路径 | 说明 |
|----------|------|
| `rtl/ppa_packet_proc_core.sv` | M3 RTL |
| `svtb/tb/ppa_tb.sv` | M3 独立 TB（行为级 SRAM 模型） |
| `svtb/sim/Makefile` | 仿真入口（comp/run/rung/clean） |

## 5 关键 Spec 引用
- 包格式与字段：spec §3.1
- 包长约束：spec §3.2
- 算法核输出：spec §3.4
- FSM 状态与输出：spec §7.1 §7.2 §7.4
- PROCESS 内部数据流：spec §7.3
- 错误码与判定优先级：spec §9.1 §9.2
- 错误清除时机：spec §9.3
- 验收场景：spec §10.1 §10.2 §10.3 §11.3

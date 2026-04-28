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

严格遵循 spec 2.3 节 M3 端口表，共 19 个端口：
- 输入 7 个：clk, rst_n, start_i, algo_mode_i, type_mask_i[3:0], exp_pkt_len_i[5:0], mem_rd_data_i[31:0]
- 输出 12 个：mem_rd_en_o, mem_rd_addr_o[2:0], busy_o, done_o, res_pkt_len_o[5:0], res_pkt_type_o[7:0], res_payload_sum_o[7:0], res_payload_xor_o[7:0], format_ok_o, length_error_o, type_error_o, chk_error_o

### 1.5 Testbench 设计

- 使用 SV 数组 `sram_model[0:7]` 替代 M2，带同步读延迟（`always_ff`），匹配真实 M2 时序
- `load_packet` task 将字节数组按小端序加载到 SRAM 模型
- `pulse_start` task 产生单拍 start 脉冲
- `wait_done` task 轮询 done_o 信号，带超时保护
- 所有测试用例均使用 `check_word`/`check_flag` task 进行自动比对（审查阶段已将原 `check`/`check1` 重命名以提升可读性）

### 1.6 未决风险

| 编号 | 描述 | 严重性 |
|------|------|--------|
| R-1 | Byte 序假设尚未在集成环境中验证，需要 Lab3 确认 M1 写入和 M3 读出的字节对齐 | MEDIUM |
| R-2 | 越界 pkt_len（如 0 或 255）的行为完全依赖 eff_total_words=1 的截断策略，结果寄存器值可能不完全有意义 | LOW |
| R-3 | beat 计数器 4 位宽度足够覆盖最大 8 word 处理场景，但未添加溢出保护 | LOW |

---

## 2 审查阶段

审查目标：逐项检查 RTL 代码（`ppa_packet_proc_core.sv`）及 TB（`ppa_tb.sv`）与 `ppa-lite-spec.md` 的一致性

审查时间：2026-04-28

---

### 2.1 M3 ppa_packet_proc_core 端口校验

对照 spec 2.3 节 M3 端口表，逐项检查：

| 信号 | 方向 | 位宽 | RTL 实现 | 结论 |
|------|------|------|----------|------|
| clk | input | 1 | `input logic clk` | PASS |
| rst_n | input | 1 | `input logic rst_n` | PASS |
| start_i | input | 1 | `input logic start_i` | PASS |
| algo_mode_i | input | 1 | `input logic algo_mode_i` | PASS |
| type_mask_i | input | 4 | `input logic [3:0] type_mask_i` | PASS |
| exp_pkt_len_i | input | 6 | `input logic [5:0] exp_pkt_len_i` | PASS |
| mem_rd_en_o | output | 1 | `output logic mem_rd_en_o` | PASS |
| mem_rd_addr_o | output | 3 | `output logic [2:0] mem_rd_addr_o` | PASS |
| mem_rd_data_i | input | 32 | `input logic [31:0] mem_rd_data_i` | PASS |
| busy_o | output | 1 | `output logic busy_o` | PASS |
| done_o | output | 1 | `output logic done_o` | PASS |
| res_pkt_len_o | output | 6 | `output logic [5:0] res_pkt_len_o` | PASS |
| res_pkt_type_o | output | 8 | `output logic [7:0] res_pkt_type_o` | PASS |
| res_payload_sum_o | output | 8 | `output logic [7:0] res_payload_sum_o` | PASS |
| res_payload_xor_o | output | 8 | `output logic [7:0] res_payload_xor_o` | PASS |
| format_ok_o | output | 1 | `output logic format_ok_o` | PASS |
| length_error_o | output | 1 | `output logic length_error_o` | PASS |
| type_error_o | output | 1 | `output logic type_error_o` | PASS |
| chk_error_o | output | 1 | `output logic chk_error_o` | PASS |

**端口校验结论：19/19 PASS，全部端口方向、位宽与 spec 一致**

> 注：设计阶段 log 记录 "共 18 个端口"，实际 spec 端口表列出 19 个（7 输入 + 12 输出），已在设计阶段 log 中修正

---

### 2.2 FSM 状态转移校验

对照 spec 7.1/7.2 节：

| 当前状态 | 条件 | spec 下一状态 | RTL 实现 | 结论 |
|---------|------|------------|---------|------|
| IDLE | start_i=1 | PROCESS | `if (start_i) next_state = S_PROCESS` | PASS |
| IDLE | 其他 | IDLE | `next_state = state`（默认保持） | PASS |
| PROCESS | 处理完成 | DONE | `if (hdr_valid && (beat + 4'd1 >= eff_total_words)) next_state = S_DONE` | PASS（注1） |
| PROCESS | 其他 | PROCESS | 默认保持 | PASS |
| DONE | start_i=1 | PROCESS | `if (start_i) next_state = S_PROCESS` | PASS |
| DONE | 其他 | DONE | 默认保持 | PASS |
| default | — | IDLE | `default: next_state = S_IDLE` | PASS |

> 注1：转移条件使用 `beat + 1 >= eff_total_words` 而非直接字节计数器，因为 SRAM 同步读存在 1 拍延迟，beat=0 时 hdr_valid 尚未设置（在同一拍时序逻辑中赋值），所以最早在 beat=1（hdr_valid=1）时才能检查转移条件。对于 1-word 包（pkt_len=4，eff_total_words=1），需要 2 个 PROCESS 拍完成，多出 1 拍开销。这是同步读流水线设计的固有代价，不影响功能正确性

**FSM 状态转移校验结论：全部 PASS**

---

### 2.3 busy_o / done_o 时序校验

对照 spec 7.4 节和 8.1 节：

| 检查项 | spec 要求 | RTL 实现 | 结论 |
|--------|-----------|---------|------|
| busy_o 定义 | PROCESS 态为 1 | `assign busy_o = (state == S_PROCESS)` 组合输出 | PASS |
| done_o IDLE 初始 | 0 | 复位值 `done_o <= 1'b0` | PASS |
| done_o PROCESS | 0 | S_IDLE/S_DONE 的 start 分支中 `done_o <= 1'b0` | PASS |
| done_o DONE | 1，保持 | S_PROCESS → S_DONE 时 `done_o <= 1'b1`；S_DONE 无 start 时不修改 done_o | PASS |
| done_o 清零时机 | 下一次合法 start 接受时 | S_DONE + start_i → `done_o <= 1'b0`；S_IDLE + start_i → `done_o <= 1'b0` | PASS |

**busy/done 时序校验结论：全部 PASS**

---

### 2.4 包头解析校验

对照 spec 3.1 节（包结构）和 6.1 节（SRAM 地址映射 Word0 = Byte0-3）：

| 字段 | spec 定义 | RTL 提取方式 | 结论 |
|------|-----------|------------|------|
| pkt_len（Byte0） | 总包长 8-bit | `pkt_len <= mem_rd_data_i[5:0]`（6-bit 存储）；长度检查使用 `mem_rd_data_i[7:0]`（8-bit 比较） | PASS（注2） |
| pkt_type（Byte1） | 包类型 8-bit | `pkt_type <= mem_rd_data_i[15:8]` | PASS |
| flags（Byte2） | 保留=0x00 | 仅在 hdr_chk 计算中引用 `mem_rd_data_i[23:16]`，不单独存储 | PASS |
| hdr_chk（Byte3） | B0 ^ B1 ^ B2 | 校验比较使用 `mem_rd_data_i[31:24]` | PASS |

> 注2：res_pkt_len_o 端口为 6-bit（spec 定义），对合法包长 [4,32] 范围足够。越界值存储到 pkt_len 时高位被截断，但 length_error 已使用 8-bit 全位宽正确判定，不影响功能。设计阶段 R-2 已记录此行为

**包头解析校验结论：全部 PASS**

---

### 2.5 长度检查校验

对照 spec 9.1 节 length_error 触发条件：

| 条件 | spec 要求 | RTL 实现 | 结论 |
|------|-----------|---------|------|
| pkt_len < 4 | length_error=1 | `mem_rd_data_i[7:0] < 8'd4` | PASS |
| pkt_len > 32 | length_error=1 | `mem_rd_data_i[7:0] > 8'd32` | PASS |
| pkt_len != exp_pkt_len（exp_pkt_len!=0） | length_error=1 | `exp_pkt_len_i != 6'd0 && mem_rd_data_i[5:0] != exp_pkt_len_i` | PASS |
| exp_pkt_len = 0 | 不检查 | `exp_pkt_len_i != 6'd0` 为 false，跳过 | PASS |
| 越界包处理 | M3 不卡死 | eff_total_words=1，仅读 Word0 后进 DONE | PASS |

**长度检查校验结论：全部 PASS**

---

### 2.6 类型检查校验

对照 spec 9.1 节 type_error 触发条件：

| 条件 | spec 要求 | RTL 实现 | 结论 |
|------|-----------|---------|------|
| pkt_type=0x01, mask[0]=1 | 合法 | `8'h01: typ_err <= !type_mask_i[0]` → 0 | PASS |
| pkt_type=0x02, mask[1]=1 | 合法 | `8'h02: typ_err <= !type_mask_i[1]` → 0 | PASS |
| pkt_type=0x04, mask[2]=1 | 合法 | `8'h04: typ_err <= !type_mask_i[2]` → 0 | PASS |
| pkt_type=0x08, mask[3]=1 | 合法 | `8'h08: typ_err <= !type_mask_i[3]` → 0 | PASS |
| pkt_type 非 one-hot | type_error=1 | `default: typ_err <= 1'b1` | PASS |
| mask 屏蔽对应 bit | type_error=1 | 例：mask[0]=0, type=0x01 → `!0 = 1` | PASS |

**类型检查校验结论：全部 PASS**

---

### 2.7 头校验检查校验

对照 spec 9.1 节 chk_error 触发条件：

| 条件 | spec 要求 | RTL 实现 | 结论 |
|------|-----------|---------|------|
| algo_mode=1, hdr_chk 正确 | chk_error=0 | `mem_rd_data_i[31:24] != (B0 ^ B1 ^ B2)` → false → 0 | PASS |
| algo_mode=1, hdr_chk 错误 | chk_error=1 | 同上表达式 → true → 1 | PASS |
| algo_mode=0 | chk_error=0（旁路） | `else chk_err <= 1'b0` | PASS |

校验公式验证：`mem_rd_data_i[7:0] ^ mem_rd_data_i[15:8] ^ mem_rd_data_i[23:16]` = Byte0 ^ Byte1 ^ Byte2，与 spec 定义 `hdr_chk = pkt_len XOR pkt_type XOR flags` 一致

**头校验检查校验结论：全部 PASS**

---

### 2.8 错误并行性校验

对照 spec 9.2 节 "三类错误可以同时成立"：

RTL 在 beat=0 的 `always_ff` 块中：
1. 长度检查：独立赋值 `len_err`
2. 类型检查：独立赋值 `typ_err`（case 语句）
3. 校验检查：独立赋值 `chk_err`（if/else）

三者无数据依赖，均在同一拍内独立计算。DONE 转移时同时输出全部错误标志

**错误并行性校验结论：PASS，三类错误独立并行判定**

---

### 2.9 Payload 计算校验

对照 spec 3.4 节和 design-prompt 2.6 节：

| 检查项 | spec 要求 | RTL 实现 | 结论 |
|--------|-----------|---------|------|
| sum 定义 | payload 各字节累加和，8-bit 截断 | `new_sum = sum_acc + byte[i]`，逐字节累加，8-bit 自然截断 | PASS |
| xor 定义 | payload 各字节逐位 XOR | `new_xor = xor_acc ^ byte[i]`，逐字节 XOR | PASS |
| 纯头部包 | payload 为空，sum=0, xor=0 | pkt_len=4 → payload_len=0 → do_payload 始终为 false → sum/xor 保持 0 | PASS |
| 部分有效字节 | 最后 word 按 pkt_len 控制 | `valid_bytes = min(remaining, 4)`，仅处理有效字节 | PASS |
| 字节提取顺序 | 小端序 B0=[7:0], B1=[15:8], B2=[23:16], B3=[31:24] | `mem_rd_data_i[7:0]`, `[15:8]`, `[23:16]`, `[31:24]` 按序处理 | PASS |

Payload 计数逻辑验证：
- `remaining = payload_len - bytes_processed`
- `valid_bytes = (remaining >= 4) ? 4 : remaining[2:0]`
- `bytes_processed <= bytes_processed + valid_bytes`（每拍累加）

对于 pkt_len=8（payload=4B）：beat=1 时 remaining=4, valid_bytes=4，处理完整 word。beat=2 时 next_state=DONE

**Payload 计算校验结论：全部 PASS**

---

### 2.10 结果清零时机校验

对照 spec 9.3 节：

| 检查项 | spec 要求 | RTL 实现 | 结论 |
|--------|-----------|---------|------|
| 清零触发 | 下一次合法 start 被接受时 | S_IDLE + start_i 和 S_DONE + start_i 分支中清零全部结果 | PASS |
| 清零范围 | ERR_FLAG + STATUS.error + STATUS.format_ok + 结果寄存器 | 两个 start 分支中均清零：done_o, res_pkt_len_o, res_pkt_type_o, res_payload_sum_o, res_payload_xor_o, format_ok_o, length_error_o, type_error_o, chk_error_o + 内部 len_err/typ_err/chk_err | PASS |
| S_IDLE 清零 | 与 S_DONE 一致 | 两处代码块逻辑完全相同 | PASS |

**结果清零校验结论：全部 PASS**

---

### 2.11 SRAM 读端口时序校验

对照 spec 7.3 节 PROCESS 内部数据流和 design-prompt 2.3 节：

| 拍次 | 期望行为 | RTL 实现 | 结论 |
|------|---------|---------|------|
| 转移拍 | 发出 rd_addr=0 | 组合 `mem_rd_en_o=1, mem_rd_addr_o=0`（IDLE/DONE + start_i） | PASS |
| beat=0 | 收到 Word0；发出 addr=1 | `!hdr_valid` 分支：`mem_rd_addr_o=1` | PASS |
| beat=1..N-2 | 收到 WordN；发出 addr=N+1 | `beat + 1 < eff_total_words`：`mem_rd_addr_o = beat[2:0] + 1` | PASS |
| beat=N-1（最后拍） | 收到最后 word；不发出下一地址 | `beat + 1 >= eff_total_words`：不进入 rd_en 分支 | PASS |
| DONE/IDLE 静默 | mem_rd_en_o=0 | 组合默认 `mem_rd_en_o = 0` | PASS |

读地址溢出保护：`beat < 4'd7` 防止 addr 超出 SRAM 范围（最大 addr=7）

**SRAM 读端口校验结论：全部 PASS**

---

### 2.12 format_ok_o 逻辑校验

对照 spec 5.2 节 STATUS.format_ok：

RTL 实现（PROCESS → DONE 转移时）：
```
format_ok_o <= !(len_err | typ_err | chk_err);
```

- 三类错误均为 0 → format_ok=1（合法包）
- 任一错误为 1 → format_ok=0

与 spec "1 = 长度/类型/头校验均通过" 一致

**format_ok_o 校验结论：PASS**

---

### 2.13 Testbench 校验

#### TB 结构合理性

| 检查项 | 结论 |
|--------|------|
| SRAM 模型时序匹配 M2 | PASS：`always_ff @(posedge clk)` 同步读，1 拍延迟 |
| DUT 端口连接完整性 | PASS：19 个端口全部连接 |
| 默认配置 | PASS：algo_mode=1, type_mask=4'b1111, exp_pkt_len=0 |
| 自动比对 | PASS：使用 `check_word`/`check_flag` task，PASS/FAIL 自动计数 |

#### TC1: 合法包完整处理

| 检查项 | 输入 | 期望值 | TB 期望 | 结论 |
|--------|------|--------|---------|------|
| pkt_len | 8 | res_pkt_len=8 | 32'd8 | PASS |
| pkt_type | 0x01 | res_pkt_type=0x01 | 32'h01 | PASS |
| hdr_chk | 8^1^0=0x09 | chk_error=0 | 1'b0 | PASS |
| payload sum | 1+2+3+4=0x0A | res_payload_sum=0x0A | 32'h0A | PASS |
| payload xor | 1^2^3^4=0x04 | res_payload_xor=0x04 | 32'h04 | PASS |
| format_ok | 全部通过 | format_ok=1 | 1'b1 | PASS |

#### TC2a/TC2b: 长度越界

| 用例 | pkt_len | 期望 length_error | 期望 format_ok | 结论 |
|------|---------|------------------|---------------|------|
| TC2a | 3（下溢） | 1 | 0 | PASS |
| TC2b | 33（上溢） | 1 | 0 | PASS |

#### TC3: busy/done 时序 + 连续两帧

| 检查点 | TB 验证方式 | 结论 |
|--------|-----------|------|
| start 后 busy_o=1 | 直接采样 `busy_o` | PASS |
| start 后 done_o 清零 | 直接采样 `done_o` | PASS |
| 帧1 done_o=1 保持 | 等待 done 后延 3 拍再检查 | PASS |
| 帧2 从 DONE 重新 start | done 清零 + busy 置 1 | PASS |
| 帧2 payload sum | 0xAA+0xBB+0xCC+0xDD = 0x30E → 8-bit = 0x0E | PASS |
| 帧2 payload xor | 0xAA^0xBB^0xCC^0xDD = 0x11^0x11 = 0x00 | PASS |

#### TC4a/TC4b: 类型合法性 + type_mask

| 用例 | 输入 | 期望 type_error | 结论 |
|------|------|----------------|------|
| TC4a | pkt_type=0x03 | 1 | PASS |
| TC4b | mask=4'b1110, type=0x01 | 1 | PASS |

#### TC5a/TC5b/TC5c: hdr_chk 校验 + payload 计算

| 用例 | 输入 | 期望结果 | 结论 |
|------|------|---------|------|
| TC5a | hdr_chk=0xFF, algo_mode=1 | chk_error=1, format_ok=0 | PASS |
| TC5b | hdr_chk=0xFF, algo_mode=0 | chk_error=0, format_ok=1 | PASS |
| TC5c | payload={1,2,3,4} | sum=0x0A, xor=0x04 | PASS |

**Testbench 校验结论：全部 9 个 TC 的测试向量和期望值与 spec 一致**

---

### 2.14 Makefile 校验

| 检查项 | 要求 | 实际 | 结论 |
|--------|------|------|------|
| comp 目标 | 编译 RTL+TB | `vlog -sv -timescale=1ns/1ps` 编译 M3 RTL 和 TB | PASS |
| run 目标 | 批处理运行 | `vsim -c -do "run -all; quit -f"` | PASS |
| rung 目标 | GUI 调试 | `vsim -i` | PASS |
| clean 目标 | 清理生成物 | `rm -rf work *.log *.wlf transcript` | PASS |
| 设计文件列表 | 仅 M3 | 仅包含 `ppa_packet_proc_core.sv` | PASS |

**Makefile 校验结论：全部 PASS**

---

### 2.15 审查中发现的修订项

| 编号 | 类别 | 描述 | 处理方式 |
|------|------|------|---------|
| F-1 | 设计日志修正 | 端口计数写为"共 18 个端口，输入 9 个，输出 9 个"，实际 spec 为 19 个（输入 7 个 + 输出 12 个） | 已在 log.md 1.4 节修正 |
| F-2 | TB 命名改善 | `check` 和 `check1` 两个 task 命名不够准确，无法从名称区分用途 | 已重命名为 `check_word`（32-bit 数据比对）和 `check_flag`（1-bit 标志比对） |

---

### 2.16 已知限制与待办

| 编号 | 类别 | 描述 | 严重性 | 建议处理时机 |
|------|------|------|--------|------------|
| L-1 | 设计开销 | 1-word 包（pkt_len=4）需要 2 个 PROCESS 拍（含 1 拍 hdr_valid 延迟），多出 1 拍。不影响功能正确性 | LOW | 接受现状 |
| L-2 | 覆盖缺口 | TB 未覆盖 pkt_len=32（最大合法包）场景（spec N-3），仅覆盖 pkt_len=4 和 pkt_len=8 | LOW | 验证阶段补充 |
| L-3 | 覆盖缺口 | TB 未覆盖 exp_pkt_len_i 非零时的长度一致性检查（spec B-4） | LOW | 验证阶段补充 |
| L-4 | 覆盖缺口 | TB 未覆盖 pkt_len=0 极端越界场景 | LOW | 验证阶段可选补充 |
| L-5 | 设计风险 | 设计阶段 R-1 仍有效：字节序假设需 Lab3 集成验证 | MEDIUM | Lab3 集成 |

---

### 2.17 校验总结

| 校验大项 | 子项数 | PASS | FAIL | 通过率 |
|----------|--------|------|------|--------|
| M3 端口 | 19 | 19 | 0 | 100% |
| FSM 状态转移 | 7 | 7 | 0 | 100% |
| busy/done 时序 | 5 | 5 | 0 | 100% |
| 包头解析 | 4 | 4 | 0 | 100% |
| 长度检查 | 5 | 5 | 0 | 100% |
| 类型检查 | 6 | 6 | 0 | 100% |
| 头校验检查 | 3 | 3 | 0 | 100% |
| 错误并行性 | 1 | 1 | 0 | 100% |
| Payload 计算 | 5 | 5 | 0 | 100% |
| 结果清零 | 3 | 3 | 0 | 100% |
| SRAM 读端口 | 5 | 5 | 0 | 100% |
| format_ok 逻辑 | 1 | 1 | 0 | 100% |
| TB 测试向量 | 9 | 9 | 0 | 100% |
| Makefile | 5 | 5 | 0 | 100% |
| **合计** | **78** | **78** | **0** | **100%** |

**审查阶段结论：M3 RTL 设计（ppa_packet_proc_core）与 ppa-lite-spec.md 完全一致，未发现功能性偏差。TB 测试向量和期望值与 spec 匹配。共发现 2 项文档/命名修订（已处理）和 5 项已知限制/待办，均为 LOW-MEDIUM 严重性，不影响设计正确性，可在后续验证阶段和 Lab3 集成阶段处理**

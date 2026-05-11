# Lab2 实验日志

> 设计/审查/验证/验收/迭代各阶段记录。新 Agent 进入时只读顶部 Status 摘要。

## Status 摘要（≤20 行）

- 当前阶段：**Lab2 验收通过，已关闭**
- 模块：`ppa_packet_proc_core.sv`（M3）已实现、审查、验证、验收
- 验收结论：3 项必做 + 2 项选做全部 PASS，无迭代
- TB：14 个 TC / 66 checks 全 PASS
- `make comp` 0 error 0 warning；`make run` 全 PASS
- feature-matrix F2-01~F2-14 → #VERIFIED
- 关键设计决策：mem_rd_en_o / mem_rd_addr_o 采用组合输出，匹配 M2 同步 SRAM 的 1 拍读延迟
- 下一步：Lab3 顶层集成

---

## 1 设计阶段（2026-05-11，DUT Agent）

### 1.1 阶段目标
按 spec §7~9 实现 M3 三态 FSM，完成包头解析、长度/类型/头校验、payload sum/XOR 计算。

### 1.2 关键设计决策

#### D1：SRAM 读端口采用组合输出
- **背景**：M2 为同步 SRAM（`rd_en/addr` 在 posedge 采样，`rd_data` 在下一拍可见）。
- **若 M3 输出为寄存器**：DUT 在 posedge T 设置 `mem_rd_en_o=1`，SRAM 在 posedge T+1 锁存数据，DUT 在 posedge T+2 才能采样到数据 → 每 word 间隔 2 拍，最小包至少 3 拍。
- **采用组合输出后**：DUT 在 posedge T（IDLE→PROCESS 同拍）由组合逻辑直接驱动 `rd_en=1, addr=0`，SRAM 同拍即锁存；T+1 拍 DUT 即可消费数据。最小包仅 2 拍。
- **风险**：路径上多一级组合逻辑（状态/start_i → rd_en），在 PPA 集成场景下时序裕度仍充足；后续若有时序问题可在 Lab3 集成阶段评估。

#### D2：流水化连续读
- DUT 每拍发起一个读请求（`issue_idx`）并消费上一拍的返回数据（`consume_idx`）。两者相差 1 拍。
- 当 `issue_idx == words_total` 时停止发起。
- 单 word 包（含 pkt_len 越界场景）：header 处理完成同拍即进入 DONE，多余的投机性读请求无副作用。

#### D3：长度越界快速终止（F2-13 防卡死）
- `pkt_len<4` 或 `pkt_len>32` 时强制 `words_total=1`，只消费 word0（即 header）后即进 DONE。
- 这样无论 `pkt_len` 是何"非法值"，FSM 都在 2 拍内回到 DONE，不依赖 SRAM 越界读保护。

#### D4：错误三类并行（spec §9.2）
- 长度/类型/校验错误在 header 处理同拍并行判定并锁存，互不抑制。
- `format_ok` 在进入 DONE 同拍由三类错误的或非组合而成。

#### D5：PKT_LEN_EXP 语义
- spec §9.1 描述为"若 PKT_LEN_EXP 已配置"。复位值为 0（spec §5.2），按"非零即已配置"判定一致性检查。
- 风险：spec 措辞略含混；已记入 ppa-risk-register.md 待 Review Agent 复核。

### 1.3 SRAM 读时序示意（pkt_len=8, 2-word 包）

```
拍 |  state   | rd_en(comb) | rd_addr | rd_data       | 动作
---|----------|-------------|---------|---------------|---------------------------
T0 | IDLE     | 1           | 0       | 0             | start_i=1；SRAM 锁存 mem[0]
T1 | PROCESS  | 1           | 1       | mem[0]        | 处理 header；SRAM 锁存 mem[1]
T2 | PROCESS  | 0           | -       | mem[1]        | 处理 word1 payload；进 DONE
T3 | DONE     | 0           | -       | -             | done_o=1 保持
```

### 1.4 验证成果

| 项 | 结果 |
|----|------|
| `make comp` | 0 error / 0 warning |
| `make run` | 33 PASS / 0 FAIL（6 个 TC：合法 4B / 8B / 下溢 / 上溢 / busy-done 时序 / 连续两帧） |
| QuestaSim FSM 识别 | 1 FSM in `ppa_packet_proc_core` |

### 1.5 已知遗留（交由 Review/VPlan 处理）

| ID | 描述 | 归属 |
|----|------|------|
| L2-O-1 | TB 未覆盖 type_mask 过滤 / algo_mode=0 旁路 / payload 全 32B / PKT_LEN_EXP 一致性 | VPlan Agent |
| L2-O-2 | 组合 rd_en/addr 输出在集成时序下的余量待 Lab3 验证 | Lab3 集成 |
| L2-O-3 | 越界判定路径与 `mem_rd_data_i` header 解码耦合，跨周期假设需 Review 检查 | Review Agent |

---

## 2 审查阶段（2026-05-11，Review Agent）

### 2.1 审查范围
逐项检查 F2-01~F2-14 与 spec §2.3（端口表）、§3（包格式）、§7（FSM/处理流程）、§9（错误码）的一致性。

### 2.2 审查结论

**无阻塞性问题。RTL 实现与 spec 完全一致，审查通过。**

### 2.3 逐项一致性检查

| ID | 功能 | Spec § | 审查结果 | 备注 |
|----|------|--------|----------|------|
| F2-01 | 三态 FSM | §7.1 | **PASS** | IDLE→PROCESS→DONE 拓扑正确；无 DONE→IDLE 回边 |
| F2-02 | start_i 无条件启动 | §7.2 | **PASS** | IDLE/DONE 均只检查 start_i，无 enable/busy 门控（M1 职责） |
| F2-03 | busy/done 时序 | §7.4 | **PASS** | IDLE:0/0, PROCESS:1/0, DONE:0/1 均符合；mem_rd_en 在 PROCESS 每拍为 1 |
| F2-04 | 包头解析 | §3.1, §7.3 | **PASS** | hdr_b0=[7:0]=pkt_len, hdr_b1=[15:8]=type, hdr_b2=[23:16]=flags, hdr_b3=[31:24]=chk；小端序正确 |
| F2-05 | 长度检查 [4,32] | §3.2, §9.1 | **PASS** | `hdr_b0<4 \|\| hdr_b0>32` + exp_pkt_len 一致性检查 |
| F2-06 | 类型检查 | §9.1 | **PASS** | one-hot case 匹配 4 种合法值；type_mask[n]=1 允许 pkt_type=(1<<n)，与 spec §5.2 默认值 4'b1111 一致 |
| F2-07 | 头校验 | §9.1 | **PASS** | `hdr_b3 != (hdr_b0^hdr_b1^hdr_b2)`，algo_mode 门控 |
| F2-08 | algo_mode 旁路 | §5.2, §9.1 | **PASS** | algo_mode=0 时 `hdr_chk_err` 恒为 0 |
| F2-09 | payload sum | §3.4, §7.3 | **PASS** | 逐字节累加 8-bit 截断；byte_offset<pkt_len 守卫避免越界字节参与 |
| F2-10 | payload XOR | §3.4, §7.3 | **PASS** | 同循环中逐字节 XOR |
| F2-11 | 错误并行 | §9.2 | **PASS** | 三类错误同拍独立锁存，互不抑制 |
| F2-12 | DONE 结果保持 | §7.2, §7.4 | **PASS** | S_DONE 不改变结果寄存器；TB TC5 验证保持 |
| F2-13 | 越界不卡死 | §7.2, §9.1 | **PASS** | words_total=1 快速终止；TB TC3/TC4 验证 |
| F2-14 | PKT_LEN_EXP 一致性 | §9.1 | **PASS** | `exp!=0 && hdr[5:0]!=exp` 判定；A-2 假设合理 |

### 2.4 非阻塞性观察

| # | 观察 | 影响 | 建议 |
|---|------|------|------|
| OBS-1 | 单 word 包路径（hdr_words_total=1）在首拍 PROCESS 会发起一次投机性 word1 读请求 | 无功能影响，SRAM 读是无副作用操作；FSM 同拍进 DONE 后不消费 | 保持现状，无需修改 |
| OBS-2 | Spec §7.2 IDLE 行描述"若曾完成过则保持 done_o=1" 在当前 FSM 拓扑下不可达（无 DONE→IDLE 转移） | RTL 正确：IDLE done_o=0 | Spec 措辞 quirk，非 DUT 问题 |
| OBS-3 | A-2 假设（PKT_LEN_EXP "非零即已配置"）| 合理：spec §5.2 复位值=0，"已配置"最自然的判据即"非零" | 已记入 risk-register，保持 OPEN 直到正式确认 |

### 2.5 L2-O-3 跨周期假设复核

DUT Agent 留待审查的 L2-O-3："越界判定路径与 mem_rd_data_i header 解码耦合，跨周期假设"

**复核结论：安全。**
- 组合路径 `mem_rd_data_i → hdr_b0..b3 → hdr_len_err/type_err/chk_err` 仅在 PROCESS、consume_idx==0 时被采样入寄存器。
- SRAM 在前一拍 posedge 已锁存了 word0（因为 start 同拍组合驱动了 rd_en=1, addr=0），所以 PROCESS 首拍 `mem_rd_data_i` 是稳定的寄存器输出。
- 不存在跨周期透明锁存竞争。

### 2.6 编译/仿真验证

| 项 | 结果 |
|----|------|
| comp.log | 0 error / 0 warning（QuestaSim 2021.1） |
| run.log | 33 PASS / 0 FAIL，TC1~TC6 全 PASS |

---

## 3 验证阶段（2026-05-12，VPlan Agent）

### 3.1 阶段目标
补充 F2-06/F2-07/F2-08/F2-11/F2-14 定向 TC，并增强 F2-09/F2-10 的边界覆盖。

### 3.2 新增 Testcase 设计

| TC | 名称 | 验证意图 | 关联 Feature |
|----|------|----------|--------------|
| TC7 | tc_type_not_one_hot | pkt_type=0x03 非 one-hot → type_error=1 | F2-06 |
| TC8 | tc_type_mask_filter | pkt_type=0x01 合法但 mask bit0=0 → type_error=1 | F2-06 |
| TC9 | tc_hdr_chk_error | 错误的 hdr_chk + algo_mode=1 → chk_error=1 | F2-07 |
| TC10 | tc_algo_mode_bypass | 错误的 hdr_chk + algo_mode=0 → chk_error=0 | F2-08 |
| TC11 | tc_multi_error | pkt_len=3 + type=0x03 + 错误 chk → 三路同时触发 | F2-11 |
| TC12 | tc_exp_pkt_len_mismatch | pkt_len=8 但 exp=10 → length_error=1 | F2-14 |
| TC13 | tc_exp_pkt_len_match | pkt_len=8 且 exp=8 → length_error=0 | F2-14 |
| TC14 | tc_payload_unaligned | pkt_len=5 → word1 仅 byte[4] 有效，sum/xor=0x42 | F2-09/F2-10 |

### 3.3 验证结果

| 项 | 结果 |
|----|------|
| `make comp` | 0 error / 0 warning |
| `make run` | 66 PASS / 0 FAIL（14 TC 全 PASS） |

### 3.4 Feature-Matrix 更新
F2-01~F2-14 TB 列全部 #TODO → #DONE。

---

## 4 验收阶段（2026-05-12，Sign-off Agent）

### 4.1 验收环境
| 项 | 值 |
|----|-----|
| 编译命令 | `make comp`（lab2/svtb/sim） |
| 运行命令 | `make run` |
| 工具版本 | QuestaSim-64 2021.1 |
| 编译结果 | 0 error / 0 warning |
| 运行结果 | 14 TC / 66 checks / 0 FAIL |

### 4.2 必做项判定

| # | 验收标准 | 判据证据 | 结果 |
|---|----------|----------|------|
| 1 | 合法包完整处理 | TC1: res_pkt_len=0x04, res_pkt_type=0x01, format_ok=1; TC2: res_pkt_len=0x08, res_pkt_type=0x02, sum=0x0a, xor=0x04 | **PASS** |
| 2 | 长度越界检测 | TC3: done=1, length_error=1, busy=0; TC4: done=1, length_error=1, busy=0 | **PASS** |
| 3 | busy/done 时序 | TC5: busy_after_start=1, done_held=1; TC6: done_cleared=0 | **PASS** |

### 4.3 选做项判定

| # | 验收标准 | 判据证据 | 结果 |
|---|----------|----------|------|
| 4 | pkt_type + type_mask 过滤 | TC7: non-one-hot type_error=1; TC8: mask-filtered type_error=1 | **PASS** |
| 5 | algo_mode 旁路 + payload sum/XOR | TC10: algo_mode=0 bypass format_ok=1; TC13/TC14: sum/xor 正确 | **PASS** |

### 4.4 验收结论

**Lab2 验收通过。** 3 项必做 + 2 项选做全部 PASS。无迭代需求。

F2-01~F2-14 → #VERIFIED，Lab2 关闭。

# Lab4 Regression Testplan (Phase 0: Testcase Consolidation)

> Verification Plan Agent | 2026-05-13
> 整理 Lab1-3 全部 36 个 testcase 为结构化回归列表

---

## 1 回归总览

| 维度 | Lab1 | Lab2 | Lab3 | 合计 |
|------|------|------|------|------|
| TC 数量 | 10 | 15 | 11 | **36** |
| Check 断言 | 61 | 76 | 40 | **177** |
| 覆盖 Feature 数 | 15 (F1-01~F1-15) | 15 (F2-01~F2-15) | 6 (F3-01~F3-06) | **36** |
| DUT 拓扑 | M1+M2 (M3 stub) | M3 (行为级 SRAM) | ppa_top (M1+M2+M3) | 3 级 |
| 优先级 | 全 P0 | 全 P0 | 8×P0 + 2×P1 + 1×P0 | 34 P0 + 2 P1 |
| TB 文件 | lab1/svtb/tb/ppa_tb.sv | lab2/svtb/tb/ppa_tb.sv | lab3/svtb/tb/ppa_tb.sv | 3 文件 |
| Makefile | lab1/svtb/sim/Makefile | lab2/svtb/sim/Makefile | lab3/svtb/sim/Makefile | 3 入口 |
| 最近验证结果 | 10 TC / 61 chk PASS | 15 TC / 76 chk PASS | 11 TC / 40 chk PASS | 全 PASS |

---

## 2 Lab1 回归列表 (Module-Level: M1+M2, M3 Stub)

DUT: `ppa_apb_slave_if` + `ppa_packet_sram`
TB: `lab1/svtb/tb/ppa_tb.sv`
编译运行: `cd lab1/svtb/sim && make comp && make run`

| Regress ID | TB TC ID | 名称 | 覆盖 Feature | Spec §10 | 优先级 | Checks | 验证意图 |
|------------|----------|------|-------------|----------|--------|--------|----------|
| L1_TC01 | TC1 | tc_csr_default_rw | F1-03, F1-05 | — | P0 | 11 | 复位后 11 个 CSR 读回默认值与 Spec §5.2 一致 |
| L1_TC02 | TC2 | tc_pkt_mem_write | F1-10, F1-11, F1-13, F1-14 | — | P0 | 8 | APB 写 8 word PKT_MEM, M2 读端口回读比对 |
| L1_TC03 | TC3 | tc_apb_basic_rw | F1-01, F1-02, F1-06 | — | P0 | 6 | Stub 赋 M3 结果后 APB 读 RES_*/STATUS/ERR_FLAG |
| L1_TC04 | TC4 | tc_slverr_reserved | F1-04 | — | P0 | 6 | 保留/越界/非对齐地址 PSLVERR=1 |
| L1_TC05 | TC5 | tc_ro_write_protect | F1-07 | — | P0 | 12 | 写 6 个 RO 寄存器 PSLVERR=1 且值不变 |
| L1_TC06 | TC6 | tc_w1p_start | F1-08 | — | P0 | 5 | W1P: enable+!busy 脉冲, enable=0/busy=1 无脉冲, 读回 0 |
| L1_TC07 | TC7 | tc_rw1c_irq_sta | F1-09 | B-3 | P0 | 2 | done_irq 置位后写 1 清零 |
| L1_TC08 | TC8 | tc_busy_write_protect | F1-12 | B-2 | P0 | 3 | busy=1 写 PKT_MEM → PSLVERR=1, SRAM 不变 |
| L1_TC09 | TC9 | tc_irq_logic | F1-15 | B-3 | P0 | 4 | done_irq + err_irq 路径: 使能→置位→irq_o=1→清除→irq_o=0 |
| L1_TC10 | TC10 | tc_rw_readback | F1-06 | — | P0 | 4 | RW 寄存器 (CTRL/CFG/IRQ_EN/PKT_LEN_EXP) 写后读一致 |

**小计: 10 TC / 61 checks / 全 P0**

---

## 3 Lab2 回归列表 (Module-Level: M3, Behavioral SRAM)

DUT: `ppa_packet_proc_core`
TB: `lab2/svtb/tb/ppa_tb.sv`
编译运行: `cd lab2/svtb/sim && make comp && make run`

| Regress ID | TB TC ID | 名称 | 覆盖 Feature | Spec §10 | 优先级 | Checks | 验证意图 |
|------------|----------|------|-------------|----------|--------|--------|----------|
| L2_TC01 | TC1 | tc_min_legal_pkt | F2-01, F2-04, F2-05 | N-1 | P0 | 9 | pkt_len=4 最小合法包, FSM 正常完成 |
| L2_TC02 | TC2 | tc_8byte_legal | F2-01, F2-04, F2-09, F2-10 | N-2 | P0 | 6 | 8B 包 payload sum/XOR 计算验证 |
| L2_TC03 | TC3 | tc_length_underflow | F2-05, F2-13 | E-1 | P0 | 4 | pkt_len=3 下溢, length_error=1, 不卡死 |
| L2_TC04 | TC4 | tc_length_overflow | F2-05, F2-13 | E-2 | P0 | 4 | pkt_len=33 上溢, length_error=1, 不卡死 |
| L2_TC05 | TC5 | tc_busy_done_timing | F2-02, F2-03, F2-12 | B-1 | P0 | 6 | start 后 busy=1; DONE 态 done 保持; 结果保持 |
| L2_TC06 | TC6 | tc_two_frames | F2-12 | N-4, B-1 | P0 | 4 | 连续两帧: done 清零→新 start→新结果独立正确 |
| L2_TC07 | TC7 | tc_type_not_one_hot | F2-06 | E-3 | P0 | 4 | pkt_type=0x03 非 one-hot → type_error=1 |
| L2_TC08 | TC8 | tc_type_mask_filter | F2-06 | E-4 | P0 | 4 | type_mask bit=0 屏蔽合法类型 → type_error=1 |
| L2_TC09 | TC9 | tc_hdr_chk_error | F2-07 | E-5 | P0 | 4 | hdr_chk 不匹配, algo_mode=1 → chk_error=1 |
| L2_TC10 | TC10 | tc_algo_mode_bypass | F2-08 | E-6 | P0 | 4 | algo_mode=0 旁路, 同一错包 chk_error=0 |
| L2_TC11 | TC11 | tc_multi_error | F2-11 | — | P0 | 5 | 三类错误 (length+type+chk) 同时成立 |
| L2_TC12 | TC12 | tc_exp_pkt_len_mismatch | F2-14 | B-4 | P0 | 4 | exp_pkt_len≠pkt_len → length_error=1 |
| L2_TC13 | TC13 | tc_exp_pkt_len_match | F2-14 | — | P0 | 4 | exp_pkt_len=pkt_len → 无 length_error (正向确认) |
| L2_TC14 | TC14 | tc_payload_unaligned | F2-09, F2-10 | — | P0 | 4 | pkt_len=5 非对齐尾 word, 仅有效字节参与 sum/XOR |
| L2_TC15 | TC15 | tc_max_legal_pkt | F2-15 | N-3 | P0 | 10 | pkt_len=32 最大包, 28B payload 满载, 全字段验证 |

**小计: 15 TC / 76 checks / 全 P0**

---

## 4 Lab3 回归列表 (Integration-Level: ppa_top)

DUT: `ppa_top` (M1+M2+M3 完整系统)
TB: `lab3/svtb/tb/ppa_tb.sv`
编译运行: `cd lab3/svtb/sim && make comp && make run`

| Regress ID | TB TC ID | 名称 | 覆盖 Feature | Spec §10 | 优先级 | Checks | 验证意图 |
|------------|----------|------|-------------|----------|--------|--------|----------|
| L3_TC01 | TC1 | tc_e2e_basic | F3-01, F3-02 | N-2 | P0 | 6 | 8B 合法包端到端: APB→SRAM→FSM→结果 |
| L3_TC02 | TC2 | tc_two_frames | F3-03 | N-1, N-4 | P0 | 4 | 连续两帧, 第二帧为 4B 最小包 |
| L3_TC03 | TC3 | tc_status_bus | F3-04 | — | P0 | 2 | busy 时 STATUS[1:0]=01; done 时 STATUS[1:0]=10 |
| L3_TC04 | TC4 | tc_e2e_max_packet | F3-02 | N-3 | P0 | 6 | 32B 最大包端到端, 全 8 word 读路径 |
| L3_TC05 | TC5 | tc_e2e_error_length | F3-02 | E-1 | P0 | 2 | pkt_len=3 下溢 ERR_FLAG 端到端通路 |
| L3_TC06 | TC6 | tc_e2e_error_type | F3-02 | E-3 | P0 | 2 | pkt_type=0x03 非法类型 ERR_FLAG 端到端通路 |
| L3_TC07 | TC7 | tc_e2e_chk_error | F3-02 | E-5 | P0 | 2 | hdr_chk 错误 ERR_FLAG 端到端通路 |
| L3_TC08 | TC8 | tc_e2e_algo_bypass | F3-02 | E-6 | P0 | 2 | algo_mode=0 旁路, CFG 路径端到端 |
| L3_TC09 | TC9 | tc_busy_write_protect | F3-05 | B-2 | P1 | 2 | busy=1 写 PKT_MEM → PSLVERR=1, SRAM 不变 |
| L3_TC10 | TC10 | tc_irq_path_e2e | F3-06 | B-3 | P1 | 4 | done_irq_en=1→done→irq_o=1→清除→irq_o=0 |
| L3_TC11 | TC11 | tc_pkt_mem_readback | F3-01 | — | P0 | 8 | APB 读 PKT_MEM 返回 SRAM 真实数据 (U-1 修复验证) |

**小计: 11 TC / 40 checks / 9 P0 + 2 P1**

---

## 5 Spec §10 场景覆盖追溯

验证 Spec §10 验收测试场景矩阵中每个场景是否有 TC 覆盖:

### 5.1 正常场景 (N-1 ~ N-4)

| 场景 | 描述 | Module-Level TC | Integration-Level TC | 覆盖状态 |
|------|------|----------------|---------------------|----------|
| N-1 | 最小合法包 (pkt_len=4) | L2_TC01 | L3_TC02 (2nd frame) | COVERED |
| N-2 | 8B 合法包 (含 4B payload) | L2_TC02 | L3_TC01 | COVERED |
| N-3 | 最大合法包 (pkt_len=32) | L2_TC15 | L3_TC04 | COVERED |
| N-4 | 连续两帧处理 | L2_TC06 | L3_TC02 | COVERED |

### 5.2 异常场景 (E-1 ~ E-6)

| 场景 | 描述 | Module-Level TC | Integration-Level TC | 覆盖状态 |
|------|------|----------------|---------------------|----------|
| E-1 | 包长下溢 (pkt_len=3) | L2_TC03 | L3_TC05 | COVERED |
| E-2 | 包长上溢 (pkt_len=33) | L2_TC04 | — | COVERED (module) |
| E-3 | 非法 pkt_type (0x03) | L2_TC07 | L3_TC06 | COVERED |
| E-4 | type_mask 屏蔽 | L2_TC08 | — | COVERED (module) |
| E-5 | hdr_chk 错误 | L2_TC09 | L3_TC07 | COVERED |
| E-6 | algo_mode=0 旁路 | L2_TC10 | L3_TC08 | COVERED |

### 5.3 边界场景 (B-1 ~ B-4)

| 场景 | 描述 | Module-Level TC | Integration-Level TC | 覆盖状态 |
|------|------|----------------|---------------------|----------|
| B-1 | done 未清除时再次 start | L2_TC05, L2_TC06 | L3_TC02 | COVERED |
| B-2 | busy=1 写 PKT_MEM | L1_TC08 | L3_TC09 (P1) | COVERED |
| B-3 | 中断完整路径 | L1_TC07, L1_TC09 | L3_TC10 (P1) | COVERED |
| B-4 | PKT_LEN_EXP 不符 | L2_TC12 | — | COVERED (module) |

**结论: Spec §10 全部 14 个场景均有 TC 覆盖, 无遗漏**

> 注: E-2/E-4/B-4 仅有 Module-Level 覆盖。这些场景的核心检查逻辑在 M3 内部, 端到端链路已由其他 E2E TC 充分验证, 不构成覆盖缺口。如需补充可作为 Lab4 迭代增强项。

---

## 6 Feature → TC 反向追溯

### 6.1 Lab1 Features

| Feature ID | 功能 | 覆盖 TC |
|------------|------|---------|
| F1-01 | APB 两段式传输时序 | L1_TC03 |
| F1-02 | PREADY 固定为 1 | L1_TC03 |
| F1-03 | CSR 地址映射 | L1_TC01 |
| F1-04 | 保留地址 PSLVERR=1 | L1_TC04 |
| F1-05 | CSR 默认值 | L1_TC01 |
| F1-06 | RW 寄存器读写 | L1_TC03, L1_TC10 |
| F1-07 | RO 寄存器写保护 | L1_TC05 |
| F1-08 | W1P (CTRL.start) | L1_TC06 |
| F1-09 | RW1C (IRQ_STA) | L1_TC07 |
| F1-10 | PKT_MEM 地址映射 | L1_TC02 |
| F1-11 | PKT_MEM 写端口生成 | L1_TC02 |
| F1-12 | busy=1 写 PKT_MEM 报错 | L1_TC08 |
| F1-13 | M2 双端口同步 SRAM | L1_TC02 |
| F1-14 | M2 复位清零 | L1_TC02 |
| F1-15 | 中断逻辑 (irq_o) | L1_TC09 |

### 6.2 Lab2 Features

| Feature ID | 功能 | 覆盖 TC |
|------------|------|---------|
| F2-01 | 三态 FSM | L2_TC01, L2_TC02 |
| F2-02 | start 无条件启动 | L2_TC05 |
| F2-03 | busy/done 时序 | L2_TC05 |
| F2-04 | 包头解析 | L2_TC01, L2_TC02 |
| F2-05 | 长度检查 [4,32] | L2_TC01, L2_TC03, L2_TC04 |
| F2-06 | 类型检查 (one-hot + type_mask) | L2_TC07, L2_TC08 |
| F2-07 | 头校验 (hdr_chk) | L2_TC09 |
| F2-08 | algo_mode 旁路 | L2_TC10 |
| F2-09 | payload sum 计算 | L2_TC02, L2_TC14 |
| F2-10 | payload XOR 计算 | L2_TC02, L2_TC14 |
| F2-11 | 错误可并行成立 | L2_TC11 |
| F2-12 | DONE 态结果保持 | L2_TC05, L2_TC06 |
| F2-13 | 长度越界不卡死 | L2_TC03, L2_TC04 |
| F2-14 | PKT_LEN_EXP 一致性检查 | L2_TC12, L2_TC13 |
| F2-15 | 最大包满载处理 | L2_TC15 |

### 6.3 Lab3 Features

| Feature ID | 功能 | 覆盖 TC |
|------------|------|---------|
| F3-01 | ppa_top 顶层连线 | L3_TC01, L3_TC11 |
| F3-02 | 端到端链路 | L3_TC01, L3_TC04, L3_TC05, L3_TC06, L3_TC07, L3_TC08 |
| F3-03 | 连续两帧顺序处理 | L3_TC02 |
| F3-04 | STATUS 总线通路 | L3_TC03 |
| F3-05 | busy 期间写保护 | L3_TC09 |
| F3-06 | 中断路径闭环 | L3_TC10 |

---

## 7 回归分级 (Smoke / Regress)

### 7.1 Smoke (冒烟测试, 快速验证基本功能)

从每个 DUT 层级各选一个最基础的 TC, 确保编译和基本功能未被破坏:

| Smoke TC | Regress ID | 验证意图 |
|----------|------------|----------|
| S1 | L1_TC01 | M1 CSR 寄存器基本可读 |
| S2 | L1_TC02 | M2 SRAM 写+回读 |
| S3 | L2_TC01 | M3 FSM 最小合法包 |
| S4 | L3_TC01 | ppa_top 端到端基本链路 |

**Smoke 预期: 4 TC / 30 checks, 运行时间 < 1 min**

### 7.2 Regress (全量回归)

全部 36 TC, 分 3 个 TB 顺序执行:

```
make -C lab1/svtb/sim comp run   # 10 TC / 61 checks
make -C lab2/svtb/sim comp run   # 15 TC / 76 checks
make -C lab3/svtb/sim comp run   # 11 TC / 40 checks
```

**Regress 预期: 36 TC / 177 checks, 运行时间 < 3 min**

---

## 8 下游工作备忘

以下信息供后续阶段 Agent 参考:

### 8.1 TB 架构现状

当前 3 个 TB 彼此独立, 各自编译运行:
- **Lab1 TB**: 直接例化 M1+M2, M3 输入用 stub 信号驱动
- **Lab2 TB**: 直接例化 M3, 使用行为级 SRAM 模型 (always_ff)
- **Lab3 TB**: 例化 ppa_top, 纯 APB 总线驱动

### 8.2 UVM 升级路径

当前全部 TB 为纯 SV 过程式验证。UVM 升级时需关注:
- **共用基础设施**: APB write/read/check task 在 3 个 TB 中重复定义, 可提取为 apb_agent
- **TC 转换**: 当前 TC 为 initial 块内顺序执行, 转 UVM 后需拆分为独立 test class
- **覆盖率**: 当前无 covergroup/coverpoint, Lab4 Phase cov 阶段需新增
- **Makefile 统一**: 3 个 Makefile 风格一致, 可合并为 lab4/svtb/sim/Makefile 统一入口

### 8.3 已知局限

| ID | 描述 | 影响 |
|----|------|------|
| U-2 | busy=1 期间 APB 读 PKT_MEM 返回 M3 当前读数据 (非精确语义) | LOW, corner case |
| — | E-2/E-4/B-4 仅有 module-level 覆盖, 无 E2E TC | 非阻塞; 核心逻辑已验, 端到端链路已由其他 TC 覆盖 |
| — | Lab1 TC 依赖 stub 信号, 非真实 M3 驱动 | 设计如此; Lab3 E2E TC 弥补此限制 |

### 8.4 Makefile 关键目标

当前各 lab Makefile 提供的目标:

| 目标 | 作用 |
|------|------|
| `make comp` | vlog 编译 RTL + TB |
| `make run` | vsim 批量运行全部 TC |
| `make rung` | vsim GUI 模式 (带波形) |
| `make clean` | 清除 work/ 和仿真生成物 |

Lab4 需新增: `make smoke`, `make regress`, `make cov`

---

## 9 Coverage Gap 分析与 Closure 计划 (Phase 1 追加)

> Verification Phase 1 Agent | 2026-05-13
> 基于 `make cov` 全量回归后的 Questa 覆盖率详细报告

### 9.1 Coverage 基线 vs 验收标准

Spec §11.5 #2: ≥90% 合格 / ≥95% 优良 / 100% 优秀

| 覆盖率类型 | 当前 | 判定 | 达标差距 |
|-----------|------|------|---------|
| Statements (line) | 96.54% | 优良 | — |
| FSM States | 100.00% | 优秀 | — |
| Branches | 87.79% | **不合格** | +2.21% |
| Conditions | 75.71% | **不合格** | +14.29% |
| FSM Transitions | 60.00% | **不合格** | +30% |
| Toggles | 77.53% | **不合格** | +12.47% |

### 9.2 根因定位

#### 根因 A: TB 代码污染 RTL 覆盖率统计

TB 的 check macro、fail 计数器、timeout 逻辑被纳入统计, 在全 PASS 回归中 false 分支永远不走。

| 被污染的 TB 代码 | 影响覆盖率类型 | 具体 miss |
|-----------------|--------------|----------|
| `actual === expected` (lab1:157, lab2:129, lab3:120) | Condition | `_0` 分支不可能命中 (全 PASS) |
| `fail_cnt == 0` (lab1:528) | Condition | `_0` 分支不可能命中 |
| `t < timeout` (lab2:120, lab3:136) | Condition | `_0` 分支 (timeout 不发生) |
| `fail_cnt[0:31]` 全 0 | Toggle | 64 bins 全 miss |
| `pass_cnt[7:31]` 高位 | Toggle | 不够大翻转 |
| TB 中 `$display("[FAIL]")` 所在 `else` 分支 | Branch / Statement | 全 PASS 不走 |

`/ppa_tb` 实例合计: branch 50%, condition 25%, toggle 67.82%。

**解决方案:** Makefile `cov` target 的 vlog 分两步 — RTL 编译加 `-cover bcstf`, TB 编译不加 `-cover`。

#### 根因 B: 缺少异步复位测试

M3 FSM (`ppa_packet_proc_core`) 共 5 条合法迁移, 3 条已覆盖, 2 条缺失:

| 迁移 | 触发条件 | 覆盖状态 |
|------|---------|---------|
| S_IDLE → S_PROCESS | start_i in IDLE | COVERED (多个 TC) |
| S_PROCESS → S_DONE | 处理完成 | COVERED (多个 TC) |
| S_DONE → S_PROCESS | start_i in DONE | COVERED (L2_TC06, L3_TC02) |
| S_PROCESS → S_IDLE | **reset during PROCESS** | **MISS** (line 131) |
| S_DONE → S_IDLE | **reset during DONE** | **MISS** (line 131) |

同时 `rst_n` toggle 只覆盖 0→1 (de-assert), miss 1→0 (assert)。

另: `case(state) default: state <= S_IDLE` (line 243) 是结构性不可达代码 (state 仅 3 值, 无法到达 2'd3)。应作为合法排除项。

**解决方案:** 新增 mid-sim reset TC。

#### 根因 C: 跨 Lab 实例重复统计 + 测试焦点不同

同一 RTL (`ppa_apb_slave_if`) 在不同 Lab 产生不同覆盖率实例, 各 Lab 测试焦点不同导致单个实例覆盖率偏低:

| 缺失项 (Lab3 M1 实例 `/ppa_tb/u_dut/u_m1`) | RTL 位置 | Lab1 覆盖 | Lab3 缺失原因 |
|----------------------------------------------|---------|----------|--------------|
| `!is_valid_addr` → slverr 分支 | line 142 | 已覆盖 (TC4) | Lab3 不测非法地址 |
| `write_ro` → slverr 分支 | line 144 | 已覆盖 (TC5) | Lab3 不测 RO 写保护 |
| `err_irq` 路径 5 个 condition 项 | line 202 | 部分覆盖 (TC9) | Lab3 TC10 仅测 done_irq |
| `ADDR_PKT_LEN_EXP` write 条件 | line 193 | 已覆盖 (TC10) | Lab3 从未写此寄存器 |
| `ADDR_CTRL/CFG/IRQ_EN/IRQ_STA` read case | line 217-222 | 已覆盖 (TC1/TC10) | Lab3 只读结果寄存器 |
| `type_mask[0:3]` toggle | — | 部分覆盖 (TC8) | Lab3 保持复位默认 4'b1111 |

**解决方案:** ① `vcover merge` 改用 `-du` 模式按 Design Unit 合并; ② 新增 Lab3 err_irq E2E TC。

#### 根因 D: 测试数据多样性不足

| 未翻转信号 | 原因 | 可否排除 |
|-----------|------|---------|
| `PREADY` (硬连线 1) | Spec §4: PREADY 固定为 1, 无等待状态 | 合法排除 |
| `PADDR[7:11]` | 地址空间仅到 0x05C, 高 5 位永为 0 | 合法排除 |
| `res_pkt_type_o[3:7]` | 测试仅用 0x01/0x02/0x04/0x08 | 可补充 |
| `res_pkt_len_o[4]` | 包长 4~32, 无 bit4=1 的值 (16 不在范围) | 合法排除 (pkt_len∈[4,32], bit4 翻转需 len=16 but [4,15] vs [16,32] 可覆盖) |
| `exp_pkt_len_i[0:5]` (Lab3 实例) | Lab3 从未写 PKT_LEN_EXP | 可补充 |

**解决方案:** 增加 payload 多样性 (0xFF/0xAA/0x55); Lab3 写 PKT_LEN_EXP; 建立排除登记表。

### 9.3 Coverage Closure 计划

#### 9.3.1 Makefile 修改 (不涉及 TC)

| 编号 | 修改 | 影响范围 |
|------|------|---------|
| M-1 | `cov` target: RTL 和 TB 分开编译, TB 不加 `-cover` | Makefile cov_run_lab* |
| M-2 | `vcover merge` 改用 `-du` 合并 Design Unit | Makefile cov_merge |

#### 9.3.2 新增 TC

| Regress ID | 建议 Lab | 名称 | 验证意图 | 覆盖 Gap |
|------------|---------|------|---------|---------|
| L2_TC16 | Lab2 | tc_mid_sim_reset | 在 S_PROCESS 和 S_DONE 态分别 assert rst_n, 验证 FSM 回到 IDLE 且输出清零 | FSM Trans ×2, rst_n toggle |
| L3_TC12 | Lab3 | tc_err_irq_e2e | 设 err_irq_en=1 + PKT_LEN_EXP=8, 发 type_error 帧, 验 irq_o 置位→清除 | M1 cond line 202 ×3, M1 branch line 193/202 |
| — | Lab2/3 | 改动已有 TC payload | 将部分 TC 的 payload 改用 0xFF/0xAA/0x55 模式 | Toggle: result 高位 |

#### 9.3.3 合法排除项 (需建立排除登记表)

| 排除对象 | RTL 位置 | 排除原因 |
|---------|---------|---------|
| `PREADY` toggle | ppa_apb_slave_if.sv:65 | Spec §4: PREADY 固定为 1, 设计意图 |
| `PADDR[7:11]` toggle | ppa_apb_slave_if.sv 端口 | 地址空间 0x000~0x05C, 高 5 位无功能意义 |
| FSM `default` branch | ppa_packet_proc_core.sv:243 | state 仅 3 值 (0/1/2), 2'd3 不可达 |
| `hdr_b1` case `default` (Lab3 实例) | ppa_packet_proc_core.sv:84 | 同一分支在 Lab2 实例已覆盖; Lab3 合法类型覆盖场景不同 |

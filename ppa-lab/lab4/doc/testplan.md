# Lab4 Regression Testplan

> Verification Plan Agent | 2026-05-13, Updated: Coverage Closure Agent | 2026-05-13
> 整理 Lab1-3 全部 42 个 testcase 为结构化回归列表 + 覆盖率 closure 结果

---

## 1 回归总览

| 维度 | Lab1 | Lab2 | Lab3 | 合计 |
|------|------|------|------|------|
| TC 数量 | 11 | 17 | 14 | **42** |
| Check 断言 | 74 | 94 | 56 | **224** |
| 覆盖 Feature 数 | 15 (F1-01~F1-15) | 15 (F2-01~F2-15) | 6 (F3-01~F3-06) | **36** |
| DUT 拓扑 | M1+M2 (M3 stub) | M3 (行为级 SRAM) | ppa_top (M1+M2+M3) | 3 级 |
| 优先级 | 全 P0 | 全 P0 | 10×P0 + 2×P1 + 2×COV | 36 P0 + 2 P1 + 4 COV |
| TB 文件 | lab1/svtb/tb/ppa_tb.sv | lab2/svtb/tb/ppa_tb.sv | lab3/svtb/tb/ppa_tb.sv | 3 文件 |
| Makefile | lab1/svtb/sim/Makefile | lab2/svtb/sim/Makefile | lab3/svtb/sim/Makefile | 3 入口 |
| 统一入口 | — | — | — | lab4/svtb/sim/Makefile |
| 最近验证结果 | 11 TC / 74 chk PASS | 17 TC / 94 chk PASS | 14 TC / 56 chk PASS | **全 PASS** |

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
| L1_TC11 | TC11 | tc_toggle_exercise | F1-01~F1-15 | — | COV | 13 | M3 stub 全位翻转 + exp_pkt_len/type_mask 全位循环 + PADDR OOB + PWDATA/PRDATA 多样性 |

**小计: 11 TC / 74 checks / 10 P0 + 1 COV**

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
| L2_TC16 | TC16 | tc_reset_in_process | F2-01 | — | COV | 10 | S_PROCESS 态 assert rst_n, 验证 FSM 回 IDLE 且输出清零 |
| L2_TC17 | TC17 | tc_reset_in_done | F2-01, F2-12 | — | COV | 6 | S_DONE 态 assert rst_n, 验证 FSM 回 IDLE, 恢复后正常处理 |

**小计: 17 TC / 94 checks / 15 P0 + 2 COV**

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
| L3_TC12 | TC12 | tc_err_irq_e2e | F3-06 | B-3 | P0 | 6 | err_irq_en=1 + PKT_LEN_EXP=8, 发 type_error 帧, irq_o 闭环 |
| L3_TC13 | TC13 | tc_mid_sim_reset | F3-01, F3-04 | — | P0 | 5 | 集成级 mid-sim reset (PROCESS→IDLE + DONE→IDLE + 恢复验证) |
| L3_TC14 | TC14 | tc_toggle_exercise | F3-01~F3-06 | — | COV | 5 | exp_pkt_len/type_mask 全位翻转, pkt_len=20/type=0xF0, PADDR OOB, is_valid_addr/write_ro |

**小计: 14 TC / 56 checks / 10 P0 + 2 P1 + 2 COV**

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

全部 42 TC, 分 3 个 TB 顺序执行:

```
make -C lab1/svtb/sim comp run   # 11 TC / 74 checks
make -C lab2/svtb/sim comp run   # 17 TC / 94 checks
make -C lab3/svtb/sim comp run   # 14 TC / 56 checks
```

**Regress 预期: 42 TC / 224 checks, 运行时间 < 3 min**

统一入口: `cd lab4/svtb/sim && make regress`

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

Lab4 统一入口: `make smoke`, `make regress`, `make cov` (已实现)

---

## 9 Coverage Closure 结果 (Phase 2)

> Coverage Closure Agent | 2026-05-13
> 基于 Phase 1 覆盖率基线分析, 执行 closure 后的最终结果

### 9.1 Coverage 最终达成 vs 验收标准

Spec §11.5 #2: ≥90% 合格 / ≥95% 优良 / 100% 优秀

| 覆盖率类型 | Phase 1 基线 | Phase 2 最终 | 判定 |
|-----------|-------------|-------------|------|
| Statements | 96.54% | **98.40%** | 优良 ✓ |
| Branches | 87.79% | **96.25%** | 优良 ✓ |
| Conditions | 75.71% | **91.93%** | 合格 ✓ |
| FSM States | 100% | **100%** | 优秀 ✓ |
| FSM Transitions | 60% | **100%** | 优秀 ✓ |
| Toggles | 77.53% | **98.28%** | 优良 ✓ |
| **Total** | **82.93%** | **97.47%** | **优良 ✓** |

**结论: 五类覆盖率全部 ≥90%, 四类达 ≥95% 优良, 满足 Spec §11.5 #2 验收标准。**

### 9.2 Closure 手段汇总

| 编号 | 手段 | 效果 |
|------|------|------|
| C-1 | Makefile RTL/TB 分开编译 (TB 不加 `-cover`) | Cond +16%, Branch +8%, Toggle +11% |
| C-2 | Lab2 TC16/TC17: mid-sim reset | FSM Transitions 60→100% |
| C-3 | Lab3 TC13: 集成级 mid-sim reset | Lab3 M3 实例 FSM 补齐 |
| C-4 | Lab3 TC12: err_irq E2E + PKT_LEN_EXP 写 | Cond +4%, Branch +2% |
| C-5 | Lab2/Lab3 payload 改 0xFF/0xAA/0x55 | Toggle +3% |
| C-6 | Lab1 TC11: M3 stub 全位翻转 + CSR 翻转 + PADDR OOB | Toggle (Lab1 实例) |
| C-7 | Lab3 TC14: toggle exercise (pkt_len=20, type=0xF0, exp_pkt_len 循环, PADDR OOB) | Toggle 88.85→98.28% |

### 9.3 合法排除项登记

详见 `lab4/doc/coverage_exclusion.md`。以下三项为结构性不可达或设计意图导致, 不需要 TC 覆盖:

| ID | 模块 | 信号/代码 | 类型 | 排除原因 | Spec 依据 |
|----|------|----------|------|---------|-----------|
| EX-01 | ppa_apb_slave_if | `PREADY` | Toggle | 硬连线 1, 永不翻转 | Spec §4 |
| EX-02 | ppa_apb_slave_if | `PADDR[11:7]` | Toggle | 地址空间仅到 0x05C, 高 5 位永为 0 | Spec §2.3 |
| EX-03 | ppa_packet_proc_core | FSM `default` branch (line 243) | Branch/Stmt | 2-bit state 仅 3 合法值, state=3 不可达 | Spec §7.1 |

> **注:** 因覆盖率已达标 (97.47%), 以上排除项未实际应用于 Questa 统计。如后续需将 Condition 从 91.93% 推至 95%, 可启用 `cov_exclude.do` 文件 (示例见 `coverage_exclusion.md`)。

### 9.4 根因分析 (Phase 1 记录, 保留供参考)

#### 根因 A: TB 代码污染 RTL 覆盖率统计

TB 的 check macro、fail 计数器、timeout 逻辑被纳入统计, 在全 PASS 回归中 false 分支永远不走。**已修复:** Makefile RTL/TB 分开编译。

#### 根因 B: 缺少异步复位测试

FSM 2 条 reset 迁移 (S_PROCESS→S_IDLE, S_DONE→S_IDLE) 未覆盖。**已修复:** Lab2 TC16/TC17 + Lab3 TC13 mid-sim reset TC。

#### 根因 C: 跨 Lab 实例覆盖率不均

`ppa_apb_slave_if` 在 Lab3 集成实例中缺少 CSR error path 和 err_irq 路径。**已修复:** Lab3 TC12 (err_irq) + TC14 (toggle exercise 覆盖 is_valid_addr/write_ro/type_mask)。`vcover merge -du` 在 Questa 2021.1 不可用, 通过逐实例补充 TC 替代。

#### 根因 D: 测试数据多样性不足

高位 toggle miss (res_pkt_type[4:7], exp_pkt_len, pkt_len bit4 等)。**已修复:** Lab3 TC14 发 pkt_len=20/type=0xF0 包, Lab1 TC11 循环 exp_pkt_len/type_mask, Lab2/3 payload 改 0xFF/0xAA/0x55。

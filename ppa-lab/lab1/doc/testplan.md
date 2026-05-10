# Lab1 测试计划 (Test Plan)

> 由 Verification Plan Agent 编写（2026-05-11）
> 覆盖 feature-matrix F1-01 ~ F1-15 全部 15 个功能点

## 测试策略

Lab1 验证基于 DUT Agent 提供的最小 TB（ppa_tb.sv）进行补充。TB 直接例化 M1（ppa_apb_slave_if）和 M2（ppa_packet_sram），M3 输入使用 stub 信号驱动。所有用例在同一仿真中顺序执行，`make run` 一次运行全量。

---

## 已有用例（DUT Agent 提供）

| TC ID | 名称 | 覆盖功能 | 检查点 | 输入摘要 | 期望输出 | 优先级 | 结果 |
|-------|------|----------|--------|----------|----------|--------|------|
| TC1 | tc_csr_default_rw | F1-03, F1-05 | 复位后读回 11 个 CSR 寄存器，值与 Spec §5.2 一致 | 复位后直接读 | CTRL=0, CFG=0xF1, STATUS=0, IRQ_EN=0, IRQ_STA=0, PKT_LEN_EXP=0, RES_*=0, ERR_FLAG=0 | P0 | PASS |
| TC2 | tc_pkt_mem_write | F1-10, F1-11, F1-13, F1-14 | APB 写 8 个 word 到 PKT_MEM，通过 M2 读端口回读比对 | 写 0x040~0x05C 共 8 word 已知数据 | SRAM Word[0..7] 与写入值一致 | P0 | PASS |
| TC3 | tc_apb_basic_rw | F1-01, F1-02, F1-06 | stub 赋值 M3 结果后 APB 读回 RES_*/STATUS/ERR_FLAG | stub: pkt_len=8, type=0x02, sum=0xAB, xor=0xCD, format_ok=1, done=1 | RES_PKT_LEN=8, TYPE=2, SUM=0xAB, XOR=0xCD, STATUS=0xA, ERR_FLAG=0 | P0 | PASS |

---

## 新增用例（VPlan Agent 补充）

| TC ID | 名称 | 覆盖功能 | 检查点 | 输入摘要 | 期望输出 | 优先级 | 结果 |
|-------|------|----------|--------|----------|----------|--------|------|
| TC4 | tc_slverr_reserved | F1-04 | 访问保留/越界/非对齐地址时 PSLVERR=1 | 写+读 0x02C, 0x030, 0x060, 0x100; 写 0x003（非对齐） | 每次访问 PSLVERR=1 | P0 | PASS |
| TC5 | tc_ro_write_protect | F1-07 | 写 6 个 RO 寄存器时 PSLVERR=1 且值不变 | 写 STATUS/RES_PKT_LEN/RES_PKT_TYPE/RES_PAYLOAD_SUM/RES_PAYLOAD_XOR/ERR_FLAG（值=0xFFFFFFFF） | PSLVERR=1; 读回值与写前一致（stub 决定） | P0 | PASS |
| TC6 | tc_w1p_start | F1-08 | W1P 行为：合法条件产生脉冲、非法条件不产生、读回恒 0 | (a) enable=1,busy=0 写 start=1; (b) enable=0 写 start=1; (c) busy=1 写 start=1; (d) 读 CTRL | (a) start_o 脉冲 1 拍; (b)(c) start_o=0; (d) bit[1]=0 | P0 | PASS |
| TC7 | tc_rw1c_irq_sta | F1-09 | RW1C 行为：done_irq 置位后写 1 清零 | 使能 done_irq_en→done 上升沿→读 IRQ_STA→写 1 清除→再读 | 置位后 IRQ_STA[0]=1; 清除后 IRQ_STA[0]=0 | P0 | PASS |
| TC8 | tc_busy_write_protect | F1-12 | busy=1 时写 PKT_MEM 返回 PSLVERR=1，SRAM 不变 | busy=1 时写 PKT_MEM[0]=0xDEADBEEF | PSLVERR=1; SRAM Word[0] 保持原值 | P0 | PASS |
| TC9 | tc_irq_logic | F1-15 | 中断路径完整：使能→置位→irq_o=1→清除→irq_o=0 | done_irq 路径 + err_irq 路径 | irq_o 随 IRQ_STA 位变化即时响应 | P0 | PASS |
| TC10 | tc_rw_readback | F1-06（补充） | RW 寄存器写后读一致性 | 写非默认值到 CTRL/CFG/IRQ_EN/PKT_LEN_EXP | 读回值与写入值一致（按位域掩码） | P0 | PASS |

---

## Feature-Matrix 覆盖映射

| Feature ID | 功能 | 覆盖 TC |
|------------|------|---------|
| F1-01 | APB 两段式传输时序 | TC3 |
| F1-02 | PREADY 固定为 1 | TC3 |
| F1-03 | CSR 地址映射 | TC1 |
| F1-04 | 保留地址返回 PSLVERR=1 | **TC4** |
| F1-05 | CSR 默认值正确 | TC1 |
| F1-06 | RW 寄存器读写 | TC3, **TC10** |
| F1-07 | RO 寄存器写保护 | **TC5** |
| F1-08 | W1P 行为（CTRL.start） | **TC6** |
| F1-09 | RW1C 行为（IRQ_STA） | **TC7** |
| F1-10 | PKT_MEM 地址映射 | TC2 |
| F1-11 | PKT_MEM 写端口生成 | TC2 |
| F1-12 | busy=1 写 PKT_MEM 报错 | **TC8** |
| F1-13 | M2 双端口同步 SRAM | TC2 |
| F1-14 | M2 复位清零 | TC2 |
| F1-15 | 中断逻辑（irq_o） | **TC9** |

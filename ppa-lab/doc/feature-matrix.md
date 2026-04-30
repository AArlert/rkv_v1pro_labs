# PPA-Lite 功能清单 (Feature Matrix)

> 每个原子功能一行，Agent 完成后必须更新状态

## 状态说明

- `TODO` — 未开始
- `WIP` — 进行中
- `DONE` — 已实现
- `VERIFIED` — 已验证通过
- `BLOCKED` — 被阻塞

---

## Lab1：APB 从接口 + SRAM

| ID | 功能描述 | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注 |
|----|----------|--------|----------|---------|---------------|------|
| F1-01 | APB 两段式传输时序 | §3.1 | DONE | DONE | tc_apb_basic_rw | |
| F1-02 | PREADY 固定为 1 | §3.1 | DONE | DONE | tc_apb_basic_rw | |
| F1-03 | CSR 地址映射（0x000~0x02B） | §3.2 | DONE | DONE | tc_csr_default_rw | |
| F1-04 | 保留地址返回 PSLVERR=1 | §3.2 | DONE | DONE | tc_apb_basic_rw | |
| F1-05 | CSR 默认值正确 | §3.3 | DONE | DONE | tc_csr_default_rw | |
| F1-06 | RW 寄存器读写 | §3.3 | DONE | DONE | tc_csr_default_rw | |
| F1-07 | RO 寄存器写保护（PSLVERR=1） | §3.3 | DONE | DONE | tc_csr_default_rw | |
| F1-08 | W1P 行为（CTRL.start） | §3.3 | DONE | DONE | tc_csr_default_rw | |
| F1-09 | RW1C 行为（IRQ_STA） | §3.3 | DONE | DONE | tc_csr_default_rw | |
| F1-10 | PKT_MEM 地址映射（0x040~0x05C） | §3.4 | DONE | DONE | tc_pkt_mem_write | |
| F1-11 | PKT_MEM 写端口生成 | §3.4 | DONE | DONE | tc_pkt_mem_write | |
| F1-12 | busy=1 时写 PKT_MEM 报错 | §3.4 | DONE | TODO | — | 待 Lab3 端到端验证 |
| F1-13 | M2 双端口同步 SRAM | §4.1 | DONE | DONE | tc_pkt_mem_write | |
| F1-14 | M2 复位清零 | §4.1 | DONE | DONE | — | 隐含在仿真初始化 |
| F1-15 | 中断逻辑（irq_o） | §3.5 | DONE | DONE | tc_csr_default_rw | |

## Lab2：包处理核心

| ID | 功能描述 | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注 |
|----|----------|--------|----------|---------|---------------|------|
| F2-01 | 三态 FSM（IDLE→PROCESS→DONE） | §5.1 | DONE | DONE | TC1, TC3 | |
| F2-02 | start 仅在 enable=1 且 busy=0 接受 | §5.1 | DONE | DONE | TC3 | |
| F2-03 | busy/done 时序正确 | §5.2 | DONE | DONE | TC3 | |
| F2-04 | 包头解析（pkt_len/type/flags/hdr_chk） | §5.3 | DONE | DONE | TC1 | |
| F2-05 | 长度检查（pkt_len ∈ [4,32]） | §5.4 | DONE | DONE | TC2a, TC2b | |
| F2-06 | 类型检查（one-hot + type_mask） | §5.4 | DONE | DONE | TC4a, TC4b | |
| F2-07 | 头校验（hdr_chk == B0^B1^B2） | §5.4 | DONE | DONE | TC5a | |
| F2-08 | algo_mode 旁路 | §5.4 | DONE | DONE | TC5b | |
| F2-09 | payload sum 计算 | §5.5 | DONE | DONE | TC5c | |
| F2-10 | payload XOR 计算 | §5.5 | DONE | DONE | TC5c | |
| F2-11 | 错误可并行成立 | §5.4 | DONE | DONE | 审查确认 | |
| F2-12 | DONE 态结果保持至下次 start | §5.2 | DONE | DONE | TC3 | |
| F2-13 | 长度越界时 M3 不卡死 | §5.4 | DONE | DONE | TC2a, TC2b | |

## Lab3：顶层集成

| ID | 功能描述 | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注 |
|----|----------|--------|----------|---------|---------------|------|
| F3-01 | ppa_top 顶层连线 | §2.1 | TODO | TODO | — | |
| F3-02 | 端到端链路（APB→CSR→SRAM→FSM→结果） | §2.1 | TODO | TODO | — | |
| F3-03 | 连续两帧顺序处理 | §5.2 | TODO | TODO | — | |
| F3-04 | STATUS 总线通路 | §3.3 | TODO | TODO | — | |
| F3-05 | busy 期间写保护（选做） | §3.4 | TODO | TODO | — | |
| F3-06 | 中断路径闭环（选做） | §3.5 | TODO | TODO | — | |

## Lab4：回归测试与覆盖率

| ID | 功能描述 | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注 |
|----|----------|--------|----------|---------|---------------|------|
| F4-01 | make smoke 一键冒烟 | — | TODO | TODO | — | |
| F4-02 | make regress 全量回归 | — | TODO | TODO | — | |
| F4-03 | make cov 覆盖率收集 | — | TODO | TODO | — | |
| F4-04 | testplan 文档完整 | — | TODO | TODO | — | |
| F4-05 | 五类覆盖率达标 | — | TODO | TODO | — | |
| F4-06 | result_summary 汇总 | — | TODO | TODO | — | |

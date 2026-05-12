# PPA-Lite 功能清单 (Feature Matrix)

> 每个原子功能一行，Agent 完成后必须更新状态

## 状态说明

- #TODO — 未开始
- #WIP — 进行中
- #DONE — 已实现
- #VERIFIED — 已验证通过
- #BLOCKED — 被阻塞

所有状态标签的前后均有一个空格（前面是标点符号或新起一行时，无需空格；后面没有更多文字时，无需空格），以能够在 Obsidian 中呈现无歧义标签为准

---

## Lab1：APB 从接口 + SRAM

| ID    | 功能描述                      | Spec §     | 实现状态  | TB 状态 | 关联 Testcase                       | 备注                            |
| ----- | ------------------------- | ---------- | ----- | ----- | --------------------------------- | ----------------------------- |
| F1-01 | APB 两段式传输时序               | §4.1       | #DONE | #DONE | tc_apb_basic_rw                   | #VERIFIED                     |
| F1-02 | PREADY 固定为 1              | §4.1       | #DONE | #DONE | tc_apb_basic_rw                   | #VERIFIED                     |
| F1-03 | CSR 地址映射（0x000~0x02B）     | §4.2, §5.2 | #DONE | #DONE | tc_csr_default_rw                 | #VERIFIED                     |
| F1-04 | 保留地址返回 PSLVERR=1          | §4.2, §8.3 | #DONE | #DONE | tc_slverr_reserved                | #VERIFIED                     |
| F1-05 | CSR 默认值正确                 | §5.2       | #DONE | #DONE | tc_csr_default_rw                 | #VERIFIED                     |
| F1-06 | RW 寄存器读写                  | §5.1, §5.2 | #DONE | #DONE | tc_csr_default_rw, tc_rw_readback | #VERIFIED                     |
| F1-07 | RO 寄存器写保护（PSLVERR=1）      | §5.1, §8.3 | #DONE | #DONE | tc_ro_write_protect               | #VERIFIED                     |
| F1-08 | W1P 行为（CTRL.start）        | §5.1, §5.2 | #DONE | #DONE | tc_w1p_start                      | #VERIFIED （M1 级）              |
| F1-09 | RW1C 行为（IRQ_STA）          | §5.1, §5.2 | #DONE | #DONE | tc_rw1c_irq_sta                   | #VERIFIED                     |
| F1-10 | PKT_MEM 地址映射（0x040~0x05C） | §6.1       | #DONE | #DONE | tc_pkt_mem_write                  | #VERIFIED                     |
| F1-11 | PKT_MEM 写端口生成             | §6.2       | #DONE | #DONE | tc_pkt_mem_write                  | #VERIFIED                     |
| F1-12 | busy=1 时写 PKT_MEM 报错      | §6.3       | #DONE | #DONE | tc_busy_write_protect             | #VERIFIED （M1+M2 级）           |
| F1-13 | M2 双端口同步 SRAM             | §2.2       | #DONE | #DONE | tc_pkt_mem_write                  | #VERIFIED                     |
| F1-14 | M2 复位清零                   | §2.2       | #DONE | #DONE | —                                 | #VERIFIED （隐含；实现约定，非 spec 强制） |
| F1-15 | 中断逻辑（irq_o）               | §8.2       | #DONE | #DONE | tc_irq_logic                      | #VERIFIED                     |

## Lab2：包处理核心

| ID | 功能描述 | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注 |
|----|----------|--------|----------|---------|---------------|------|
| F2-01 | 三态 FSM（IDLE->PROCESS->DONE） | §7.1 | #DONE | #DONE | TC1/TC2/TC5 | #VERIFIED |
| F2-02 | M3 收到 start_i 后无条件启动处理 | §7.2 | #DONE | #DONE | TC5 | #VERIFIED |
| F2-03 | busy/done 时序正确 | §7.4 | #DONE | #DONE | TC5 | #VERIFIED |
| F2-04 | 包头解析（pkt_len/type/flags/hdr_chk） | §3.1, §7.3 | #DONE | #DONE | TC1/TC2 | #VERIFIED |
| F2-05 | 长度检查（pkt_len [4,32]） | §3.2, §9.1 | #DONE | #DONE | TC3/TC4 | #VERIFIED |
| F2-06 | 类型检查（one-hot + type_mask） | §9.1 | #DONE | #DONE | TC7/TC8 | #VERIFIED |
| F2-07 | 头校验（hdr_chk == B0^B1^B2） | §9.1 | #DONE | #DONE | TC9 | #VERIFIED |
| F2-08 | algo_mode 旁路 | §5.2, §9.1 | #DONE | #DONE | TC10 | #VERIFIED |
| F2-09 | payload sum 计算 | §3.4, §7.3 | #DONE | #DONE | TC2/TC13/TC14 | #VERIFIED |
| F2-10 | payload XOR 计算 | §3.4, §7.3 | #DONE | #DONE | TC2/TC13/TC14 | #VERIFIED |
| F2-11 | 错误可并行成立 | §9.2 | #DONE | #DONE | TC11 | #VERIFIED |
| F2-12 | DONE 态结果保持至下次 start | §7.2, §7.4 | #DONE | #DONE | TC5/TC6 | #VERIFIED |
| F2-13 | 长度越界时 M3 不卡死 | §7.2, §9.1 | #DONE | #DONE | TC3/TC4 | #VERIFIED |
| F2-14 | PKT_LEN_EXP 与 pkt_len 不符时 length_error | §9.1 | #DONE | #DONE | TC12/TC13 | #VERIFIED |
| F2-15 | 最大合法包满载处理（pkt_len=32, 28B payload） | §3.2, §10.1 | #DONE | #DONE | TC15 | #VERIFIED |

## Lab3：顶层集成

| ID    | 功能描述                       | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注  |
| ----- | -------------------------- | ------ | ---- | ----- | ----------- | --- |
| F3-01 | ppa_top 顶层连线               | §2.1   | #DONE | #DONE  | TC1, TC11   | #VERIFIED M2 读端口 MUX 仲裁；TC11 验证 PKT_MEM 读回路径 |
| F3-02 | 端到端链路（APB->CSR->SRAM->FSM->结果） | §2.1   | #DONE | #DONE  | TC1, TC4~TC8 | #VERIFIED TC4 最大包；TC5~TC8 错误通路端到端 |
| F3-03 | 连续两帧顺序处理                   | §7.2, §10.1 | #DONE | #DONE  | TC2         | #VERIFIED |
| F3-04 | STATUS 总线通路                | §5.2   | #DONE | #DONE  | TC3         | #VERIFIED |
| F3-05 | busy 期间写保护（选做）             | §6.3   | #DONE | #DONE  | TC9         | #VERIFIED |
| F3-06 | 中断路径闭环（选做）                 | §8.2   | #DONE | #DONE  | TC10        | #VERIFIED |

## Lab4：回归测试与覆盖率

| ID | 功能描述 | Spec § | 实现状态 | TB 状态 | 关联 Testcase | 备注 |
|----|----------|--------|----------|---------|---------------|------|
| F4-01 | make smoke 一键冒烟 | — | #TODO | #TODO | — | |
| F4-02 | make regress 全量回归 | — | #TODO | #TODO | — | |
| F4-03 | make cov 覆盖率收集 | — | #TODO | #TODO | — | |
| F4-04 | testplan 文档完整 | — | #TODO | #TODO | — | |
| F4-05 | 五类覆盖率达标 | — | #TODO | #TODO | — | |
| F4-06 | result_summary 汇总 | — | #TODO | #TODO | — | |

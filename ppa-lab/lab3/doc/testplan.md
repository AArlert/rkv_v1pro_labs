# Lab3 测试计划 (Test Plan)

> 由 Verification Plan Agent 编写（2026-05-12）
> 覆盖 feature-matrix F3-01 ~ F3-06 全部 6 个功能点

## 测试策略

Lab3 为集成级端到端验证，DUT 为 `ppa_top`（M1+M2+M3 完整系统）。TB 通过 APB 接口驱动完整流程：写 PKT_MEM → 配置 CTRL → start → 轮询 STATUS.done → APB 读结果 / ERR_FLAG。所有用例在同一仿真中顺序执行，`make run` 一次运行全量。

与 Lab2 模块级验证的区别：Lab2 TC 直接驱动 M3 端口验证 FSM 行为；Lab3 TC 通过 APB 总线端到端验证信号在 M1→M2→M3→M1 完整链路上的正确传递。

---

## 已有用例（DUT Agent 提供）

| TC ID | 名称 | 覆盖功能 | 检查点 | 输入摘要 | 期望输出 | 优先级 | 结果 |
|-------|------|----------|--------|----------|----------|--------|------|
| TC1 | tc_e2e_basic | F3-01, F3-02 | 8B 合法包端到端：写 PKT_MEM→start→done→读结果全部正确 | pkt_len=8, type=0x02, payload=0x01020304 | RES_PKT_LEN=8, TYPE=0x02, SUM=0x0A, XOR=0x04, STATUS=0x0A, ERR_FLAG=0x00 | P0 | PASS |
| TC2 | tc_two_frames | F3-03 | 第一帧 done 后写第二帧(4B 最小包)→start→done→结果独立正确 | Frame2: pkt_len=4, type=0x01 | Frame2 RES_PKT_LEN=4, TYPE=0x01, SUM=0x00, STATUS=0x0A | P0 | PASS |
| TC3 | tc_status_bus | F3-04 | 12B 包 start 后立即读 STATUS 捕获 busy；done 后读 STATUS 捕获 done | pkt_len=12, type=0x04 | busy 时 STATUS[1:0]=0x01; done 时 STATUS[1:0]=0x02 | P0 | PASS |

## VPlan 阶段补充 TC

| TC ID | 名称 | 覆盖功能 | 检查点 | 输入摘要 | 期望输出 | 优先级 | 结果 |
|-------|------|----------|--------|----------|----------|--------|------|
| TC4 | tc_e2e_max_packet | F3-02 | 最大合法包(32B)端到端处理正确，验证 M2 全 8 word 读路径 | pkt_len=32, type=0x04, payload=0x01..0x1C (28B) | RES_PKT_LEN=32, SUM=0x96, XOR=0x1C, ERR_FLAG=0x00 | P0 | PASS |
| TC5 | tc_e2e_error_length | F3-02 | 包长下溢(pkt_len=3)，ERR_FLAG.length_error 端到端通路正确 | pkt_len=3, type=0x01, hdr_chk=0x02 | ERR_FLAG[0]=1, STATUS=0x06 (done+error) | P0 | PASS |
| TC6 | tc_e2e_error_type | F3-02 | 非法 pkt_type(0x03)，ERR_FLAG.type_error 端到端通路正确 | pkt_len=4, type=0x03, hdr_chk=0x07 | ERR_FLAG[1]=1, STATUS=0x06 | P0 | PASS |
| TC7 | tc_e2e_chk_error | F3-02 | hdr_chk 错误，ERR_FLAG.chk_error 端到端通路正确 | pkt_len=4, type=0x01, hdr_chk=0xFF (wrong) | ERR_FLAG[2]=1, STATUS=0x06 | P0 | PASS |
| TC8 | tc_e2e_algo_bypass | F3-02 | algo_mode=0 时同一错包 chk_error=0，CFG 路径端到端验证 | 同 TC7 包, CFG.algo_mode=0 | ERR_FLAG=0x00, STATUS=0x0A (format_ok=1) | P0 | PASS |
| TC9 | tc_busy_write_protect | F3-05 | busy=1 写 PKT_MEM→PSLVERR=1 且 SRAM 内容不变 | 32B 包处理中写 PKT_MEM Word1 | PSLVERR=1; done 后读回 Word1 与原值一致 | P1（选做） | PASS |
| TC10 | tc_irq_path_e2e | F3-06 | done_irq_en=1→done 触发 irq_o=1→清 IRQ_STA→irq_o=0 | 4B 合法包 + IRQ_EN.done_irq_en=1 | irq_o=1 on done; IRQ_STA[0]=1; 清除后 irq_o=0 | P1（选做） | PASS（修复后） |
| TC11 | tc_pkt_mem_readback | F3-01 | APB 读 PKT_MEM 路径正确（验证 U-1 修复：pkt_mem_rdata_i） | 写 8 word 已知数据到 PKT_MEM | 逐 word 读回与写入值一致（M3 空闲时） | P0 | PASS |

---

## Feature-Matrix 覆盖映射

| Feature ID | 功能 | 覆盖 TC |
|------------|------|---------|
| F3-01 | ppa_top 顶层连线 | TC1, **TC11** |
| F3-02 | 端到端链路 | TC1, **TC4**, **TC5**, **TC6**, **TC7**, **TC8** |
| F3-03 | 连续两帧顺序处理 | TC2 |
| F3-04 | STATUS 总线通路 | TC3 |
| F3-05 | busy 期间写保护（选做） | **TC9** |
| F3-06 | 中断路径闭环（选做） | **TC10** |

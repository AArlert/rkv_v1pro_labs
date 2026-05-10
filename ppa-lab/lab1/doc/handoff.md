# Lab1 交接笔记 (Handoff Notes)

---

## Handoff: DUT Agent -> Verification Plan Agent (2026-05-10, Lab1)

### 我做了什么
1. 实现 `ppa_apb_slave_if.sv`（M1）：APB 3.0 从接口 + 完整 CSR 寄存器组（11 个寄存器）
2. 实现 `ppa_packet_sram.sv`（M2）：8x32-bit 双端口同步 SRAM
3. 搭建 SV TB `ppa_tb.sv`：3 条测试用例（CSR 默认值 / PKT_MEM 写入+自动回读比对 / RES_* 读通路）
4. 编写 Makefile：comp/run/rung/clean 目标可用
5. 编写 design-prompt.md / acceptance.md / log.md

### 我没做什么 / 留给下一步的
1. 未运行 `make comp` / `make run`（待验证环境确认）
2. testplan.md 为空（由 Verification Plan Agent 编写）
3. busy=1 写保护的端到端验证（需 M3 配合，归 Lab3）
4. 中断路径闭环验证（需 Lab3 顶层集成）
5. PKT_MEM 的 APB 读返回当前实现为 0（M1 未连接 M2 读端口，Lab3 集成时解决）

### 踩过的坑 / 要小心的
1. CSR 读数据需按位域拼接，RO 字段从 M3 输入端口取值而非寄存器
2. W1P 类型（CTRL.start）不存储，读回恒为 0
3. 地址空间有"保留区"（0x02C~0x03F），不要遗漏 PSLVERR 逻辑

### 验证成果的最小命令
```
cd ppa-lab/lab1/svtb/sim
make comp
make run
```

### 推荐下一步动作
1. **[P0]** 运行 `make comp` 确认编译通过（0 error, 0 warning）
2. **[P0]** 运行 `make run` 确认 TC1/TC2/TC3 全部 PASS
3. **[P1]** 编写 testplan.md，为 Lab4 回归做准备

---

## Handoff: Review Agent → Verification Plan Agent (2026-05-11, Lab1)

### 我做了什么（≤5 条）
1. 运行 `make comp`（0 error, 0 warning）和 `make run`（25/25 PASS）确认编译仿真通过
2. 逐项审查 F1-01 ~ F1-15 全部 15 个功能点与 Spec 的一致性，结果记入 `log.md § 2 审查阶段`
3. 确认 M1 端口列表、地址译码、CSR 属性（RW/RO/W1P/RW1C）、PSLVERR 策略均与 Spec 一致
4. 确认 M2 存储体、端口、复位行为与 Spec 一致
5. 确认已知非阻塞问题 U-1（PKT_MEM APB 读返回 0）属于 Lab3 集成范畴，不阻塞 Lab1

### 我没做什么 / 留给下一步的（≤5 条）
1. 未编写 testplan.md（由 VPlan Agent 负责）
2. 未补充 TB #TODO 用例（F1-04 保留地址 / F1-07 RO 写保护 / F1-08 W1P / F1-09 RW1C / F1-12 busy 写保护 / F1-15 中断）
3. 未验证 RW 寄存器写后读（TC1 仅检查默认值，TC3 检查 RO 直透）
4. 未做波形级审查（依赖 VPlan Agent 补充定向用例）

### 踩过的坑 / 要小心的（≤3 条）
1. APB read task 中 PRDATA 采样时机：组合输出在 ACCESS 阶段立即有效，当前 TB 时序正确对齐
2. start_accepted 使用 reg_enable（已生效值），同时写 enable=1 和 start=1 时 start 不会被接受——这是正确行为，TB 需注意先写 enable 再写 start
3. IRQ_STA 清除优先于置位（互斥 if-else 分支），若 done_rising 与 APB 清中断写同拍发生，清除生效、置位不生效

### 验证成果的最小命令
```
cd ppa-lab/lab1/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** 编写 testplan.md，覆盖 feature-matrix 中 TB 为 #TODO 的 6 个功能点
2. **[P0]** 补充 TC：tc_slverr_reserved / tc_ro_write_protect / tc_rw1c_irq_sta / tc_rw_readback
3. **[P1]** 确认 `make run` 全量 PASS 后更新 feature-matrix TB 列 → #DONE

---

## Handoff: VPlan Agent → Sign-off Agent (2026-05-11, Lab1)

### 我做了什么（≤5 条）
1. 编写 `testplan.md`，覆盖 F1-01~F1-15 全部 15 个功能点（10 条 TC，含覆盖映射表）
2. 在 `ppa_tb.sv` 中新增 7 条 TC（TC4~TC10），补全 feature-matrix 中 6 个 TB #TODO 项 + 1 个 RW readback 补充
3. 新增 2 个辅助 task：`apb_write_with_slverr` / `apb_read_with_slverr`，用于 PSLVERR 捕获验证
4. `make comp` 0 error 0 warning；`make run` 61/61 PASS，0 FAIL
5. 更新 feature-matrix（F1-04/07/08/09/12/15 TB 列 → #DONE）、ppa-status.md

### 我没做什么 / 留给下一步的（≤5 条）
1. 未按 acceptance.md 逐项判定验收结论（由 Sign-off Agent 负责）
2. 未做波形级审查（定向用例已通过自动比对，波形可由 `make rung` 打开 GUI 查看）
3. PKT_MEM APB 读路径仍返回 0（U-1，Lab3 集成解决）
4. F1-08/F1-12 仅在 M1+M2 级验证（start 脉冲、busy 写保护），端到端验证需 Lab3

### 踩过的坑 / 要小心的（≤3 条）
1. PSLVERR 是组合输出，在 ACCESS 阶段（PSEL=1 & PENABLE=1）有效——捕获时机必须在第三个 posedge 的 blocking 赋值
2. done_rising 检测依赖 done_i_d（寄存的上一拍值），触发 IRQ 前需确保 done_stub 先置 0 并等待 2 拍以清除历史状态
3. IRQ_STA 清除/置位互斥（if-else 分支），同拍写 IRQ_STA 清除时不会发生重新置位

### 验证成果的最小命令
```
cd ppa-lab/lab1/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** 按 `acceptance.md` 逐项判定 PASS/FAIL，验收结论记入 `log.md`
2. **[P0]** 全部必做项 PASS 后关闭 Lab1
3. **[P1]** 如有 FAIL → 归因后进入迭代阶段

---

## Handoff: Sign-off Agent → DUT Agent (2026-05-11, Lab1 → Lab2)

### 我做了什么（≤5 条）
1. 独立运行 `make comp`（0 error, 0 warning）和 `make run`（61/61 PASS）确认仿真结果
2. 按 `acceptance.md` 逐项判定 4 项必做验收标准，全部 PASS
3. 交叉验证 feature-matrix F1-01~F1-15 与 testplan.md 覆盖映射，确认 15 个功能点全覆盖
4. 更新 acceptance.md（PASS 状态 + 验收结论）、log.md（§4 验收阶段 + §5 迭代阶段）
5. 更新 feature-matrix（F1-01~F1-15 备注列 → #VERIFIED）、ppa-status.md（Lab1 关闭）

### 我没做什么 / 留给下一步的（≤5 条）
1. 未做波形级审查（所有 TC 已通过自动比对，需要时可 `make rung` 打开 GUI）
2. 未解决 U-1（PKT_MEM APB 读返回 0），归 Lab3 集成
3. 未做 F1-08/F1-12 端到端验证（需 M3 配合），归 Lab3
4. Lab2 feature-matrix（F2-01~F2-13）均为 #TODO，由 DUT Agent 启动

### 踩过的坑 / 要小心的（≤3 条）
1. Lab1 的 acceptance.md 仅定义了 4 项基础标准，实际验证覆盖度远超此范围（10 TC / 61 checks）——后续 lab 建议在 acceptance.md 中补充进阶验收标准
2. IRQ_STA 清除/置位互斥分支：同拍 done_rising 与 APB 写清除同时发生时，清除优先——Lab2/3 设计 M3 时需知晓此行为
3. start_accepted 依赖 reg_enable（已生效值），先写 enable 再写 start 才能产生脉冲——Lab2 TB 需注意序列

### 验证成果的最小命令
```
cd ppa-lab/lab1/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** 启动 Lab2：由 DUT Agent 实现 M3（ppa_packet_proc_core.sv），按 Spec §7~9 实现 FSM + 包解析 + 格式检查
2. **[P0]** 编写 Lab2 design-prompt.md 和 acceptance.md
3. **[P1]** 编写 Lab2 最小 TB 验证 FSM 基本状态转移

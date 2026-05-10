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

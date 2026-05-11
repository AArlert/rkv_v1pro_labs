# Lab1 交接笔记 (Handoff Notes)

---

## Handoff: DUT Agent → Verification/Integration Agent (2026-04-23, Lab1)

### 我做了什么
1. 实现 `ppa_apb_slave_if.sv`（M1）：APB 3.0 从接口 + 完整 CSR 寄存器组
2. 实现 `ppa_packet_sram.sv`（M2）：8×32-bit 双端口同步 SRAM
3. 搭建 SV TB 骨架 `ppa_tb.sv`：3 条基础测试用例
4. 完成审查：123 项全 PASS，与 spec 完全一致
5. 编写 Makefile：comp/run/rung/clean 目标可用

### 我没做什么 / 留给下一步的
1. testplan.md 为空（未正式编写验证计划）
2. busy=1 写保护的端到端验证（需 M3 配合，归 Lab3）
3. 中断路径闭环验证（需 Lab3 顶层集成）
4. TC2 的自动化强验证（目前仅波形弱验证）
5. PKT_MEM 的读端口功能（M3 读端口 Lab1 未连接）

### 踩过的坑 / 要小心的
1. CSR 读数据需按位域拼接，RO 字段从内部信号取值而非寄存器
2. W1P 类型（CTRL.start）不存储，读回恒为 0
3. 地址空间有"保留区"（0x02C~0x03F），不要遗漏 PSLVERR 逻辑

### 验证成果的最小命令
```
cd ppa-lab/lab1/svtb/sim
make comp
make run
```

### 推荐下一步动作
1. **[P0]** 启动 Lab3 顶层集成，创建 `ppa_top.sv` 连线 M1+M2+M3
2. **[P1]** 补齐 Lab1 testplan.md，为 Lab4 回归做准备
3. **[P2]** 在 Lab3 端到端环境下验证 busy 写保护和中断闭环

# Lab4 交接笔记 (Handoff)

## Handoff: VPlan Agent → Next Agent (2026-05-13, Lab4 Phase 0)

### 我做了什么
1. 创建 lab4/ 目录结构 (doc/, rtl/, svtb/tb/, svtb/sim/)
2. 通读 Lab1-3 全部 testplan.md、ppa_tb.sv、acceptance.md、feature-matrix
3. 与 Spec §10 验收测试场景矩阵逐项交叉比对
4. 输出 `lab4/doc/testplan.md` — 36 TC / 177 checks 结构化回归列表
5. 定义 Smoke (4 TC) / Regress (36 TC) 分级, 附下游工作备忘

### 我没做什么 / 留给下一步的
1. **Makefile 统一入口** (`make smoke / regress / cov`) — 需新建 lab4/svtb/sim/Makefile
2. **全量回归运行** — 需在 lab4 Makefile 就位后执行
3. **Coverage 收集** — 需在 Makefile 加 `+cover` 编译选项和 `coverage save/report`
4. **UVM 升级** — testplan.md §8.2 已列出升级路径要点, 但未动手
5. **E-2/E-4/B-4 E2E 补充** — 当前仅 module-level 覆盖, 非阻塞但可增强

### 踩过的坑 / 要小心的
1. Lab1 TC 编号 (TC1~TC10) 与 Lab2/Lab3 TC 编号有重叠, 回归列表使用 L1_TC01 等前缀消歧
2. Lab1 TB 的 M3 输入是 stub 驱动, 不可与 Lab3 E2E TC 混为一级
3. Lab2 TC15 是迭代阶段追加的 (N-3 验收场景), 在原始 testplan.md 的 VPlan 补充表中未列出但在 TB 源码中已实现

### 验证成果的最小命令
```bash
# 确认 testplan 文件已生成
cat ppa-lab/lab4/doc/testplan.md | head -5

# 确认现有回归仍全 PASS (各 lab 独立运行)
cd ppa-lab/lab1/svtb/sim && make comp && make run
cd ppa-lab/lab2/svtb/sim && make comp && make run
cd ppa-lab/lab3/svtb/sim && make comp && make run
```

### 推荐下一步动作
1. **建立 lab4/svtb/sim/Makefile** — 实现 `make smoke` (4 TC 快速冒烟) 和 `make regress` (3 lab 顺序全量)
2. **运行全量回归** — 确认 36 TC / 177 checks 全 PASS
3. **启用覆盖率收集** — `make cov` 生成 Questa HTML 覆盖率报告 (line/branch/condition/FSM/toggle)

---

## Handoff: Verification Phase 1 Agent → Next Agent (2026-05-13, Lab4 Phase 1)

### 我做了什么

1. **建立 `lab4/svtb/sim/Makefile`** — 统一入口, 支持 `make smoke / regress / cov / clean`
2. **运行全量回归** — 36 TC / 177 checks 全 PASS (Lab1: 61, Lab2: 76, Lab3: 40)
3. **启用覆盖率收集** — 使用 `-cover bcstf` 编译, `coverage save -onexit` 运行, `vcover merge + report -html` 生成 HTML 报告
4. **更新 .gitignore** — 添加 covdata/ covhtmlreport/ work_lab*/ *.ucdb 忽略规则

### Coverage 基线 (2026-05-13)

| 覆盖率类型 | Bins | Hits | Misses | Coverage |
|-----------|------|------|--------|----------|
| Statements (line) | 665 | 642 | 23 | **96.54%** |
| Branches | 172 | 151 | 21 | **87.79%** |
| Conditions | 70 | 53 | 17 | **75.71%** |
| FSM States | 6 | 6 | 0 | **100.00%** |
| FSM Transitions | 10 | 6 | 4 | **60.00%** |
| Toggles | 2934 | 2275 | 659 | **77.53%** |
| **Total** | | | | **82.93%** |

#### RTL 逐模块 Coverage (关键实例)

| Instance | Module | Stmt | Branch | Cond | FSM St | FSM Tr | Toggle |
|----------|--------|------|--------|------|--------|--------|--------|
| /ppa_tb/u_apb_slave | ppa_apb_slave_if (Lab1独立) | 97.91% | 97.61% | 84.21% | — | — | 66.16% |
| /ppa_tb/u_sram | ppa_packet_sram (Lab1独立) | 100% | 100% | — | — | — | 95.94% |
| /ppa_tb/u_dut | ppa_packet_proc_core (Lab2独立) | 99.00% | 96.87% | 100% | 100% | 60% | 83.63% |
| /ppa_tb/u_dut/u_m1 | ppa_apb_slave_if (Lab3集成) | 81.25% | 76.19% | 63.15% | — | — | 79.95% |
| /ppa_tb/u_dut/u_m2 | ppa_packet_sram (Lab3集成) | 100% | 100% | — | — | — | 99.32% |
| /ppa_tb/u_dut/u_m3 | ppa_packet_proc_core (Lab3集成) | 98.01% | 90.62% | 91.66% | 100% | 60% | 84.14% |

#### Coverage Gap 分析

1. **FSM Transitions 60%** — M3 的 `ppa_packet_proc_core` FSM 有 5 条合法迁移, 仅覆盖 3 条。缺失的 2 条可能是异常路径 (如从 PROC 直接回到 IDLE 的 error 短路径)
2. **Conditions 75.71%** — 主要 gap 在 `ppa_apb_slave_if` 的复杂地址解码条件 (多条件组合的真假覆盖不完全)
3. **Toggles 77.53%** — Toggle 主要受限于 32-bit 数据路径中高位未充分翻转 (payload 值覆盖有限)
4. **Branch in Lab3 M1 (76.19%)** — 集成级测试对 M1 的 error path 覆盖弱于 Lab1 独立验证 (CSR error 路径由 Lab1 直接 stub 驱动)

### Makefile 使用方式

```bash
cd ppa-lab/lab4/svtb/sim

make smoke    # 快速冒烟: Lab1 only (10 TC / 61 checks, ~5s)
make regress  # 全量回归: Lab1+2+3 (36 TC / 177 checks, ~15s)
make cov      # 带覆盖率回归 + HTML 报告 (report at covhtmlreport/index.html)
make clean    # 清除所有生成物
```

### Makefile 架构 — 利于 UVM 升级

当前 Makefile 设计考虑了后续 UVM 升级的扩展性:

1. **RTL 文件列表集中定义** (`RTL_LAB1`, `RTL_LAB2`, `RTL_LAB3`, `RTL_ALL`) — UVM 升级时直接复用
2. **Coverage flags 变量化** (`COV_COMP`, `COV_RUN`) — UVM 升级时可追加 `-cover e` (expression) 或 covergroup 选项
3. **每 lab 独立 work library** (`work_lab1/2/3`) — UVM 升级后合并为单一 `work/` 即可
4. **`vcover merge`** 已就绪 — UVM 升级后只需改编译/运行逻辑, merge 和 report 流程不变
5. **`smoke` target 预留** — UVM 后可改为 `+UVM_TESTNAME=ppa_smoke_test` 方式选择 TC

### 我没做什么 / 留给后续阶段的

1. **UVM 升级** — 将 3 个纯 SV TB 统一为 UVM 环境 (vif/agent/driver/monitor/scoreboard/test)
2. **功能覆盖率 (covergroup)** — 当前仅有代码覆盖率, 无 functional coverage
3. **Coverage closure** — FSM transition 60% 和 condition 75.71% 有提升空间
4. **TB 代码覆盖率排除** — TB 本身 (ppa_tb) 的覆盖率 (50% branch) 应被排除, 仅关注 RTL
5. **Regression 结果自动解析** — 当前依靠 `ALL TESTS PASSED` 文本判定, 可增加 pass/fail 计数自动提取

### 踩过的坑 / 要小心的

1. **UCDB merge 警告** — 因 3 个 lab 共享 `ppa_tb` 模块名但实现不同, merge 时会报 `vcover-6820 Source code mismatch` 警告。**RTL 覆盖率不受影响**, TB 代码覆盖率仅保留 Lab1 的
2. **vlib 必须显式调用** — 使用非默认 library 名 (work_lab1 等) 时需先 `vlib`, 否则 vlog 报错
3. **Lab3 编译需全部 RTL** — ppa_top 例化了 M1+M2+M3, 必须编译 `RTL_ALL` 而非仅 `RTL_LAB3`
4. **Questa 2021.1 -cover flags** — `bcstf` (branch/condition/statement/fsm/toggle); 不含 `e` (expression) 因当前无需

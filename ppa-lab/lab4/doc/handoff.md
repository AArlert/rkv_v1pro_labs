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

#### Coverage Gap 根因分析

Spec §11.5 #2 验收标准: ≥90% 合格 / ≥95% 优良 / 100% 优秀。当前 4/6 项不合格。

**根因 A: TB 代码污染 RTL 覆盖率统计 (影响 Condition/Branch/Toggle)**

TB 的 check macro、fail 计数器、timeout 逻辑被纳入统计, 在"全 PASS"回归中永远不走 false 分支:
- `actual === expected` condition `_0` 无法命中; `fail_cnt == 0` 同理; `t < timeout` 同理
- `fail_cnt[0:31]` 全 0 → 64 toggle bins 全 miss; `pass_cnt[7:31]` 高位不翻转
- `/ppa_tb` 实例: branch 50%, condition 25%, toggle 67.82%, 严重拖低全局指标

解决: Makefile `cov` target 拆成两步 vlog — RTL 用 `-cover bcstf`, TB 不加 `-cover`。预估: Condition +8~10%, Branch +5%, Toggle +5~8%。

**根因 B: 缺少异步复位测试 (影响 FSM Transitions/Toggle)**

FSM 缺失的 2 条迁移 (均在 ppa_packet_proc_core.sv:131, reset 路径):
- `S_PROCESS → S_IDLE` (处理中途被 reset)
- `S_DONE → S_IDLE` (完成态被 reset)

所有 TB 在仿真开头一次性复位 (此时 FSM 必然在 S_IDLE), 之后不再触发 reset。`rst_n` 信号也因此只有 0→1 方向, miss 一半 toggle bin。

另: FSM `case(state)` 的 `default` 分支 (ppa_packet_proc_core.sv:243) 是结构性不可达代码 (state 只能是 0/1/2), 应登记为合法排除项。

解决: 新增 1 个 mid-sim reset TC → FSM Transitions 60% → 100%。

**根因 C: 跨 Lab 实例重复统计 + 测试焦点不同 (影响 Branch/Condition/Toggle)**

`ppa_apb_slave_if` 产生 2 个覆盖率实例:
- `/ppa_tb/u_apb_slave` (Lab1 独立) → branch 97.61%
- `/ppa_tb/u_dut/u_m1` (Lab3 集成) → branch 76.19%

Lab3 集成测试重心是 E2E 链路, 不覆盖 CSR error path, 具体缺失:

| 缺失项 (Lab3 M1 实例) | 原因 |
|----------------------|------|
| `!is_valid_addr` 分支 (line 142) | Lab3 不访问非法地址 (Lab1 TC4 已覆盖) |
| `write_ro` 分支 (line 144) | Lab3 不写 RO 寄存器 (Lab1 TC5 已覆盖) |
| CTRL/CFG/IRQ_EN/IRQ_STA read case 分支 | Lab3 只读结果寄存器 |
| `err_irq` 路径全部 5 个 condition 项 (line 202) | Lab3 TC10 仅测 done_irq, 未测 err_irq |
| `ADDR_PKT_LEN_EXP` write 条件 (line 193) | Lab3 从未写此寄存器 |
| `type_mask[0:3]` toggle | Lab3 从未改 type_mask (保持复位默认 4'b1111) |

解决: ① `vcover merge` 改用 `-du` 按 Design Unit 合并 (同一 RTL 的不同实例合并); ② 新增 Lab3 err_irq E2E TC。

**根因 D: 测试数据多样性不足 (影响 Toggle)**

- `res_pkt_type_o[3:7]` 未翻转 (测试仅用 0x01/0x02/0x04/0x08, 最高到 bit3)
- `res_pkt_len_o[4]` 未翻转 (最大包长 32=0x20, bit5 翻转但 bit4 总为 0)
- `exp_pkt_len_i[0:5]` 在 Lab3 全未翻转 (从未设置 PKT_LEN_EXP)
- `PREADY` 硬连线 1, 永不翻转 (设计意图, 合法排除)
- `PADDR[7:11]` 地址空间仅到 0x05C, 高位永为 0 (设计意图, 合法排除)

解决: 增加 payload 数据多样性 (0xFF/0xAA/0x55 模式); 在 Lab3 写一次 PKT_LEN_EXP; 建立排除登记表。

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

1. **Coverage Closure** — 当前 4/6 项不合格 (见根因分析), 需执行下列动作
2. **UVM 升级** — 将 3 个纯 SV TB 统一为 UVM 环境 (vif/agent/driver/monitor/scoreboard/test)
3. **功能覆盖率 (covergroup)** — 当前仅有代码覆盖率, 无 functional coverage
4. **Regression 结果自动解析** — 当前依靠 `ALL TESTS PASSED` 文本判定, 可增加 pass/fail 计数自动提取

### 推荐下一步动作 (Coverage Closure Agent)

按投入产出比排序:

| 优先级 | 动作 | 预估提升 | 工作量 |
|--------|------|---------|--------|
| P0 | Makefile `cov` target: RTL 和 TB 分开编译, TB 不加 `-cover` | Cond +8~10%, Branch +5%, Toggle +5~8% | 改 Makefile 3 处 |
| P0 | `vcover merge` 改用 `-du` 按 Design Unit 合并 | Branch +5~8%, Cond +5%, Toggle +3% | 改 Makefile 1 处 |
| P0 | 新增 mid-sim reset TC (Lab2 or Lab3) | FSM Trans 60→100% | 1 个 TC |
| P1 | 新增 err_irq E2E TC (Lab3), 顺带写 PKT_LEN_EXP | Cond +3~5%, Branch +2% | 1 个 TC |
| P1 | 增加 payload 数据多样性 (0xFF/0xAA/0x55) | Toggle +3~5% | 改 2~3 个 TC |
| P2 | 建立覆盖率排除登记表 (PREADY/PADDR[7:11]/FSM default/TB check) | 各项 +1~3% | Excel + .do |

目标: 五类覆盖率全部 ≥90% (合格线), 争取 ≥95% (优良)。

### 踩过的坑 / 要小心的

1. **UCDB merge 警告** — 因 3 个 lab 共享 `ppa_tb` 模块名但实现不同, merge 时会报 `vcover-6820 Source code mismatch` 警告。**RTL 覆盖率不受影响**, TB 代码覆盖率仅保留 Lab1 的
2. **vlib 必须显式调用** — 使用非默认 library 名 (work_lab1 等) 时需先 `vlib`, 否则 vlog 报错
3. **Lab3 编译需全部 RTL** — ppa_top 例化了 M1+M2+M3, 必须编译 `RTL_ALL` 而非仅 `RTL_LAB3`
4. **Questa 2021.1 -cover flags** — `bcstf` (branch/condition/statement/fsm/toggle); 不含 `e` (expression) 因当前无需

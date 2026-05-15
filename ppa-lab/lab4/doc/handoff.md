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

---

## Handoff: Coverage Closure Agent → Next Agent (2026-05-13, Lab4 Phase 2)

### 我做了什么

1. **消除 TB 覆盖率污染** — Makefile `cov` target 拆分 vlog: RTL 加 `-cover bcstf`, TB 不加。即刻消除 `/ppa_tb` 实例中 condition/branch/toggle 的假性 miss。
2. **FSM Transitions 60%→100%** — 新增 Lab2 TC16/TC17 (mid-sim reset during S_PROCESS 和 S_DONE) + Lab3 TC13 (集成级 mid-sim reset), 覆盖全部 5 条合法迁移。
3. **err_irq E2E 路径** — Lab3 TC12: 设 err_irq_en=1 + PKT_LEN_EXP=8, 发 type_error 帧, 验证 irq_o→清除闭环。填补 M1 Condition 和 Branch 的 err_irq 相关空洞。
4. **Toggle 覆盖率 88.85%→98.28%** — Lab1 TC11 Phase 6/7 + Lab3 TC14 (toggle exercise): 覆盖 exp_pkt_len/type_mask 全位翻转、pkt_len bit4 (pkt_len=20)、res_pkt_type bits4-7 (type=0xF0)、payload sum/xor 缺失位 (0xE3)、PADDR 高位。
5. **数据多样性增强** — Lab2/Lab3 多个现有 TC payload 改为 0xFF/0xAA/0x55 模式, 增加结果寄存器位翻转覆盖。
6. **覆盖率排除登记表** — `lab4/doc/coverage_exclusion.md` 登记 3 项合法排除 (PREADY toggle、PADDR[11:7] toggle、FSM default branch), 含 Spec 依据和 Questa `.do` 文件示例。

### Coverage 最终结果 (Phase 2)

| 覆盖率类型 | Phase 1 基线 | Phase 2 最终 | 判定 |
|-----------|-------------|-------------|------|
| Statements | 96.54% | **98.40%** | 优良 |
| Branches | 87.79% | **96.25%** | 优良 |
| Conditions | 75.71% | **91.93%** | 合格 |
| FSM States | 100% | **100%** | 优秀 |
| FSM Transitions | 60% | **100%** | 优秀 |
| Toggles | 77.53% | **98.28%** | 优良 |
| **Total** | **82.93%** | **97.47%** | **优良** |

验收标准 (Spec §11.5 #2): 五类均 ≥90% ✓, 四类 ≥95% 优良。

### 回归规模变化

| Lab | Phase 0 | Phase 2 | 新增 TC |
|-----|---------|---------|---------|
| Lab1 | 10 TC / 61 chk | 11 TC / 74 chk | TC11 (toggle exercise) |
| Lab2 | 15 TC / 76 chk | 17 TC / 94 chk | TC16 (reset in PROCESS), TC17 (reset in DONE) |
| Lab3 | 11 TC / 40 chk | 14 TC / 56 chk | TC12 (err_irq), TC13 (mid-sim reset), TC14 (toggle exercise) |
| **合计** | **36 TC / 177 chk** | **42 TC / 224 chk** | +6 TC / +47 chk |

### 我没做什么 / 留给后续阶段的

1. **Questa exclude file 实际应用** — `coverage_exclusion.md` 已列出 3 条排除项及 `.do` 示例, 但未实际创建并集成到 Makefile (当前已达标, 排除项仅作审查记录)
2. **Condition 从 91.93% 推向 95%** — 剩余 5 个 miss bin 主要在 `ppa_apb_slave_if` 内部逻辑 (addr decode combination), 需更多 Lab3 CSR error path TC
3. **UVM 升级** — 42 TC 全为纯 SV 过程式, 可统一为 UVM 环境
4. **功能覆盖率 (covergroup)** — 当前仅有代码覆盖率

### 踩过的坑 / 要小心的

1. **`vcover merge -du` 不可用** — Questa 2021.1 的 `vcover merge` 不支持 `-du` 选项 (报 `vcover-17363`); 只能用纯 merge, 必须确保每个实例在其对应 TB 中覆盖充分
2. **Lab2 TC15 payload sum 手算易错** — 28 字节逐字节累加需仔细; RTL 输出 0xBD 为正确值 (中间累加到 word4 后 sum=0x88, 非 0x7C)
3. **Lab1 TC11 err_irq 需 done 上升沿** — M1 中断逻辑用 `done_i` 上升沿检测; 若 done_stub 已经为 1 不会再产生 irq; 必须先清 done_stub 再重新拉高
4. **PADDR toggle 需实际驱动 OOB 地址** — 即使 SLVERR, PADDR 端口仍会翻转 (是合法的覆盖手段)

### 验证成果的最小命令

```bash
cd ppa-lab/lab4/svtb/sim
make cov   # 42 TC / 224 checks ALL PASS + coverage report
# 输出: covhtmlreport/index.html (总覆盖 97.47%)
```

---

## Phase 3 交接 (2026-05-15) — UVM 升级

### 交付物

新增 4 个文件 + 修改 1 个 Makefile：

| 文件 | 说明 |
|------|------|
| `lab4/svtb/tb/ppa_apb_if.sv` | APB virtual interface + irq_o 嗅探（drv_ck/mon_ck） |
| `lab4/svtb/tb/ppa_ref_model.sv` | **Spec 派生** 的纯函数预测模型（CSR 属性、hdr_chk、sum/xor、length/type/chk 错误判定） |
| `lab4/svtb/tb/ppa_pkg.sv` | UVM 环境（item / driver / 2×monitor / scoreboard / coverage / env / 17 sequence / 18 test） |
| `lab4/svtb/tb/ppa_uvm_tb.sv` | TB 顶层（clk/reset、ppa_top 实例化、`ppa_rst_req` 事件监听） |
| `lab4/svtb/sim/Makefile` | 新增 `uvm` / `uvm_compile` / `uvm_cov` / `uvm_clean` target；不动 smoke/regress/cov |

### 设计决策

- **范围**：新建 UVM env 同时覆盖 Lab1（CSR/SRAM）+ Lab2（M3 corner）+ Lab3（E2E）三层场景，不局限于 ppa_top E2E
- **统一 sequence_item**：用 `ppa_op_kind_e` 枚举派发（OP_PKT / OP_RAW_WRITE / OP_RAW_READ / OP_RESET / OP_WAIT / OP_IRQ_CHECK / OP_BUSY_WRITE_PROBE / OP_W1P_PROBE / OP_PKT_MEM_RW），单一 sequencer 不需多 agent
- **Reference model 与 RTL 解耦**：`ppa_ref_model` 是 **pure spec**（§3/§5/§7/§9 的 12 个函数），item 在 `post_randomize()` 调用它生成 expected；scoreboard 直接对比 expected vs APB 观测值
- **Reset 通路**：driver 的 OP_RESET 触发全局 `uvm_event "ppa_rst_req"`，TB 顶层 `initial` 监听并重新拉低 PRESETn 5 拍
- **UVM 库**：用 Questa 内建 `-L mtiUvm`（uvm-1.1d），无需 `$QUESTA_HOME` 硬编码

### 验证结果

```
make uvm        # 18/18 UVM tests PASS（含 ppa_regression_test 串接所有 17 个 sequence）
make regress    # 原 SV 回归 224/224 不退化
```

### 实现期间踩到的坑（已修复）

1. **`pack_hdr_word` 只产 30 bits** — `pkt_len` 是 6-bit，与 `{hdr_chk_field, flags, pkt_type, pkt_len}` 拼接位宽不足 32；修为 `{hdr_chk_field, flags, pkt_type, 2'b00, pkt_len}`
2. **enable+start 同周期写 CTRL=0x3 首包不启动** — 必须先写 CTRL=0x1（enable=1）再写 CTRL=0x3（start W1P）；参考 lab3 tb 的两段式写
3. **`uvm_event::trigger()` 不能传 int** — 原本 `rst_req_ev.trigger(it.n_cycles)` 编译错；改为无参 trigger
4. **`payload.size() <= 28` 与 `(pkt_len >= 4) -> payload.size() == pkt_len-4` 在 ERR_LEN_OVER 下冲突** — 增加 `(pkt_len > 32) -> payload.size() == 28`
5. **`err_mode` 是非 rand 字段，`randomize() with { err_mode == X }` 静默失败** — IRQ_E sequence 改为先 `it.err_mode = ERR_TYPE_BAD` 再 randomize
6. **`set_timeout(5ms)` 因 timescale 实际仅 5us** — 改为 `set_timeout(1s)`，受跨 package timescale 影响也仍足够

### 给下一位 Agent

- 若要做 Phase 4 (UVM 覆盖率收集)：直接 `make uvm_cov`，UCDB 落到 `covdata_uvm/`，HTML 落到 `covhtml_uvm/`
- 若要做 Phase 5 (functional coverage 扩展)：扩 `ppa_pkg.sv::ppa_coverage::cg_pkt`，已有 op/len/type/mask/algo/三类 err 的 coverpoint + cross
- UVM env 当前覆盖率不强求与 SV 基线对齐（用户 2026-05-15 决定：先跑通即可）

---

## Phase 4 交接 (2026-05-15) — UVM 覆盖率收集与对比

### 我做了什么

1. **消除 UVM TB 覆盖率污染** — Makefile `uvm_cov` target 拆分 vlog: RTL 用 `-cover bcstf`，TB 不加。消除 `ppa_ref_model`/`ppa_pkg`/`ppa_uvm_tb`/`ppa_apb_if` 实例的假性 miss。
2. **FSM Transition `S_PROCESS→S_IDLE` 覆盖** — 修复 `ppa_mid_sim_reset_seq`：通过 RAW_WRITE 序列加载长包(pkt_len=32)并启动处理，插入 OP_WAIT(3) 确保 FSM 进入 S_PROCESS 后再 OP_RESET。FSM Transitions 80%→100%。
3. **u_m1 Conditions 89.47%→100%** — 扩展 `ppa_irq_err_seq`：原仅测 `ERR_TYPE_BAD`+err_irq_en，新增独立的 `ERR_LEN_UNDER` 和 `ERR_CHK` 包（均 err_irq_en=1），覆盖 `length_error_i_1` 和 `chk_error_i_1` 两个 FEC condition bin。

### UVM Coverage 最终结果 (Phase 4)

| 覆盖率类型 | 修复前 | 修复后 | SV 基线 | 判定 |
|-----------|--------|--------|---------|------|
| Statements | 69.38% (含TB污染) | **99.36%** | 98.40% | 优良 |
| Branches | 29.10% (含TB污染) | **98.78%** | 96.25% | 优良 |
| Conditions | 30.00% (含TB污染) | **100%** | 91.93% | 优秀 |
| FSM States | 100% (3/3) | **100%** (3/3) | 100% (6/6) | 优秀 |
| FSM Transitions | 80% (4/5) | **100%** (5/5) | 100% (10/10) | 优秀 |
| Toggles | 99.40% | **99.56%** | 98.28% | 优良 |
| **Total** | **70.57%** | **97.84%** | **97.47%** | **优良** |

#### RTL 逐模块 Coverage

| Instance | Stmt | Branch | Cond | FSM St | FSM Tr | Toggle |
|----------|------|--------|------|--------|--------|--------|
| /ppa_uvm_tb/dut (ppa_top) | 100% | 100% | — | — | — | 99.52% |
| /ppa_uvm_tb/dut/u_m1 (ppa_apb_slave_if) | 100% | 100% | 100% | — | — | 99.13% |
| /ppa_uvm_tb/dut/u_m2 (ppa_packet_sram) | 100% | 100% | — | — | — | 100% |
| /ppa_uvm_tb/dut/u_m3 (ppa_packet_proc_core) | 99.00% | 96.87% | 100% | 100% | 100% | 100% |

验收标准 (Spec §11.5 #2): 各模块各项均 ≥90% ✓

### FSM States 3 vs 6 根因说明

SV 基线 FSM States=6 是因为 Lab2 独立 TB 和 Lab3 集成 TB 各有一个 `ppa_packet_proc_core` 实例（3×2=6 bins）。UVM 仅通过 `ppa_top` 测试（含 1 个 M3 实例），故 FSM States=3。实际只有 3 个状态（S_IDLE/S_PROCESS/S_DONE），两种拓扑覆盖率均为 100%。bin 数量差异是测试拓扑差异，不影响验证质量。

### 验证成果的最小命令

```bash
cd ppa-lab/lab4/svtb/sim
make uvm_cov   # 18 tests PASS + coverage report (97.84%)
make regress   # 原 SV 回归 42 TC / 224 checks 不退化
```

### 我没做什么 / 留给后续阶段的

1. **Covergroup (functional coverage) 目前 87.22%** — 未达 90% 但这是自定义功能覆盖率，非代码覆盖率必达项
2. **u_m3 Branch 96.87%** — 剩余 1 个 miss 是 FSM `default` 分支（结构性不可达代码，可排除）
3. **u_m3 Statements 99.00%** — 同上，`default` 分支内的赋值语句

### 踩过的坑

1. **`S_PROCESS→S_IDLE` 时序问题** — 直接在 RAW_WRITE CTRL=3 后发 OP_RESET 不够：start_pulse 是注册信号，需额外 2-3 cycles 才能让 FSM 进入 S_PROCESS。必须插入 OP_WAIT(3) 确保 FSM 已实际进入 S_PROCESS 再触发 reset。
2. **TB 代码污染表现不同** — SV 基线中 TB 污染主要影响 condition/toggle；UVM 中 `ppa_pkg` 的 1051 条 statement 仅 64% hit，单项把总覆盖率从 97.84% 拖到 70.57%。

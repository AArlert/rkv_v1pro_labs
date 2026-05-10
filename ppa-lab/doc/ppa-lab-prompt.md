# 0 总体准则
## 0.1 目标受众
本文件是 PPA-Lite 项目蓝图，定义阶段划分、目录结构和命名规范。
- Agent 行为准则 → 见 `CLAUDE.md`
- 协作协议与角色定义 → 见 `ppa-agent-character.md`
- 技术规格 → 见 `ppa-lite-spec.md`
- 当前进度 → 见 `ppa-status.md`

## 0.2 现状确认
Lab1（M1+M2）和 Lab2（M3）的 RTL 已实现并通过审查。Lab3（顶层集成）和 Lab4（回归覆盖率）待启动。详见 `ppa-status.md`

## 0.3 文件优先级（冲突时裁决顺序）
1. `ppa-lite-spec.md` — 唯一技术真相源
2. `ppa-agent-character.md` — 协作协议
3. 本文件 — 项目蓝图与规范
4. `CLAUDE.md` — 通用编码准则
5. `labX/doc/design-prompt.md` — lab 级设计指引

## 0.4 设计侧硬约束
> 以下为 spec 关键约束的快速索引，详细定义以 spec 原文为准

- 遵循 SystemVerilog、UVM 语言规范，保持一致的缩进（1个TAB）和命名风格
- 模块头部注释包含功能描述、端口说明和参数，在末尾不使用中文句号"。"
- PREADY 固定为 1（spec §4.1）
- APB 写在 ACCESS 阶段生效（spec §4.1）
- 保留/越界地址返回 PSLVERR=1（spec §4.2）
- 写 RO 寄存器返回 PSLVERR=1 且无副作用（spec §8.3）
- CTRL.start 是 W1P，不存储（spec §5.1）
- IRQ_STA 是 RW1C（spec §5.1）
- busy=1 期间写 PKT_MEM 报错且写入无效（spec §6.3）
- done 信号保持至下次合法 start（spec §8.1）
- 三类错误可同时成立（spec §9.1）

## 0.5 验证侧硬约束
- 驱动、监视、检查分离，不要把所有判断写进一个 initial 块
- 定向用例优先覆盖规格中的必做场景矩阵
- 随机测试必须可复现，记录 seed
- 出现 mismatch 时要打印输入摘要、期望值、实际值、测试名、seed
- scoreboard 或 checker 必须基于规格建模
- coverage 只在功能稳定后补

## 0.6 开发环境
Windows + Questasim + Make，在 VS Code 内直接进入现有目录执行 make 完成编译与仿真

## 0.7 开发参考
### 非 UVM 骨架参考
- `mcdt-lab/lab1/mcdt_pkg_ref.sv` — generator/initiator/monitor/checker 组织方式
- `mcdt-lab/lab1/tb.sv` — 时钟复位、interface 例化、test 启动
- `mcdt-lab/lab1/Makefile` — 最小可运行编译脚本

### UVM 与覆盖率骨架参考
- `mcdt-lab/lab3/mcdt_pkg_ref.sv` — UVM 全组件参考实现
- `mcdt-lab/lab3/Makefile` — UVM 和 coverage 编译/运行参数
- `mcdt-lab/lab2/mcdt_pkg.sv` — checker 与 coverage 过渡参考

## 0.8 不建议的做法
- 不建议照抄 MCDT 的整套 UVM 框架
- 不建议通读完整 lecture/mcdt-lab 再开始
- 不建议在规格未吃透前写 scoreboard/coverage
- 不建议把大量逻辑堆在 ppa_top
- 不建议把 Lab1/2 的缺陷拖到 Lab3 统一处理

# 1 项目概述
PPA-Lite（APB Packet Processing Accelerator Lite）是一个可编程的数据包加速处理器，基于 APB 3.0 协议总线接口，包含以下核心功能
- APB 从接口和 CSR 寄存器组
- 8×32-bit 双端口同步 SRAM
- 数据包格式检查（长度、类型、头校验）
- 3 态 FSM 处理流程（IDLE→PROCESS→DONE）
- 中断功能和错误标志

/ppa-lab 是本项目的工作目录，可参考 /mcdt-lab 的验证结构，但不直接迁移其功能规格

# 2 分层设计结构
- **ppa-lite-spec.md**：完整设计规范（唯一真相源）
- **ppa-lab-prompt.md**：项目蓝图与命名规范（本文件）
- **ppa-agent-character.md**：Agent 协作协议
- **ppa-status.md**：当前进度看板
- **ppa-feature-matrix.md**：功能清单与状态追踪（含 spec↔实现↔测试可追溯性）
- **ppa-risk-register.md**：风险与假设登记
- **ARM_AMBA3_APB.pdf**：APB3.0 官方协议文档（按需查阅，不要主动通读）

每个实验阶段有独立文档：
- `labX/doc/design-prompt.md` — 本阶段设计指引，在当前 lab 设计阶段由 DUT Agent 给出
- `labX/doc/testplan.md` — 测试计划
- `labX/doc/log.md` — 实验日志（Agent 负责撰写，用户负责阅读和维护）
- `labX/doc/handoff.md` — Agent 间交接笔记
- `labX/doc/acceptance.md` — 机器化验收标准

# 3 实验阶段划分
## 3.1 lab1：APB 从接口 + SRAM
**核心任务**
- 实现 APB 3.0 从接口（M1）
- 实现 CSR 寄存器组
- 实现 8×32-bit 双端口同步 SRAM（M2）
- 实现 PKT_MEM 地址映射

**验收标准** → 详见 `lab1/doc/acceptance.md`

## 3.2 lab2：包处理核心
**核心任务**
- 实现 3 态 FSM（IDLE→PROCESS→DONE）（M3）
- 实现包头解析逻辑
- 实现格式检查算法
- 实现 payload 的 sum 和 XOR 计算

**验收标准** → 详见 `lab2/doc/acceptance.md`

## 3.3 lab3：顶层集成
**核心任务**
- 实现 ppa_top 顶层模块
- 集成三个子模块（M1+M2+M3）
- 实现端到端驱动序列（引入 UVM）
- 测试连续两帧处理能力

**验收标准**（待 `lab3/doc/acceptance.md` 创建）
1. 端到端链路完整
2. 连续两帧顺序处理正常
3. STATUS 总线通路正确
4. busy 期间写保护正常（选做）
5. 中断路径闭环（选做）

## 3.4 lab4：回归测试与覆盖率
**核心任务**
- 建立 make smoke / regress / cov 统一入口
- 整理全量 testcase
- 运行全量回归测试
- 分析覆盖率并优化

**验收标准**（待 `lab4/doc/acceptance.md` 创建）
1. 一键回归通过率 100%
2. 五类覆盖率达标（line/branch/condition/FSM/toggle）
3. testplan 文档完整
4. 覆盖率过滤合规（选做）

# 4 文件命名规范
## 4.1 设计文件
- 顶层文件：`ppa_top.sv`
- 子模块：`ppa_apb_slave_if.sv`、`ppa_packet_sram.sv`、`ppa_packet_proc_core.sv`
- 公共 package/interface：`ppa_` 前缀（如 `ppa_pkg.sv`、`ppa_apb_if.sv`）

## 4.2 测试文件
- 顶层 testbench：`ppa_tb.sv`
- 定向测试：`tc_<feature>_<case>.sv`
- UVM 测试：`ppa_<scenario>_test.sv`
- testplan：`testplan.md`

## 4.3 执行文件
- 仿真入口：`svtb/sim/Makefile`
- 基础目标：`make comp`、`make run`、`make rung`、`make clean`
- Lab4 增强：`make smoke`、`make regress`、`make cov`

# 5 目录结构规范

```text
ppa-lab/
├── doc/
│   ├── CLAUDE.md               # Agent 入口 + 通用准则
│   ├── ppa-lite-spec.md        # 技术规格（唯一真相源）
│   ├── ppa-lab-prompt.md       # 项目蓝图（本文件）
│   ├── ppa-agent-character.md  # 协作协议
│   ├── ppa-status.md           # 进度看板
│   ├── ppa-feature-matrix.md   # 功能清单 + 可追溯矩阵
│   ├── ppa-risk-register.md    # 风险登记
│   └── ARM_AMBA3_APB.pdf       # APB3.0 官方协议文档（按需查阅）
├── lab1/
│   ├── doc/
│   │   ├── design-prompt.md
│   │   ├── testplan.md
│   │   ├── log.md
│   │   ├── handoff.md
│   │   └── acceptance.md
│   ├── rtl/
│   │   ├── ppa_apb_slave_if.sv
│   │   └── ppa_packet_sram.sv
│   └── svtb/
│       ├── tb/
│       │   └── ppa_tb.sv
│       └── sim/
│           └── Makefile
├── lab2/
│   ├── doc/
│   ├── rtl/
│   │   └── ppa_packet_proc_core.sv
│   └── svtb/
│       ├── sim/
│       ├── tb/
│       └── wave/
├── lab3/
│   ├── doc/
│   ├── rtl/
│   └── svtb/
│       ├── tb/
│       └── sim/
└── lab4/
    ├── doc/
    ├── rtl/
    └── svtb/
        ├── tb/
        └── sim/
```

约束：
- `work/`、`*.log`、`*.wlf`、`*.qdb` 等仿真生成物不纳入版本控制
- 各 lab 目录结构保持同构

# 6 验收流程

每个 lab 按以下阶段推进。各 Agent 的输入契约、产出要求与终止条件详见 `ppa-agent-character.md`。每个阶段结束时执行 `CLAUDE.md § 2 收尾流程`（更新 status、feature-matrix、handoff）。

```text
设计 ──→ 审查 ──→ 验证 ──→ 验收 ⇄ 迭代
DUT     Review    VPlan   Sign-off 按归因
Agent   Agent    +VDebug   Agent   分配
  ↑              │                  │
  └── 阻塞性不一致 ┘                  ↓ 全 PASS
                                 lab 关闭
```

1. **设计阶段**（DUT Agent）
   - 根据 spec 实现 RTL，撰写 `design-prompt.md`，提供最小验证 TB
   - **出口**：`make comp` 0 error；用户执行 `make run` 确认基本功能
   - **交付物**：RTL 文件、comp.log、run.log
   - **feature-matrix**：目标行实现状态 → #DONE

2. **审查阶段**（Review Agent）
   - 检查 RTL 实现与 spec 的一致性，结果记入 `log.md`
   - **出口**：无阻塞性不一致 → 进入验证；有阻塞性不一致 → handoff 回 DUT Agent 修复后重审

3. **验证阶段**（VPlan Agent；失败分析由 VDebug Agent 协助）
   - 先写 `testplan.md`，再实现 TB 代码，用户执行 `make run` 运行全部用例
   - **出口**：testplan 中 P0 用例全 PASS
   - **feature-matrix**：TB 状态列 → #DONE；验证通过的行 → #VERIFIED

4. **验收阶段**（Sign-off Agent）
   - 按 `acceptance.md` 逐项判定 PASS/FAIL，验收结论记入 `log.md`
   - **出口**：全部必做项 PASS → **当前 lab 关闭**；存在 FAIL → 进入迭代

5. **迭代阶段**（按 FAIL 归因分配：RTL 缺陷 → DUT Agent，TB 缺陷 → VPlan Agent）
   - 修复问题、补充回归用例、更新 testplan
   - **出口**：修复完成 → **回到第 4 步重新验收**

> **闭环约束**：迭代阶段不直接关闭 lab，必须经第 4 步验收确认全部 PASS。

# 7 实验日志
`labX/doc/log.md` 按阶段记录：
1. 设计阶段：挑战、权衡决策、对规格的假设
2. 审查阶段：一致性检查结果、不一致项及解决方案
3. 验证阶段：用例设计目标、运行结果、失败分析
4. 验收阶段：关键检查点和验收结论
5. 迭代阶段：循环总结、最终状态、未决风险

**重要**：log.md 以人工阅读和维护为主。新 Agent 进入时只读顶部状态摘要。

# 8 注意事项
- 规格以 `ppa-lite-spec.md` 为准，本文件仅做实施指引
- 不要编辑仿真生成物
- 不要迁移 MCDT 功能规格，仅借鉴验证结构
- 每个 lab 保留最小可复现 testcase
- APB 行为按 SETUP/ACCESS 两阶段规范理解，不靠猜测

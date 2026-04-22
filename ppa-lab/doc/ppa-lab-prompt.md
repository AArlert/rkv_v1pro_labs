# 0 总体准则
## 0.1 目标受众
本文件面向参与本仓库的所有 AI Agent，作为进入工程后的第一参考资料

## 0.2 现状确认
PPA-Lite 规格文档已经完整给出，但 PPA-Lite 的 RTL、TB、UVM 环境、回归脚本目前尚未落地，后续工作需要在本仓库内从零搭建

## 0.3 参考优先级
文件优先级：
1. ppa-lab/doc/CLAUDE.md
2. ppa-lab/doc/ppa-lite-spec.md
3. ppa-lab/doc/ppa-lab-prompt.md
4. ppa-lab/doc/ppa-agent-character.md
5. ppa-lab/labX/doc/ppa-lab-design-prompt.md
6. ppa-lab/labX/doc/log.md

任何新 Agent 开始工作时，建议按以下顺序：
1. 读 CLAUDE.md
2. 读本文件
3. 读 ppa-lab/doc/ppa-lite-spec.md
4. 读 ppa-lab/doc/ppa-agent-character.md，确认自己的角色定位
5. 确认当前 Lab 目标和对应交付物
6. 确认是否已有代码骨架或正在进行的未提交改动
7. 再决定是参考 lecture/ 还是 mcdt-lab/
8. 需要外部知识如 APB 3.0 协议时，按照规范理解，不要靠猜测或照搬别的总线接口

## 0.4 设计侧硬约束
- 遵循 SystemVerilog、UVM 语言规范，保持一致的缩进（1个TAB）和命名风格
- 模块头部注释包含功能描述、端口说明和参数，在末尾不使用中文句号“。”
- PREADY 固定为 1
- APB 写在 ACCESS 阶段生效
- APB 读在 ACCESS 阶段返回 PRDATA
- 保留地址和越界地址返回 PSLVERR=1
- 写 RO 寄存器返回 PSLVERR=1 且无副作用
- CTRL.start 是 W1P，不存储
- IRQ_STA 是 RW1C
- busy=1 期间写 PKT_MEM 必须报错且写入无效
- done 信号在 DONE 态保持为高，直到下一次合法 start 被接受
- length_error、type_error、chk_error 可以同时成立

## 0.5 验证侧硬约束
- 驱动、监视、检查分离，不要把所有判断写进一个 initial 块
- 定向用例优先覆盖规格中的必做场景矩阵
- 随机测试必须可复现，记录 seed
- 出现 mismatch 时要打印输入摘要、期望值、实际值、测试名、seed
- scoreboard 或 checker 必须基于规格建模，不要只做“输出不为 X”的弱检查
- coverage 只在功能稳定后补，不要用 coverage 掩盖基础功能未通的问题

## 0.6 开发环境
Windows + Questasim + Make，在 VS Code 内直接进入现有目录执行 make 完成编译与仿真

## 0.7 开发参考
### 非 UVM 骨架参考
- mcdt-lab/lab1/mcdt_pkg_ref.sv
  - 参考 generator / initiator / monitor / checker 的最小事务级组织方式
- mcdt-lab/lab1/tb.sv
  - 参考时钟复位、interface 例化、test 启动方式
- mcdt-lab/lab1/Makefile
  - 参考最小可运行编译脚本

### UVM 与覆盖率骨架参考
- mcdt-lab/lab3/mcdt_pkg_ref.sv
  - 已具备 uvm_sequence_item、uvm_driver、uvm_monitor、uvm_agent、uvm_scoreboard、coverage component 的参考实现
- mcdt-lab/lab3/Makefile
  - 已展示 UVM 和 coverage 编译/运行参数
- mcdt-lab/lab2/mcdt_pkg.sv
  - 虽非完整 UVM，但已经包含 checker 与 coverage 思路，适合做 Lab2 到 Lab3 的过渡参考

## 0.8 外部知识缺口
本项目的主要缺口不在基本 SV 语法或基础 UVM 组件，而在以下几类工程知识：
- AMBA APB 3.0 基本时序与术语
- 更复杂 DUT 的分层拆解方法，包括 CSR、存储体、状态机与端到端链路的联动分析
- Questa coverage 的查看、merge 与过滤流程
- smoke test、regression、结果汇总与回归闭环的基本工作流

特别说明：仓库内没有 ARM 官方 APB 标准文档，也没有现成 APB agent。涉及 APB 行为时，必须按规范理解 `SETUP/ACCESS` 两阶段，而不是靠猜测或照搬别的总线接口

## 0.9 不建议的做法
- 不建议在 PPA 项目一开始就照抄 MCDT 的整套 UVM 框架
- 不建议先机械地通读完整个 lecture/ 和 mcdt-lab/ 再开始 ppa-lab
- 不建议在规格未吃透前直接写 scoreboard 或 coverage
- 不建议把大量逻辑堆在 ppa_top，顶层应保持薄层连线
- 不建议把 Lab1/2 的缺陷拖到 Lab3 再统一处理

# 1 项目概述
PPA-Lite（APB Packet Processing Accelerator Lite）是一个可编程的数据包加速处理器，基于 APB 3.0 协议总线接口，包含以下核心功能
- APB 从接口和 CSR 寄存器组
- 8×32-bit 双端口同步 SRAM
- 数据包格式检查（长度、类型、头校验）
- 3 态 FSM 处理流程（IDLE→PROCESS→DONE）
- 中断功能和错误标志

/ppa-lab 是本项目的工作目录，可参考 /mcdt-lab 的设计与验证结构，但不直接迁移其功能规格

# 2 分层设计结构
## 2.1 顶层规则（ppa-lab/doc/）
- **ppa-lite-spec.md**：完整的设计规范文档，包含所有模块的详细要求
- **ppa-lab-prompt.md**：总体实验设计完成思路，指导整个项目的实现流程

## 2.2 下层规划（ppa-lab/labx/doc/）
每个实验阶段都有独立的文档，明确该阶段要完成的任务和验收标准：
- **/lab1/doc/**：lab1 相关文档（APB 从接口和 SRAM）
- **/lab2/doc/**：lab2 相关文档（包处理核心 FSM）
- **/lab3/doc/**：lab3 相关文档（顶层集成）
- **/lab4/doc/**：lab4 相关文档（回归测试和覆盖率）

# 3 实验阶段划分
## 3.1 lab1：APB 从接口 + SRAM
**核心任务**
- 实现 APB 3.0 从接口
- 实现 CSR 寄存器组（CTRL/CFG/STATUS/IRQ_EN/IRQ_STA 等）
- 实现 8×32-bit 双端口同步 SRAM
- 实现 PKT_MEM 地址映射(`0x040 ~ 0x05C`)

**验收标准**
1. APB 基础读写时序正确
2. CSR 默认值正确
3. PKT_MEM 写入地址映射正确
4. RES_* 寄存器读通路正确

## 3.2 lab2：包处理核心
**核心任务**
- 实现 3 态 FSM(IDLE→PROCESS→DONE)
- 实现包头解析逻辑
- 实现格式检查算法(长度检查、类型检查、头校验)
- 实现 payload 的 sum 和 XOR 计算

**验收标准**
1. 合法包处理结果正确
2. 长度越界检测正常
3. busy/done 时序正确
4. 类型合法性检查正常
5. 头校验功能正常

## 3.3 lab3：顶层集成
**核心任务**
- 实现 rkv_ppa_top 顶层模块
- 集成三个子模块（apb_slave_if、packet_sram、packet_proc_core）
- 实现端到端驱动序列（从 lab3 开始引入 UVM）
- 测试连续两帧处理能力

**验收标准**
1. 端到端链路完整
2. 连续两帧顺序处理正常
3. STATUS 总线通路正确
4. busy 期间写保护正常（选做）
5. 中断路径闭环（选做）

## 3.4 lab4：回归测试与覆盖率
**核心任务**
- 建立统一入口、可回归、可统计、可答辩的工程形态
  - make smoke
  - make regress
  - make cov
  - testplan 文档
  - result_summary.txt 或等效汇总
  - coverage merge 流程
- 整理全量 testcase
- 运行全量回归测试
- 分析覆盖率并优化
- 生成覆盖率报告

**验收标准**
1. 一键回归通过率 100%
2. 五类覆盖率达标（line/branch/condition/FSM/toggle）
3. testplan 文档完整
4. 覆盖率过滤合规（选做）

# 4 文件命名规范
## 4.1 设计文件
- 顶层文件统一命名：`ppa_top.sv`
- 子模块文件统一命名：`ppa_apb_slave_if.sv`、`ppa_packet_sram.sv`、`ppa_packet_proc_core.sv`
- 公共 package/interface 统一前缀：`ppa_`（示例：`ppa_pkg.sv`、`ppa_apb_if.sv`）

## 4.2 测试文件
- 顶层 testbench：`ppa_tb.sv`
- 定向测试建议命名：`tc_<feature>_<case>.sv`（示例：`tc_apb_basic_rw.sv`）
- UVM 测试建议命名：`ppa_<scenario>_test.sv`（示例：`ppa_smoke_test.sv`）
- testplan 文档统一命名：`testplan.md`

## 4.3 执行文件（make）
- 每个 lab 的仿真入口统一为：`svtb/sim/Makefile`
- 统一目标：`make comp`、`make run`、`make rung`、`make clean`
- Lab4 增强目标：`make smoke`、`make regress`、`make coverage`

## 4.4 文档文件
- 项目级文档放在 `/ppa-lab/doc/`：`CLAUDE.md`、`ppa-lite-spec.md`、`ppa-lab-prompt.md`
- 实验级文档放在 `/ppa-lab/labX/doc/`：`ppa-lab-design-prompt.md`、`testplan.md`、`log.md`
- 项目级复盘与问题记录放在 `/ppa-lab/doc/`：`result_summary.md`

# 5 目录结构规范
`/ppa-lab/` 统一按如下树形组织：

```text
ppa-lab/
├── doc/
│   ├── CLAUDE.md
│   ├── ppa-lite-spec.md
│   └── ppa-lab-prompt.md
├── lab1/
│   ├── doc/
│   │   ├── log.md
│   │   ├── ppa-lab-design-prompt.md
│   │   └── testplan.md
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
│       ├── tb/
│       └── sim/
├── lab3/
│   ├── doc/
│   ├── rtl/
│   │   └── ppa_apb_slave_if.sv
│   │   └── ppa_top.sv
│   │   └── ppa_packet_proc_core.sv
│   │   └── ppa_packet_sram.sv
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

约束说明：
- `work/`、`*.log`、`*.wlf`、`*.qdb`、`*.qpg`、`*.qtl` 属于仿真生成物，不纳入设计交付物
- 各 lab 目录结构保持同构，避免阶段间脚本和路径反复修改
- `CLAUDE.md` 作为行为准则文档，放在 doc/ 目录下供全局参考，不特指某个 lab
- 每个 lab 的设计文档（`ppa-lab-design-prompt.md`）放在对应的 labX/doc/ 目录下，紧邻 `testplan.md` 和 `log.md`，形成完整的设计-验证-记录闭环

# 6 设计要点
## 6.1 APB 3.0
- 严格采用两段式传输：SETUP（`PSEL=1,PENABLE=0`）到 ACCESS（`PSEL=1,PENABLE=1`）
- `PREADY` 固定为 1，无等待状态
- 读写在 ACCESS 阶段生效，其中读传输在 ACCESS 阶段返回 PRDATA，错误访问统一返回 `PSLVERR=1`

## 6.2 系统结构图
- 顶层 `ppa_top` 仅做连线与时钟复位分发，不承载状态逻辑
- M1（`apb_slave_if`）负责 APB+CSR，M2（`packet_sram`）负责存储，M3（`packet_proc_core`）负责算法与状态机

```
                             APB Master    # TB/DUT上层
                                 |
                                 v
                            ┌─────────┐
                            | ppa_top |    # 顶层：薄层连线，无状态逻辑
                            └─────────┘
                              |  |  |      # 统一分发 PCLK/PRESETn 到 M1/M2/M3
                              |  |  |      # 控制下发/状态结果回传(M1 <-> M3)
         ┌────────────────────┘  |  └───────────────────┐
         |                       |                      |
┌──────────────────┐       ┌───────────┐       ┌──────────────────┐
|   apb_slave_if   | 写端口 | pack_sram | 读端口 | packet_proc_core |
|       (M1)       | ────> |   (M2)    | <──── |       (M3)       |
|    APB + CSR     |       | dual-port |       |   FSM + 算法核    |
└──────────────────┘       └───────────┘       └──────────────────┘
         | irq_o                                        | done_O
         └──────────────────────────────────────────────┘
                            (顶层对外引脚)
```

## 6.3 寄存器属性
- 必须区分 `RW`、`RO`、`W1P`、`RW1C` 四类属性
  - `RW`：可读可写；写入后保持新值
  - `RO`：只读；写入返回 `PSLVERR=1`，寄存器值不变
  - `W1P`：写 1 产生单拍脉冲，不存储该值；读回为 0
  - `RW1C`：读出当前状态；写对应位为 1 则清零该位，写 0 无效
- 错误标志（`ERR_FLAG`、`STATUS.error`、`STATUS.format_ok`）在“下一次合法 `start` 被接受”时统一清零

## 6.4 数据包格式
- 头部固定 4 Byte：`pkt_len`、`pkt_type`、`flags`、`hdr_chk`
- `pkt_len` 合法范围 `[4,32]`，`payload_len = pkt_len - 4`
- `pkt_type` 仅允许 one-hot 值：`0x01/0x02/0x04/0x08`，并受 `type_mask` 约束
- `flags` 保留字段（`0x00`）
- `hdr_chk` 定义为前 3 字节的 XOR，合法包需满足 `hdr_chk == (pkt_len ^ pkt_type ^ flags)`

```
字节偏移: 0         1          2        3         4   ...    N-1
        ┌─────────┬──────────┬────────┬─────────┬─────────────┐
        │ pkt_len │ pkt_type │ flags  │ hdr_chk │   payload   │
        └─────────┴──────────┴────────┴─────────┴─────────────┘
           总包长     包类型      保留=0    头校验      有效载荷
```

## 6.5 状态机设计
- M3 使用三态 FSM：`IDLE -> PROCESS -> DONE`
- `start` 仅在 `enable=1` 且 `busy=0` 时接受
- `DONE` 状态保持结果，直到下一次合法 `start` 触发新一轮处理

## 6.6 错误处理
- 错误位包括：`length_error`、`type_error`、`chk_error`
- 三类错误可同时成立，不因某类错误提前中止检查
- `STATUS.error = length_error | type_error | chk_error`，并用于中断条件判定

# 7 仿真环境
## 7.1 EDA 环境
- 推荐环境：Windows + Questasim + GNU Make
- 编译器：`vlog`；仿真器：`vsim`；覆盖率可使用 `-cover` 相关参数

## 7.2 Makefile 目标
- 基础目标：`comp`、`run`、`rung`、`clean`
- 回归目标（Lab4）：`smoke`、`regress`、`coverage`

## 7.3 编译命令
- 典型编译命令：`vlog -work work -sv -timescale=1ns/1ps -l comp.log <design_files> <tb_files>`

## 7.4 仿真命令
- 批处理运行：`vsim -work work <tb_top> -c -do "run -all; quit -f" -l run.log`
- GUI 调试运行：`vsim -work work <tb_top> -i -l run.log`

# 8 验收流程
1. 设计阶段：根据 SPEC 文档实现 RTL 代码，优先保证接口、寄存器和状态机语义正确
2. 校验阶段：检查 RTL 代码设计逻辑是否和 SPEC 文档一致
3. 验证阶段：编写 testcase 并运行仿真，覆盖正常路径、边界条件和错误路径
4. 验收阶段：检查波形和结果，确认 CSR/中断/错误标志与预期一致
5. 迭代阶段：根据反馈修复问题并完善设计，更新 testplan 与回归集合

# 9 实验日志
在 /labX/doc/log.md 中写入 #8 验收流程 规定的每个阶段的执行记录

# 10 注意事项
- 规格优先级以 `ppa-lite-spec.md` 为准，prompt 文档用于实施指引，不替代 SPEC
- 不要编辑仿真生成物（`work/`、`*.wlf`、`*.log` 等）
- 不要将 MCDT 的功能规格直接迁移到 PPA，仅借鉴验证结构与工程组织
- 每个 lab 都应保留最小可复现 testcase，避免只依赖随机回归
- 所有新增目标（`smoke/regress/coverage`）需在 Makefile 中可直接执行并可复现

# 11 每次交付前的最小检查清单
每个 Agent 在提交结果前至少自查：
1. 是否引用了正确规格，而不是从参考工程推断行为
2. 是否只改了当前任务所需文件
3. 是否避开了 work/ 和日志等生成物
4. 是否给出最小验证步骤
5. 是否记录了未决风险或尚未覆盖的场景

# 12 下一步事项
1. 在 `lab1/` 落地最小可运行工程：补齐 `doc/rtl/svtb/{tb,sim}` 目录与基础文件；编写 `ppa_apb_slave_if.sv`、`ppa_packet_sram.sv`
2. 先完成 APB + CSR + PKT_MEM 的 3 条必做 testcase（默认值、地址映射、读通路）
3. 补充统一 Makefile 入口，先实现 `comp/run/rung/clean`，再扩展 `smoke/regress/coverage`
4. 在 `lab4/doc/testplan.md` 建立用例到覆盖点映射，形成可追踪验收清单
# 0 编码规范
- 代码风格：遵循 SystemVerilog、UVM 语言规范，保持一致的缩进（1个TAB）和命名风格
- 注释规范：模块头部注释包含功能描述、端口说明和参数，在末尾不使用中文句号“。”

# 1 项目概述
PPA-Lite（APB Packet Processing Accelerator Lite）是一个可编程的数据包加速处理器，基于 APB 3.0 协议总线接口，包含以下核心功能
- APB 从接口和 CSR 寄存器组
- 8×32-bit 双端口同步 SRAM
- 数据包格式检查（长度、类型、头校验）
- 3 态 FSM 处理流程（IDLE→PROCESS→DONE）
- 中断功能和错误标志

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
- 实现端到端驱动序列
- 测试连续两帧处理能力

**验收标准**
1. 端到端链路完整
2. 连续两帧顺序处理正常
3. STATUS 总线通路正确
4. busy 期间写保护正常（选做）
5. 中断路径闭环（选做）

## 3.4 lab4：回归测试与覆盖率
**核心任务**
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
- 项目级文档放在 `/ppa-lab/doc/`：`AGENTS.md`、`ppa-lite-spec.md`、`ppa-lab-prompt.md`
- 实验级文档放在 `/ppa-lab/labX/doc/`：`ppa-lab-design-prompt.md`、`testplan.md`
- 复盘与问题记录建议命名：`issues.md`、`result_summary.md`

# 5 目录结构规范
`/ppa-lab/` 统一按如下树形组织（Linux `tree` 风格）：

```text
ppa-lab/
├── doc/
│   ├── AGENTS.md
│   ├── ppa-lite-spec.md
│   └── ppa-lab-prompt.md
├── lab1/
│   ├── doc/
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
2. 验证阶段：编写 testcase 并运行仿真，覆盖正常路径、边界条件和错误路径
3. 验收阶段：检查波形和结果，确认 CSR/中断/错误标志与预期一致
4. 迭代阶段：根据反馈修复问题并完善设计，更新 testplan 与回归集合

# 9 注意事项
- 规格优先级以 `ppa-lite-spec.md` 为准，prompt 文档用于实施指引，不替代 SPEC
- 不要编辑仿真生成物（`work/`、`*.wlf`、`*.log` 等）
- 不要将 MCDT 的功能规格直接迁移到 PPA，仅借鉴验证结构与工程组织
- 每个 lab 都应保留最小可复现 testcase，避免只依赖随机回归
- 所有新增目标（`smoke/regress/coverage`）需在 Makefile 中可直接执行并可复现

# 10 下一步事项
1. 在 `lab1/` 落地最小可运行工程：补齐 `doc/rtl/svtb/{tb,sim}` 目录与基础文件；编写 `ppa_apb_slave_if.sv`、`ppa_packet_sram.sv`
2. 先完成 APB + CSR + PKT_MEM 的 3 条必做 testcase（默认值、地址映射、读通路）
3. 补充统一 Makefile 入口，先实现 `comp/run/rung/clean`，再扩展 `smoke/regress/coverage`
4. 在 `lab4/doc/testplan.md` 建立用例到覆盖点映射，形成可追踪验收清单
# RKV_V1PRO_LABS AI Agent Guide

## 1. 目标与适用范围

本文件面向参与本仓库的所有 AI Agent，作为进入工程后的第一参考资料。

本工作区的核心定位不是通用 RTL 仓库，而是一个教学型仓库：

- lecture/ 提供 SystemVerilog 语言与验证基础示例
- mcdt-lab/ 提供参考验证工程与 UVM 演进路径
- ppa-lab/ 对应本学期实际要完成的课程项目 PPA-Lite

当前最重要的事实：PPA-Lite 规格文档已经完整给出，但 PPA-Lite 的 RTL、TB、UVM 环境、回归脚本目前尚未落地，后续工作需要在本仓库内从零搭建。

## 2. 仓库现状

### 2.1 已确认事实

- 根目录 README.md 说明本仓库由课程示例和 MCDT 参考实验组成
- ppa-lab/doc/ppa-lab-prompt.md 是当前项目级 prompt 文件，供参与 PPA 项目的 AI Agent 统一参考
- ppa-lab/doc/ppa-lite-spec.md 是项目级 SPEC 承载文件；若其内容尚未同步完整，则回退到 ppa-lab/实验说明.md 读取详细规格
- ppa-lab/readme.md 明确说明：MCDT 是参考工程，PPA 才是当前学期要完成的实验主线
- ppa-lab/lab1/ 当前为空目录，没有现成起始代码
- 仓库中没有现成 APB BFM、APB agent、APB monitor、APB checker 或 PPA 相关 RTL
- MCDT 参考工程具备从非 UVM 到 UVM、再到 coverage 的完整演进骨架

### 2.2 不应误判的点

- 不要把 mcdt-lab/ 当作 PPA 的规格来源，它只是结构与方法参考
- 不要从 MCDT 行为反推 PPA 设计要求，PPA 行为必须以 ppa-lab/doc/ppa-lite-spec.md 为准；若其内容未同步完整，则回退到 ppa-lab/实验说明.md
- 不要修改 lecture/ 和 mcdt-lab/ 中已有教学示例，除非任务明确要求
- 不要编辑各目录下的 work/、.qdb、.qpg、.qtl、.wlf、comp.log、run.log 等生成物

### 2.3 /ppa-lab 目录规范

为避免后续 Agent 在不同实验阶段随意扩展目录结构，PPA 项目统一采用以下目录规范：

```text
ppa-lab/
  doc/
    ppa-lab-prompt.md
    ppa-lite-spec.md
  lab1/
    doc/
      ppa-lab-design-prompt.md
      testplan.md
    rtl/
      ppa_apb_slave_if.sv
      ppa_packet_sram.sv
    svtb/
      sim/
        Makefile
        work/
        comp.log
        run.log
        vsim.wlf
      tb/
        ppa_tb.sv
  lab2/
    doc/
    rtl/
    svtb/
      sim/
      tb/
  lab3/
    doc/
    rtl/
    svtb/
      sim/
      tb/
  lab4/
    doc/
    rtl/
    svtb/
      sim/
      tb/
```

说明：

- lab2、lab3、lab4 的目录规范与 lab1 一致
- ppa-lab/doc/ 存放项目级 prompt 和 SPEC
- ppa-lab/labX/doc/ 存放当前实验专用 prompt 与 testplan
- ppa-lab/labX/rtl/ 存放当前实验的 DUT 文件
- ppa-lab/labX/svtb/tb/ 存放当前实验的 testbench 源文件
- ppa-lab/labX/svtb/sim/ 存放 Makefile，以及 EDA 编译、仿真时产生的工作目录和日志

### 2.4 PPA-Lite 系统结构图

```text
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

## 3. 资料优先级

当多个资料出现冲突时，按以下优先级处理：

1. ppa-lab/实验说明.md
2. ppa-lab/doc/ppa-lite-spec.md
3. ppa-lab/doc/ppa-lab-prompt.md
4. README.md
5. ppa-lab/readme.md
6. 课程 lecture/ 示例
7. mcdt-lab/ 参考工程

执行原则：

- 规格定义优先看 ppa-lab/doc/ppa-lite-spec.md；若其内容未同步完整，则回退到 ppa-lab/实验说明.md
- 项目目录规范、Agent 协作方式、交付习惯看 ppa-lab/doc/ppa-lab-prompt.md
- 目录理解与课程定位看 README.md
- 代码组织与验证骨架优先参考 mcdt-lab/
- SV 语法、约束随机、接口、OOP、进程控制等语言问题优先回到 lecture/

## 4. 开发环境与构建事实

### 4.1 已知环境

- 主机系统：Windows
- 用户已在本机安装并可直接使用 Questasim、Node、Make
- 用户已能在 VS Code 内直接进入现有目录执行 make 完成编译与仿真

### 4.2 用户当前能力画像

用户并非从零开始，当前能力边界应按以下事实理解：

- 已有 SV、UVM 学习经验，写过 agent、driver、monitor、sequence、scoreboard 等基础组件
- 理解 virtual interface、transaction、phase、factory、field automation 等常见 UVM 概念
- 能熟练使用 SV 进行 RTL coding 和代码分析
- 已在 Linux 虚拟机中使用过 make、VCS、Verdi 进行仿真和 debug
- 当前在本工作区中主要使用 Windows + Questasim + Make 进行开发和验证

当前主要短板不在基本语法，而在以下工程能力：

- 尚未系统学习 AMBA/APB，只具备基础概念
- 不熟悉 coverage 的执行、分析和闭环方法
- 对 smoke test、regression、回归入口和结果汇总缺少系统化实践
- 既有练习中的 DUT 较简单，本项目需要处理多模块、CSR、SRAM、FSM 和端到端链路组合带来的复杂度

### 4.3 当前仓库里已验证的常用构建模式

现有 lecture/ 与 mcdt-lab/ 常用 Make 目标：

- make comp
- make run
- make rung
- make clean

其中：

- mcdt-lab/lab1 使用基础 vlog/vsim 流程
- mcdt-lab/lab3 和 mcdt-lab/lab4 已启用 UVM/coverage 相关编译运行选项

### 4.4 尚未在仓库里现成存在的能力

- make smoke
- make regress
- make cov

注意：PPA 规格文档要求形成统一验收入口，但当前仓库里还没有为 PPA 预先实现这些目标。后续 Agent 可以在新建的 PPA 工程中增加这些目标，但不要错误地声称仓库已经具备。

## 5. 可直接借鉴的学习材料

鉴于用户已经具备一定的 SV/UVM/RTL 基础，下列材料应优先按需回查，而不是要求先全部学习完再开始 PPA-Lite。

### 5.1 SV 基础与建模材料

- lecture/lec1/interface_type.sv
  - 适合参考 interface、transaction struct、interface 内部 task 的组织方式
- lecture/lec1/sv_for_design.sv
  - 适合参考设计侧 SystemVerilog 语法
- lecture/lec3/constrained_random.sv
  - 适合参考约束随机、inline constraint、随机化失败分析
- lecture/lec3/interprocess_sync.sv
  - 适合参考 driver/monitor/test 之间的进程同步思路
- lecture/lec2/class_encapsulation.sv 与 lecture/lec2/class_inheritance.sv
  - 适合补 OOP 基础，为 Lab3 UVM 迁移做准备

### 5.2 非 UVM 骨架参考

- mcdt-lab/lab1/mcdt_pkg_ref.sv
  - 参考 generator / initiator / monitor / checker 的最小事务级组织方式
- mcdt-lab/lab1/tb.sv
  - 参考时钟复位、interface 例化、test 启动方式
- mcdt-lab/lab1/Makefile
  - 参考最小可运行编译脚本

### 5.3 UVM 与覆盖率骨架参考

- mcdt-lab/lab3/mcdt_pkg_ref.sv
  - 已具备 uvm_sequence_item、uvm_driver、uvm_monitor、uvm_agent、uvm_scoreboard、coverage component 的参考实现
- mcdt-lab/lab3/Makefile
  - 已展示 UVM 和 coverage 编译/运行参数
- mcdt-lab/lab2/mcdt_pkg.sv
  - 虽非完整 UVM，但已经包含 checker 与 coverage 思路，适合做 Lab2 到 Lab3 的过渡参考

## 6. 外部知识缺口

本项目的主要缺口不在基本 SV 语法或基础 UVM 组件，而在以下几类工程知识：

- AMBA APB 3.0 基本时序与术语
- 更复杂 DUT 的分层拆解方法，包括 CSR、存储体、状态机与端到端链路的联动分析
- Questa coverage 的查看、merge 与过滤流程
- smoke test、regression、结果汇总与回归闭环的基本工作流

特别说明：仓库内没有 ARM 官方 APB 标准文档，也没有现成 APB agent。涉及 APB 行为时，必须按规范理解 SETUP/ACCESS 两阶段，而不是靠猜测或照搬别的总线接口。

## 7. PPA-Lite 实施总策略

### 7.1 总原则

- 采用第一性原理的学习方式：直接进入 ppa-lab 当前实验，遇到阻塞点再按需回查 lecture/ 或 mcdt-lab/
- 先按 Lab1/Lab2 分模块做通，再做 Lab3 集成，最后做 Lab4 回归与覆盖率闭环
- 先求规格正确，再做抽象升级；不要一开始就把所有内容 UVM 化
- Lab1 和 Lab2 优先建立可调试、可波形观察、可快速失败定位的简单 TB
- Lab3 再引入 UVM 化和标准化 agent/monitor/checker
- 每个阶段都要保留最小可复现 testcase，避免只有随机回归没有定向场景

### 7.2 不建议的做法

- 不建议在 PPA 项目一开始就照抄 MCDT 的整套 UVM 框架
- 不建议先机械地通读完整个 lecture/ 和 mcdt-lab/ 再开始 ppa-lab
- 不建议在规格未吃透前直接写 scoreboard 或 coverage
- 不建议把大量逻辑堆在 ppa_top，顶层应保持薄层连线
- 不建议把 Lab1/2 的缺陷拖到 Lab3 再统一处理

## 8. 推荐学习路径

本项目不采用“先把 lecture 和 mcdt-lab 全学完，再开始 PPA”的线性路线，而采用第一性原理的路径：从当前要交付的 PPA 实验任务出发，只补当前阻塞所需的知识。

### 8.1 第一步：直接进入 ppa-lab

1. 先读 ppa-lab/doc/ppa-lab-prompt.md，明确目录规范、Agent 协作方式和交付习惯
2. 再读 ppa-lab/doc/ppa-lite-spec.md；若内容尚未同步完整，则回退到 ppa-lab/实验说明.md
3. 明确当前 lab 的 DUT 边界、接口、寄存器、状态机和必做 testcase
4. 先搭最小可编译、可仿真、可观察波形的骨架，再逐步补功能

目标：

- 先把当前实验变成一个可执行的工程问题，而不是先做大范围预习

### 8.2 遇到语言或建模细节时，再回查 lecture/

建议按问题类型定向回查：

- interface、clocking、task、transaction struct：lecture/lec1/
- class、封装、继承：lecture/lec2/
- 约束随机、线程控制、进程同步：lecture/lec3/

目标：

- 只补当前 blocker 对应的语言点，不做脱离当前任务的泛读

### 8.3 遇到验证架构或脚本组织问题时，再回查 mcdt-lab/

建议按问题类型定向回查：

- 最小事务级 TB 骨架：mcdt-lab/lab1/
- checker 与 coverage 过渡思路：mcdt-lab/lab2/
- UVM agent、monitor、scoreboard、coverage、Makefile 组织：mcdt-lab/lab3/

目标：

- 借鉴结构与工作流，不借用 MCDT 的功能规格

## 9. 推荐的 PPA 工程落地顺序

### 9.1 Lab1：M1 + M2

目标：完成 apb_slave_if 与 packet_sram，并形成最小可运行 TB。

建议交付物：

- ppa_apb_slave_if.sv
- ppa_packet_sram.sv
- apb_if.sv 或 apb_pkg.sv
- ppa_tb.sv
- svtb/sim/Makefile
- 至少 3 条定向 testcase

Lab1 最低必须覆盖：

- APB 两段式读写时序
- CTRL/CFG/STATUS/RES_* 默认值与读写属性
- PKT_MEM 地址窗口译码
- PKT_MEM 写入路径
- PSLVERR 基础策略

优先验证用例：

- CSR 默认值读取
- 写 CTRL/CFG 后读回
- 向 0x040 到 0x05C 连续写 8 个 word，检查 wr_en/wr_addr/wr_data
- 对 RES_* 输入打桩，检查 APB 读回路径

### 9.2 Lab2：M3

目标：完成 packet_proc_core，先用独立 TB 做算法核验证，不依赖完整 M1/M2。

建议交付物：

- packet_proc_core.sv
- 行为级 packet memory model 或简单数组模型
- 独立 tb_m3.sv
- 结果比对 task 或轻量 checker

Lab2 最低必须覆盖：

- IDLE -> PROCESS -> DONE 状态转换
- busy_o / done_o 时序
- pkt_len 范围检查
- pkt_type 合法性检查
- hdr_chk 检查
- payload sum/xor 计算

优先验证用例：

- 最小合法包
- 最大合法包
- pkt_len 下溢 / 上溢
- 非法 pkt_type
- algo_mode 旁路 hdr_chk
- 连续两帧

### 9.3 Lab3：集成 ppa_top

目标：把 M1、M2、M3 连成完整端到端路径，并开始引入标准化验证结构。

建议交付物：

- ppa_top.sv
- 端到端 APB driver / monitor
- 简单 reference model 或结果预测函数
- 集成 testcase

Lab3 最低必须覆盖：

- 写 packet -> start -> 轮询 done -> 读结果
- 连续两帧顺序处理
- STATUS.busy / STATUS.done 总线通路

Lab3 选做项可逐步补：

- busy 期间写 PKT_MEM 返回 PSLVERR
- IRQ_EN / IRQ_STA / irq_o 完整链路

### 9.4 Lab4：回归与覆盖率闭环

目标：建立统一入口、可回归、可统计、可答辩的工程形态。

建议交付物：

- make smoke
- make regress
- make cov
- testplan 文档
- result_summary.txt 或等效汇总
- coverage merge 流程

Lab4 最低必须覆盖：

- Lab1 到 Lab3 必做场景全纳入回归
- 定向测试与随机测试兼有
- line / branch / condition / FSM / toggle 覆盖率可解释
- 覆盖率过滤有登记，不做无依据过滤

## 10. 推荐目录结构

PPA 项目目录应以实验为单位展开，且各 Lab 保持相同结构。推荐规范如下：

```text
ppa-lab/
  doc/
    ppa-lab-prompt.md
    ppa-lite-spec.md
  lab1/
    doc/
      ppa-lab-design-prompt.md
      testplan.md
    rtl/
      ppa_apb_slave_if.sv
      ppa_packet_sram.sv
    svtb/
      sim/
        Makefile
        work/
        comp.log
        run.log
        vsim.wlf
      tb/
        ppa_tb.sv
  lab2/
    doc/
    rtl/
    svtb/
      sim/
      tb/
  lab3/
    doc/
    rtl/
    svtb/
      sim/
      tb/
  lab4/
    doc/
    rtl/
    svtb/
      sim/
      tb/
```

说明：

- ppa-lab/doc/ 是项目级文档目录
- ppa-lab/labX/doc/ 是当前实验级文档目录
- ppa-lab/labX/rtl/ 存放当前实验的 DUT 文件
- ppa-lab/labX/svtb/tb/ 存放 testbench 源文件
- ppa-lab/labX/svtb/sim/ 存放 Makefile 以及编译、仿真工作目录和日志
- lab2、lab3、lab4 与 lab1 采用同一套目录规范

## 11. 设计侧硬约束

实现 DUT 时，以下行为必须严格以规格为准：

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

## 12. 验证侧硬约束

验证环境至少要具备以下意识：

- 驱动、监视、检查分离，不要把所有判断写进一个 initial 块
- 定向用例优先覆盖规格中的必做场景矩阵
- 随机测试必须可复现，记录 seed
- 出现 mismatch 时要打印输入摘要、期望值、实际值、测试名、seed
- scoreboard 或 checker 必须基于规格建模，不要只做“输出不为 X”的弱检查
- coverage 只在功能稳定后补，不要用 coverage 掩盖基础功能未通的问题

## 13. Agent 角色建议

### 13.1 DUT Agent

职责：

- 编写或修复 RTL
- 对齐寄存器属性、状态机、地址译码、时序语义

输出要求：

- 明确说明改动影响的模块
- 明确说明对应哪条规格
- 提供最小编译/仿真验证命令

### 13.2 Verification Plan Agent

职责：

- 把规格转成 testcase 矩阵、检查点矩阵、覆盖点矩阵
- 维护 testplan 与验收映射

输出要求：

- 每条 testcase 必须写明输入摘要、预期输出、覆盖目标、优先级

### 13.3 Verification Execution Agent

职责：

- 运行 make 目标
- 收集失败日志
- 定位失败是在 driver、checker、reference model 还是 DUT

输出要求：

- 记录命令、目录、seed、失败测试名、首个报错点

### 13.4 Integration Agent

职责：

- 维护 Makefile、目录组织、公共 package、回归入口
- 保证 smoke / regress / cov 的命令体验稳定

输出要求：

- 说明新增目标依赖哪些文件和工具

## 14. 每次交付前的最小检查清单

每个 Agent 在提交结果前至少自查：

1. 是否引用了正确规格，而不是从参考工程推断行为
2. 是否只改了当前任务所需文件
3. 是否避开了 work/ 和日志等生成物
4. 是否给出最小验证步骤
5. 是否记录了未决风险或尚未覆盖的场景

## 15. 新 Agent 进入工程时的推荐动作

任何新 Agent 开始工作时，建议按以下顺序：

1. 先读本文件
2. 读 README.md
3. 读 ppa-lab/doc/ppa-lite-spec.md；若其内容尚未同步完整，则读 ppa-lab/实验说明.md
4. 确认当前 Lab 目标和对应交付物
5. 确认是否已有代码骨架或正在进行的未提交改动
6. 再决定是参考 lecture/ 还是 mcdt-lab/

## 16. 当前阶段结论

截至目前，可以明确给出以下工程判断：

- PPA-Lite 是本仓库后续开发主线
- PPA 规格是完整的，代码不是完整的
- MCDT 参考工程足以提供 TB、UVM、coverage 的结构范式
- PPA 的第一优先级不是“找现成代码”，而是“依据规格，从简单 TB 起步逐步搭建”
- 当前推荐学习路径是 PPA-first：先直接进入 ppa-lab，遇到知识缺口再按需学习 lecture/ 和 mcdt-lab/
- 任何 AI Agent 参与此工程时，都应把“规格优先、分阶段推进、最小验证闭环”作为默认工作方式
# Harness 工程分析：ppa-lab 项目不合理之处

> 本文从 Harness（验证线束/测试骨架）工程的角度，分析 /ppa-lab/ 当前实现中存在的不合理之处。Harness 工程的核心思想是：**统一可复用的 DUT 连接骨架、分层解耦的激励/检查环境、跨 Lab 稳定演进的验证基础设施**。

---

## 1 缺少统一的 Interface / Harness 顶层

### 问题
Lab1 和 Lab2 的 TB 均采用**裸信号直连** DUT 的方式（`logic` 信号逐一声明后手动连到 DUT 端口），没有定义 `interface` 或 `harness` 模块。

### 具体表现
- `lab1/svtb/tb/ppa_tb.sv`：声明了约 30 个独立的 `logic` 信号，然后在 DUT 实例化时逐一按名连线（第 16~54 行信号声明，第 68~111 行实例化）
- `lab2/svtb/tb/ppa_tb.sv`：同样模式，声明约 20 个信号后直连（第 16~44 行信号声明，第 53~73 行实例化）
- 每个 Lab 的 TB 都要重新声明和连接一遍信号，连线冗余且容易出错

### 不合理原因
- **Harness 工程的基本原则**：DUT 的端口绑定应统一封装在 `interface`（如 `ppa_apb_if`）或 `harness` wrapper 中，TB 通过 `virtual interface` 或 modport 与 DUT 交互
- 裸信号直连无法在 Lab 间复用，Lab3 集成时需要再次重写所有连线
- 不利于后续引入 UVM（UVM driver/monitor 需要 virtual interface 句柄）

### 建议
- 定义 `ppa_apb_if.sv`（APB 信号 interface）和 `ppa_ctrl_if.sv`（M1↔M3 控制/状态 interface）
- 在 harness 顶层或 TB 顶层统一例化 interface 并绑定到 DUT
- 后续 Lab 的 TB 只需获取 virtual interface 即可驱动和监控

---

## 2 缺少公共 Package（ppa_pkg）

### 问题
Lab1 和 Lab2 均没有定义 `ppa_pkg.sv`，地址常量、寄存器偏移、包格式参数等分散在各模块内部。

### 具体表现
- `ppa_apb_slave_if.sv`（第 96~108 行）在模块内部用 `localparam` 定义了 12 个地址常量
- `lab1/svtb/tb/ppa_tb.sv` 中直接使用硬编码的地址字面量（如 `12'h000`、`12'h004`），未引用任何共享常量
- `lab2/svtb/tb/ppa_tb.sv` 中也没有引用统一定义的包格式常量
- `ppa_packet_proc_core.sv` 内的 FSM 枚举类型 `state_t` 仅在模块内部定义，无法被 TB 或 checker 复用

### 不合理原因
- 地址常量在 RTL 和 TB 两侧各自维护，一旦 SPEC 变更需要同步修改多处
- FSM 状态枚举无法在 TB 中直接引用，难以编写状态相关的断言或 checker
- 缺少事务级类型定义（如 packet transaction struct），TB 只能用裸数组手工构造激励

### 建议
- 创建 `ppa_pkg.sv`，集中定义地址映射、寄存器位域、FSM 状态枚举、包格式参数
- RTL 和 TB 统一 `import ppa_pkg::*`

---

## 3 TB 中驱动、监控、检查未分离

### 问题
Lab1 和 Lab2 的 TB 均把**激励生成、协议驱动、结果检查**写在同一个 `initial` 块中，违反了 Harness 分层原则。

### 具体表现
- `lab1/svtb/tb/ppa_tb.sv`（第 178~323 行）：一个巨大的 `initial` 块完成所有测试，包含 APB 驱动、SRAM 验证、CSR 读回检查
- `lab2/svtb/tb/ppa_tb.sv`（第 158~461 行）：同样在单个 `initial` 块中完成 7 个测试用例
- `ppa-lab-prompt.md` 第 42 行明确要求"驱动、监视、检查分离"，但实际代码未遵守

### 不合理原因
- 无法独立复用 APB 驱动逻辑（Lab2 不需要 APB 但仍需自己写 SRAM 行为模型驱动）
- 无法插入 protocol checker 或 coverage monitor
- 测试用例与基础设施耦合，新增用例需要复制大量模板代码

### 建议
- 将 APB 驱动封装为独立的 driver class/task（或 module）
- 将结果比对封装为 checker/scoreboard
- 将 SRAM 行为模型提取为可复用 component
- 测试用例仅描述高层意图（写什么包、期望什么结果），不关心底层协议时序

---

## 4 RTL 文件跨 Lab 复制而非共享

### 问题
按 `ppa-lab-prompt.md` 第 193~237 行的目录结构规划，Lab3 需要将 `ppa_apb_slave_if.sv`、`ppa_packet_sram.sv`、`ppa_packet_proc_core.sv` 全部**再复制**一份到 `lab3/rtl/` 下。

### 具体表现
- Lab1 的 `ppa_apb_slave_if.sv` 和 Lab3 的 `ppa_apb_slave_if.sv` 将是两份独立文件
- 如果 Lab2 阶段发现 M1 有 bug 需要修复，Lab1 和 Lab3 的文件需要分别修改
- 没有 RTL 共享目录或符号链接机制

### 不合理原因
- Harness 工程强调**单一数据源（Single Source of Truth）**：同一个 RTL 模块在整个项目中应只有一份规范实现
- 文件复制导致版本分叉，增加维护成本和一致性风险

### 建议
- 建立 `ppa-lab/rtl/` 公共 RTL 目录，所有 Lab 的 Makefile 从公共目录引用设计文件
- 各 Lab 的 `labX/rtl/` 仅存放该 Lab 新增或实验性修改的文件（如有需要）
- 或者使用 Makefile 变量统一管理 RTL 文件路径

---

## 5 Makefile 缺乏文件列表管理和依赖跟踪

### 问题
Lab1 和 Lab2 的 Makefile 使用硬编码的文件路径，没有 filelist 机制。

### 具体表现
- `lab1/svtb/sim/Makefile`（第 9~10 行）：`DFILES` 写死了两个 RTL 文件的相对路径
- `lab2/svtb/sim/Makefile`（第 9 行）：`DFILES` 写死了一个 RTL 文件
- 没有 `.f` 文件（filelist）来管理编译顺序和文件依赖
- Lab3 集成时需要重新组织所有文件路径

### 不合理原因
- 随着 Lab 演进，文件数量增加，硬编码路径难以维护
- 缺少 filelist 导致无法在不同 Lab 之间共享编译配置
- 没有增量编译支持（每次 `make comp` 都全量重编）

### 建议
- 引入 `rtl.f` 和 `tb.f` 文件列表，Makefile 通过 `-f rtl.f` 引用
- 公共 filelist 放在 `ppa-lab/` 根目录或 `ppa-lab/sim/` 公共目录
- 各 Lab 按需 include 公共 filelist 并追加本 Lab 特有文件

---

## 6 Lab2 TB 的 SRAM 行为模型未复用 M2 RTL

### 问题
Lab2 的 TB 自行实现了一个 SRAM 行为模型（`sram_model` 数组 + `always_ff` 同步读），而不是复用 Lab1 已验证通过的 `ppa_packet_sram` 模块。

### 具体表现
- `lab2/svtb/tb/ppa_tb.sv`（第 78~85 行）：用 SV 数组和 `always_ff` 重新实现了同步读逻辑
- `lab2/svtb/sim/Makefile`（第 9 行）：编译列表中只包含 `ppa_packet_proc_core.sv`，不含 `ppa_packet_sram.sv`

### 不合理原因
- 行为模型与真实 RTL 可能存在时序或功能差异，导致 Lab2 通过但 Lab3 集成时出现问题
- Harness 工程鼓励复用已验证的组件，而非重复实现
- 如果 M2 的接口或行为在后续修改，行为模型不会同步更新

### 建议
- Lab2 的 TB 直接例化 `ppa_packet_sram`，通过 task 写入 SRAM 数据
- 或至少在 Makefile 中同时编译 `ppa_packet_sram.sv` 并在 TB 中例化，保证 M3 测试的 SRAM 行为与真实硬件一致

---

## 7 缺少断言（SVA）和协议检查器

### 问题
Lab1 和 Lab2 的 RTL 和 TB 中均没有任何 SystemVerilog Assertion（SVA）。

### 具体表现
- `ppa_apb_slave_if.sv`：无 APB 协议合规性断言（如 PSEL/PENABLE 时序约束）
- `ppa_packet_proc_core.sv`：无 FSM 非法状态断言、无 busy/done 互斥断言
- TB 中仅通过 `check` task 做事后比对，没有实时协议监控

### 不合理原因
- Harness 工程的重要组成部分是**嵌入式协议检查器**（protocol checker），通常以 SVA bind 的形式绑定到 DUT
- 缺少 SVA 意味着协议违规只能在特定测试序列下被偶然发现，无法被系统性捕获
- APB 作为标准总线协议，其基本时序约束（如 PSEL 先于 PENABLE 拉高、地址在 ACCESS 阶段保持稳定等）应作为 assertion 永久存在

### 建议
- 创建 `ppa_apb_protocol_checker.sv`，包含 APB 协议基本断言，bind 到 M1
- 创建 `ppa_fsm_checker.sv`，包含 FSM 状态转移合法性断言，bind 到 M3
- 这些 checker 是 harness 的一部分，所有 Lab 和所有用例自动生效

---

## 8 测试用例与 TB 骨架耦合，无法独立管理

### 问题
所有测试用例（TC1~TC7）都硬编码在 `ppa_tb.sv` 的 `initial` 块中，无法独立选择、跳过或扩展。

### 具体表现
- Lab1 的 `ppa_tb.sv` 包含 3 个 TC，Lab2 包含 7+ 个 TC，全部串行写死在 `initial` 块
- 没有 test selector 机制（如 `+UVM_TESTNAME` 或 `+TEST_ID`）
- 无法单独运行某一个 TC 进行调试，必须跑完所有用例
- `ppa-lab-prompt.md` 第 177~179 行建议 `tc_<feature>_<case>.sv` 的命名规范，但未实际使用

### 不合理原因
- 调试效率低：修改一个场景需要等待所有前置用例执行完毕
- 不利于回归管理：Lab4 的 `make regress` 需要能独立调度每个用例
- 增加测试时需要修改已有的 TB 文件，风险高

### 建议
- 将每个 TC 提取为独立的 test file 或 test class
- TB 骨架仅负责 harness（DUT 例化、时钟复位、interface 连接）
- 通过 Makefile 参数或 plusargs 选择运行哪个测试

---

## 9 TC2（PKT_MEM 写入）检查不充分——依赖波形而非自动化比对

### 问题
Lab1 的 TC2 写入 8 个 SRAM word 后，仅打印 `[INFO]` 提示用户检查波形，没有自动化验证。

### 具体表现
- `lab1/svtb/tb/ppa_tb.sv`（第 261~272 行）：SRAM 读操作已执行，但没有对 `sram_rd_data` 进行自动比对
- 直接打印 `[PASS] TC2`（第 271~272 行），实际上没有任何检查逻辑
- pass_cnt 被无条件递增，掩盖了潜在问题

### 不合理原因
- 违反 Harness 工程的自动化原则：所有检查必须可自动判定 PASS/FAIL
- 回归测试无法包含需要人工看波形的用例
- 虚假的 PASS 会误导覆盖率统计

### 建议
- 在 SRAM 读出后逐 word 与预期值自动比对
- 所有 TC 必须有明确的自动化 PASS/FAIL 判定

---

## 10 缺少 Timeout / Watchdog 和全局错误捕获

### 问题
Lab1 TB 没有全局超时保护；Lab2 TB 的 `wait_done` 虽有 timeout 参数，但超时后仅打印 ERROR 并继续执行后续检查，可能导致级联误报。

### 具体表现
- `lab1/svtb/tb/ppa_tb.sv`：无任何超时机制，若 DUT 挂死仿真将无限运行
- `lab2/svtb/tb/ppa_tb.sv`（第 122~130 行）：`wait_done` 超时后打印 ERROR 但不 `$finish`，后续 check 会在错误状态下继续执行

### 不合理原因
- Harness 骨架应包含全局 watchdog（如 `initial begin #MAX_TIME; $fatal("Simulation timeout"); end`）
- 超时后继续运行会产生大量误报，掩盖真正的根因

### 建议
- 在 TB harness 层添加全局 watchdog timer
- `wait_done` 超时后应 `$fatal` 或跳过当前 TC 的后续检查

---

## 总结

| # | 问题 | 严重程度 | 影响阶段 |
|---|------|----------|----------|
| 1 | 缺少 interface / harness 顶层 | 高 | Lab3 集成、UVM 迁移 |
| 2 | 缺少公共 ppa_pkg | 中 | 全 Lab |
| 3 | 驱动/监控/检查未分离 | 高 | 全 Lab，尤其 Lab4 回归 |
| 4 | RTL 跨 Lab 复制 | 中 | Lab3 集成 |
| 5 | Makefile 无 filelist 管理 | 低 | Lab3/Lab4 |
| 6 | Lab2 未复用 M2 RTL | 中 | Lab3 集成 |
| 7 | 缺少 SVA 协议检查器 | 中 | 全 Lab |
| 8 | TC 与 TB 骨架耦合 | 高 | Lab4 回归 |
| 9 | TC2 检查依赖波形 | 中 | Lab4 回归 |
| 10 | 缺少 watchdog/全局保护 | 中 | 全 Lab |

以上问题在当前 Lab1/Lab2 的单模块验证阶段或许影响不大，但随着 Lab3 集成和 Lab4 回归阶段的到来，**缺少统一的 harness 层**将成为工程效率和质量的主要瓶颈。建议在进入 Lab3 之前，优先建立 interface + harness + pkg 的基础骨架，为后续 UVM 迁移和回归闭环打好地基。

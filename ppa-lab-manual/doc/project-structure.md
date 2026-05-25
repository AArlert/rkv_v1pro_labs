# project-structure — 企业级 UVM 验证工程文件夹结构与本项目映射

> 解答两件事：
> 1. 一个 **常见企业级 UVM 验证工程** 长什么样
> 2. 针对 PPA-Lite spec，本项目（`ppa-lab-manual/`）如何 **裁剪/适配** 这套标准结构

---

## 1 常见企业级 UVM 验证工程文件夹结构

下面给出一个典型 IC 公司 IP/子系统级 UVM 验证工程的目录布局（去掉公司专有 flow 后的"最大公约数"）：

```
<project_root>/
├── docs/                       # 规格 + 文档（spec / micro-arch / verification-plan）
│   ├── spec/
│   ├── uarch/
│   ├── verification-plan/
│   └── review/                 # 设计/代码评审记录
│
├── rtl/                        # 设计 RTL（不属于 DV，常常是另一个 git submodule）
│   ├── <ip_top>.sv
│   ├── <submodules>/*.sv
│   └── include/                # 公共 header / parameter pkg
│
├── verif/                      # —— 验证根 ——
│   ├── tb/                     # 顶层 testbench（HDL top + DUT 例化 + 接口绑定）
│   │   ├── tb_top.sv
│   │   └── hdl_top.sv          # （有的项目把 clk/rst 生成放这里）
│   │
│   ├── env/                    # UVM 环境层：env / scoreboard / coverage
│   │   ├── <ip>_env.sv
│   │   ├── <ip>_env_pkg.sv
│   │   ├── <ip>_scoreboard.sv
│   │   └── <ip>_coverage.sv
│   │
│   ├── agents/                 # 协议级 UVM agents（每个协议一个目录）
│   │   ├── apb_agent/
│   │   │   ├── apb_if.sv
│   │   │   ├── apb_pkg.sv
│   │   │   ├── apb_driver.sv
│   │   │   ├── apb_monitor.sv
│   │   │   ├── apb_sequencer.sv
│   │   │   └── apb_agent.sv
│   │   └── <other_agent>/
│   │
│   ├── sequences/              # virtual seq + module seq
│   │   ├── <ip>_base_seq.sv
│   │   ├── <ip>_smoke_seq.sv
│   │   └── <ip>_random_seq.sv
│   │
│   ├── tests/                  # UVM tests（每个 testcase 一个 .sv）
│   │   ├── <ip>_base_test.sv
│   │   ├── <ip>_smoke_test.sv
│   │   ├── <ip>_<feature>_test.sv
│   │   └── ...
│   │
│   ├── ref_model/              # reference model（C/SV/Python 任意，独立实现）
│   ├── common/                 # 跨 agent 的 pkg / typedef / utility
│   └── assertions/             # SVA / property 文件（有时合入 rtl/）
│
├── sim/                        # 仿真运行目录：Makefile / filelist / 脚本
│   ├── Makefile
│   ├── filelist.f
│   ├── regress/                # 回归列表（list 文件 + python launcher）
│   └── waves/                  # 波形 dump 落点（gitignore）
│
├── coverage/                   # 覆盖率配置 + ucdb 归档
│   ├── covergroup_config.cfg
│   ├── exclusion.do
│   └── reports/
│
├── scripts/                    # 通用脚本（regress / triage / merge）
│   ├── run_regress.py
│   └── merge_cov.sh
│
└── lint/                       # Spyglass / Verible / 等 lint 配置
    └── spyglass/
```

### 关键约定（业界共识）

1. **rtl/ 与 verif/ 完全隔离**：DV 工程师不改 rtl，遇到问题走 fix-request 流程
2. **agent 是协议级而不是模块级**：APB agent 在任何用到 APB 的项目里都能复用
3. **每个 .sv 都属于一个 `*_pkg.sv`**：用 `import` 而不是 `` `include`` 链
4. **sim/ 只放运行入口与产物**：编译/运行/波形/log 都在这里产生，方便 .gitignore
5. **覆盖率与 lint 各自独立目录**：不与功能仿真混杂

---

## 2 本项目（`ppa-lab-manual/`）的适配

### 2.1 适配原则

PPA-Lite 是 **教学 IP**，体量小（3 个 RTL 模块 + 1 个顶层 + 4 次实验渐进），不必拉满工业结构。我们做 3 件事：

1. **保留** `rtl / verif/{tb,env,agents,sequences,tests,ref_model,common} / sim` 主干 —— 让学生看到企业目录的标准形状
2. **下沉到每个 lab**：每个 `labN/` 内部各有一份完整的 `rtl + verif + sim`（lab 之间天然隔离），方便阶段性独立交付
3. **省略** 业界通用但 PPA-Lite 用不上的目录：
   - 无独立 `docs/uarch/`（spec 已经够细，design-note 放 `labN/doc/`）
   - 无独立 `lint/` `coverage/` `scripts/`（lab4 才需要，集中到 `lab4/sim/`）
   - `assertions/` 暂不强制（学生进度允许时合入 `verif/tb/`）

### 2.2 顶层与 lab 的两级布局

```
ppa-lab-manual/                ← 项目级（spec / 工作流 / REV / skill）
├── doc/                       ← 业界 docs/ 的精简版
├── agent/  skill/             ← 本项目特有（AI 审查闭环）
├── review_report 在 doc/      ← 业界 docs/review/ 的强化版（结构化报告）
│
└── labN/                      ← 每 lab = 一个最小但完整的 verif 工程
    ├── doc/                   ← 业界 docs/verification-plan/ 的 lab 切片
    │   ├── design-note.md
    │   ├── testplan.md
    │   └── progress.md
    ├── rtl/                   ← 该 lab 涉及的模块
    ├── verif/
    │   ├── tb/                ← 顶层 TB（lab1/2/3 用 SV TB，lab4 切到 UVM）
    │   ├── env/               ← UVM env（lab1–3 占位；lab4 完整）
    │   ├── agents/apb_agent/  ← APB agent（lab1 起逐步成型，lab4 完整）
    │   ├── sequences/         ← lab1 起逐步引入
    │   ├── tests/             ← lab1 起逐步引入
    │   ├── ref_model/         ← packet ref model（lab2 起需要）
    │   └── common/            ← typedef / register map pkg
    └── sim/                   ← Makefile + filelist + waves
```

### 2.3 lab × spec 模块映射

| Lab | RTL 模块（来自 spec §2） | verif/agents | verif/ref_model | sim 目标 |
|---|---|---|---|---|
| **lab1** | `apb_slave_if` (M1) + `packet_sram` (M2) | apb_agent v0.1（driver+monitor） | 寄存器 shadow（python 或 SV class） | `make smoke` / `make wave` |
| **lab2** | `packet_proc_core` (M3) | （沿用 lab1 apb_agent，stub 化 SRAM） | packet parser ref model（独立实现，**不引用 RTL 内部信号**） | `make smoke` |
| **lab3** | `ppa_top` 集成 | apb_agent + irq_monitor | packet 端到端 ref model | `make smoke` / `make regress` |
| **lab4** | （沿用） | 完整 apb_agent / virtual sequencer | 完整 ref model + scoreboard | `make regress` / `make cov` |

### 2.4 学生眼里的"目录使用顺序"

```
doc/spec → labN/doc/design-note.md → labN/rtl/*.sv （手写）
                                          │
                                          ▼ Copilot 补齐细节
                                  labN/verif/tb/tb_top.sv （手写）
                                  labN/verif/sequences/*.sv （Copilot 补齐）
                                          │
                                          ▼ make smoke
                                  labN/sim/<*.log, *.fsdb>
                                          │
                                          ▼ 调 REV
                                  doc/review_report/<date>-lab<N>-<phase>-<target>.md
```

### 2.5 为什么 `review_report/` 放在 **顶层** `doc/` 而不是每 lab？

- 用户明确要求："每一次调用都不会删除上一次的报告，每一次 md 报告对应具体的 labX 和进度"
- 顶层集中后：
  - 单一目录天然按时间排序 = 项目级"病历卷宗"
  - 文件名内嵌 `lab<N>-<phase>` 既保留 lab 维度，又支持跨 lab 横向对比
  - REV agent 实现简单：只读/写一个目录，无需扫各 lab
- 与业界对照：相当于把 `docs/review/` 升级成"结构化、永不覆盖、文件名即索引"的版本

---

## 3 命名约定速查

| 类别 | 约定 | 例 |
|---|---|---|
| RTL 文件 | `<module>.sv`（snake_case，与 spec §2.2 模块名严格一致） | `apb_slave_if.sv` |
| SV pkg | `<scope>_pkg.sv` | `ppa_common_pkg.sv` |
| UVM agent 文件 | `<proto>_<role>.sv` | `apb_driver.sv` |
| UVM test | `<feature>_test.sv` | `csr_default_test.sv` |
| REV 报告 | `<YYYYMMDD>-<HHMM>-lab<N>-<phase>-<target>.md` | `20260415-1430-lab1-design-rtl-apb_slave_if.md` |
| Makefile target | `smoke / regress / cov / wave / lint`（与 spec §1.4 一致） | `make smoke` |

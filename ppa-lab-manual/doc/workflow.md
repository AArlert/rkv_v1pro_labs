# workflow — 手动 + Copilot 补齐 + REV 审查

> 本项目唯一工作流。不像 `ppa-lab-copilot` 有多 agent 调度，这里 **人是主角**，Copilot 与 REV 都是辅助。

## 1 三方角色

| 角色 | 谁来扮演 | 输入 | 输出 |
|---|---|---|---|
| **设计/验证者** | 学生本人 | spec + design-note + 经验 | RTL 骨架、TB 骨架、关键算法手写 |
| **Copilot** | IDE 内联补全 / Chat | 已有骨架 + 注释 | 端口列表展开、case 分支补齐、模板套用 |
| **REV** | 本项目唯一 agent | RTL/TB/log/spec | `doc/review_report/*.md`（四段式报告） |

## 2 一个 lab 的标准节奏

### 阶段 D — Design（设计）

1. 学生读 `doc/ppa-lite-spec.md` 对应章节 + `labN/doc/design-note.md`
2. **学生手写** `labN/rtl/<module>.sv` 的：
   - 模块名 + 端口表（必须与 spec §2.3 100% 对齐，名称/方向/位宽）
   - FSM 状态定义 / CSR 偏移定义 / 关键 always 块的"骨架与意图注释"
3. **Copilot 补齐**：
   - 重复性 always_ff 模板
   - case 分支的剩余项
   - 端口连线 / wire 声明 / 默认值
4. 学生通读、调整、确认无 latch / 无 multi-driver 等基础问题
5. **触发 REV**（target = `rtl-<module>`，phase = `design`）

### 阶段 V — Verify（验证）

1. 学生读 `labN/doc/testplan.md`，手写 `labN/verif/tb/tb_top.sv`：
   - 时钟/复位生成、DUT 例化、接口绑定
   - 至少 1 个自检的 smoke testcase
2. **Copilot 补齐**：
   - APB write/read task 模板
   - 其余 testcase 的 stimulus 部分
   - assert/scoreboard 中比较语句
3. `cd labN/sim && make smoke`，看 log
4. **触发 REV**（target = `tb`，phase = `tb`）

### 阶段 I — Integrate（lab3 起）

1. 端到端连接、连续两帧、IRQ 路径
2. **触发 REV**（target = `full`，phase = `integration`）

### 阶段 R — Regression（lab4）

1. `make regress` + `make cov`
2. **触发 REV**（target = `full`，phase = `regression`）

## 3 REV 触发方式

### 3.1 按需触发（学生主动）

在 `labN/doc/progress.md` 末尾追加一行：

```
>>> CALL REV @<YYYY-MM-DD HH:MM> on <target> phase=<phase>
```

然后调用 REV agent（IDE 内、Copilot Chat 中、或 CLI），REV 读到这行后开始审查。

### 3.2 阶段闭合强制触发

每个 lab 阶段（D/V/I/R）关闭之前必须至少 1 次 REV 报告无 P0，才允许在 `doc/progress.md` 把该阶段标记为 ✅。

## 4 REV 报告四段式（本项目特色）

REV 输出的每份报告以 **bug 视角** 组织，而不是按 P0/P1/P2 优先级。这是 user 明确要求："bug 从哪里来、怎么解决、为什么、怎么做"。

| 段 | 内容 | 引用要求 |
|---|---|---|
| **① Where（从哪来）** | bug 出现的文件/行号 + 触发场景 | `file:line` + 波形/log 时刻 |
| **② How-to-fix（怎么解决）** | 一句话给修法（不直接改代码） | 给出具体的修改位置（不要"建议优化"这种空话）|
| **③ Why（为什么）** | 这个 bug 违反了 spec 的哪一条、产生的根因 | spec §X.Y / design-note §Z |
| **④ How-it-was-done（怎么做的）** | 学生当时**这么写**的可能心路（误解了什么、漏看了哪段 spec） | 引可疑的注释或骨架，帮学生下次避坑 |

详细模板见 [`agent/review.md`](../agent/review.md) "Output Format" 节。

## 5 报告命名与归档（顶层 `doc/review_report/`）

```
doc/review_report/
├── README.md
├── 20260415-1430-lab1-design-rtl-apb_slave_if.md
├── 20260415-1612-lab1-tb-tb.md
├── 20260418-0930-lab1-design-rtl-apb_slave_if.md   ← 第二次审同一对象，新文件
├── 20260502-1100-lab2-design-rtl-packet_proc_core.md
└── ...
```

- 文件名格式：`<YYYYMMDD>-<HHMM>-lab<N>-<phase>-<target>.md`
- 永不覆盖既有文件；目录按文件名时间排序天然成索引
- 同一 `<labN, phase, target>` 三元组重复审查 → 时间戳不同 = 不同文件

## 6 进度看板规则

- 全项目：[`doc/progress.md`](progress.md)（lab 维度勾选）
- 每 lab：`labN/doc/progress.md`（D/V/I/R 阶段维度勾选 + 关联报告文件名）

## 7 与 spec 的强约束

- spec 是 **immutable ground truth**，任何 RTL 端口/CSR 偏移/FSM 转移与 spec 不一致 → REV 强制 P0
- REV 调用 `review-spec-alignment` skill 做端口/CSR/FSM 三轴严格对齐检查（这是与 `ppa-lab-copilot` 同款规则）

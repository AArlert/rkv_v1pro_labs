# PPA-Lab-Copilot 工作流 v6（拆解版）

> **本文档只承担"工作流维护"职责**——记录 v5 → v6 的设计决策、边界规则、迁移清单。
> 日常干活**不需要读本文**；要读的是 `doc/`、`agents/`、`skill/`、`template/`、`memory/`。

---

## 1 v6 的核心转变

v5 把所有约定塞进 `workflow-v5.md` 一篇（文件树、6 套模板、agent 形态、Skill 矩阵…）。问题：

- 干活时谁也不会回头去读 workflow.md
- 模板内联在 workflow 里，修改要先翻几百行才找到
- 文件树和 outlook 看板重复维护

**v6 把内容**按"用的人"和"读的频次"**拆到项目内**：

| 内容 | v5 位置 | v6 位置 | 谁读 |
|---|---|---|---|
| 项目完整文件树 | workflow-v5 §3 | `doc/ppa-outlook.htm` 新章 + `doc/ppa-plan.md` §1.3 | 人（每次浏览） |
| 6 套模板 | workflow-v5 §7 内联 | `template/*.md` 单独小文件 | 任意角色（每次写文档） |
| Skill × Agent 矩阵 | workflow-v5 §4 | `agents/README.md` + `skill/README.md` Consumers 列 | ARCH/RTL/DV/REV 起手 |
| state.md schema | workflow-v5 §5 | `memory/README.md` + state.md 内注释 | ORCH / outlook 解析器 |
| 两层纠错 / REV 双触发 | workflow-v5 §6 | 各 agent .md 的 Inner/Outer Loop + `agents/README.md` | 各角色 |
| Lab1–4 实验拆解（人用） | 散落 | `doc/ppa-plan.md`（v6 蒸馏版） | 人 |
| EDA 工具版本 | workflow-v5 §1 | 各 agent .md `## Tool Options` + `doc/ppa-plan.md` §4.1 | 用到 EDA 的角色 |

---

## 2 v6 主要变更

### 2.1 REV 工具权限放宽（本机有 EDA 许可）

- **v5**：REV 不直接跑 EDA，只消费 RTL/DV 留下的 log/fsdb 和 Spyglass `.rpt`。
- **v6**：REV 可经 **make target** 在本机触发 VCS / Verdi / Spyglass / xwave / xtrace，自行产报告 → 分析。
- 约束（写进 `agents/reviewer.md`）：
  1. 只通过 `make <target>` 触发，不手敲 `vcs`/`verdi`/`spyglass` 命令——保证可复现
  2. 产物必须落到约定路径（`svtb/sim/`、`svtb/spyglass_reports/`、`svtb/wave/`）
  3. 每个跑过的 target 在 review report 的 `Evidence used → make` 段登记
  4. 不能改 Makefile（要新 target 走"按需调 RTL/DV"）

### 2.2 template/ 目录化

- 新建 `template/` 共 9 个小文件，每个 ≤ 30 行
- 各 agent .md 把内联模板改为"Use `template/<file>.md`"指针
- 模板与 workflow 文档**互不重叠**：template 只放样板，workflow 解释为什么

### 2.3 `doc/ppa-plan.md` 蒸馏

- 删掉与 workflow/agents/memory 重复的 §1.2 / §1.4–1.5 / §2 整章
- 保留并强化人用部分：§0 阅读说明、§1 框图+骨架（含 v5/v6 完整文件树）、§3 学习+AI 纪律、§4 第 0 周、§5–8 Lab1–4 拆解、§10 答辩、§11 何时参考 /ppa-lab/、§12 风险与避坑
- 措辞从 v3/v4 旧名（`design_state.json` / `fix_request`）改 v6（`memory/state.md` / `## RISKs`）

### 2.4 outlook.htm 增"项目文件结构"章节

- v5 §3 整棵树搬过来，作为浏览入口（不再让人去 workflow-vX.md 找）
- 顺手把 §3 的"5 个角色"卡片、§5 的"仓库目录速览"、§7 的"AI 调用约束"按 v6 名字校准

---

## 3 边界规则（谁的内容放在哪）

| 文档 | 职责 | **不**放什么 |
|---|---|---|
| `workflow-vX.md` | 工作流维护：版本差异、设计决策、迁移清单 | 文件树、模板正文、Lab 计划、skill 卡片正文 |
| `doc/ppa-plan.md` | 人用学习/实验书：8 周怎么干 | 工作流维护、agent 规约、模板正文 |
| `doc/ppa-outlook.htm` | 浏览入口 + 实时状态看板 + 文件结构图 | 模板正文、Lab 任务清单 |
| `doc/ppa-lite-spec.md` | 权威 spec | 任何工程决策（spec 不改） |
| `agents/<role>.md` | 干活指令：Inputs/Outputs/Loop/Sign-off | 模板正文（指向 template/）、知识细节（指向 skill/） |
| `skill/<name>/SKILL.md` | 知识卡片：when_to_use / how_to_use / example | 工作流约束、模板 |
| `template/<file>.md` | 复制即用样板 | "为什么" 的解释（写到 workflow-vX.md） |
| `memory/state.md` | 单一状态源 | 长篇 narrative（写到 experiences.md） |
| `memory/<domain>/{knowledge,experiences}.md` | 角色经验 / 蒸馏 | 当前状态（state.md 已是单源） |

---

## 4 v5 → v6 迁移速查

| 维度 | v5 | v6 |
|---|---|---|
| 完整文件树位置 | workflow-v5 §3 | `doc/ppa-outlook.htm` 新章 + `doc/ppa-plan.md` §1.3（双处指向同一棵树，因 outlook 是 HTML 看板） |
| 模板存放 | workflow-v5 §7 内联 | `template/*.md` 9 个小文件 |
| REV 跑 EDA | 禁，只读 RTL/DV 产物 | **允许**，但只能经 make target |
| ppa-plan.md | 781 行混合内容（人用计划 + 重复 workflow 约定） | 蒸馏为人用计划，去除与 workflow/agents/memory 重复段 |
| 各 agent .md 模板段 | 内联 markdown 块 | 一行 "Use `template/<file>.md`" |
| Skill 矩阵 / 心法 / state schema / 两层纠错 / REV 触发 | workflow-v5 §4/§2/§5/§6 | 散到 agents/README.md + skill/README.md + memory/README.md + 各 agent .md（每处只 1 份） |

---

## 5 v6 落地清单

- [x] 新建 `template/` 与 9 个模板小文件 + `template/README.md`
- [x] 新建本文档 `workflow-v6.md`（精简版，无内联）
- [x] 重写 `doc/ppa-plan.md`：v6 蒸馏版，含完整文件树，删 §1.2/§1.4-1.5/§2/§9 重复段
- [x] 改 `doc/ppa-outlook.htm`：顶部链接 v6 + 新增"项目文件结构"章节 + 文案 v6 化（`design_state.json`→`state.md` 等）
- [x] 改 `agents/reviewer.md`：REV-EDA 权限放宽 + 指向 template/
- [x] 改 `agents/orchestrator.md` / `architect.md` / `rtl-designer.md` / `dv-engineer.md`：内联模板段 → 指向 template/
- [x] 改 `agents/README.md`、`skill/README.md`、`memory/README.md` → v6 引用
- [x] 改 `memory/state.md` Meta.workflow → `workflow-v6.md` + History +1 + Cursor.last/next 同步

## 6 不变项（不重述）

- 5 角色（ORCH/ARCH/RTL/DV/REV）、spec 不可改、state.md 单源、`## RISKs` 内嵌、REV 报告独立文件归档永不覆盖、Skill 命名前缀（copilot-*/manual-*）与"manual-* 禁 REV"约束、Inner/Outer Loop 软上限、outlook.htm 实时解析。
- 详见各对应文档；本节不重复。

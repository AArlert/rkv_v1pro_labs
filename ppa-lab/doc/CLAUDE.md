# PPA-Lite Agent 入口文件

> 本文件是任何 Agent 进入 `/ppa-lab/` 后的**第一个读取目标**。
> 协作协议详见 `ppa-agent-character.md`；项目蓝图详见 `ppa-lab-prompt.md`。

---

## 1 Onboarding 流程（进入仓库后第一件事）

按以下顺序读取，**按需深入，不要通读所有文件**：

1. **`doc/ppa-status.md`**（≤30 秒）— 了解当前进度、阻塞项、下一步
2. **当前 lab 的 `labX/doc/handoff.md`**（≤2 分钟）— 了解上一棒留下了什么
3. **`doc/ppa-feature-matrix.md`**（≤2 分钟）— 确认哪些功能已完成、哪些待做
4. **`doc/ppa-agent-character.md`** — 确认自己的角色和职责
5. **`doc/ppa-lab-prompt.md`** 的相关章节 — 命名规范、目录结构
6. **`doc/ppa-lite-spec.md`** 的相关章节 — 按 feature-matrix 中的 Spec § 按需查阅

## 2 收尾流程（会话结束前最后一件事）

提交前必须完成：

1. 更新 `doc/ppa-status.md` — 反映最新进度
2. 更新 `doc/ppa-feature-matrix.md` — 改动涉及的行改状态
3. 追加 `labX/doc/handoff.md` — 写交接笔记给下一个 Agent
4. 如有新风险/假设，追加到 `doc/ppa-risk-register.md`
5. 运行 `labX/doc/acceptance.md` 中的判据（如适用）
6. 在 `labX/doc/log.md` 中记录当前阶段（设计/实现/验证/验收/迭代，各阶段由 ppa-lab-prompt.md §6 §7 定义）的设计/实现细节、挑战、决策理由等

## 3 通用编码准则

### 3.1 编码前思考

- **明确说明假设** — 不确定时，记录到 `ppa-risk-register.md` 并标注待验证
- **呈现多种解释** — 存在歧义时不要默默选择
- **困惑时停下来** — 在 `handoff.md` 中记录 Open Question，挂起当前子任务

### 3.2 简洁优先

- 不要添加要求之外的功能
- 不要为一次性代码创建抽象
- 如果 200 行代码可以写成 50 行，重写它
- 匹配现有风格

### 3.3 精准修改

- 只碰必须碰的文件和行
- 不要"改进"相邻代码或格式
- 每一行修改都应直接追溯到当前任务

### 3.4 目标驱动执行

将任务转化为可验证目标：

| RTL/验证场景 | 转化为... |
|-------------|-----------|
| "实现 CSR" | "编写 CSR RTL → `make comp` 0 error → tc_csr_default_rw PASS" |
| "修复 FSM bug" | "编写复现用例 → 定位 → 修复 → 原用例 PASS 且回归不劣化" |
| "补充 testcase" | "在 testplan 新增行 → 实现 TC → `make run` PASS → 更新 ppa-feature-matrix" |

## 4 文件优先级（冲突时的裁决顺序）

1. `ppa-lite-spec.md` — 唯一技术真相源
2. `ppa-agent-character.md` — 协作协议
3. `ppa-lab-prompt.md` — 项目蓝图与规范
4. 本文件 — 通用编码准则

> 当 prompt 与 spec 出现矛盾时，以 spec 为准。

## 5 log.md 的使用说明

- `labX/doc/log.md` 主要供**人工阅读和维护**
- 新 Agent 进入时**只读顶部 Status 摘要**（≤20 行），不需要读全部内容
- 仅在需要了解历史决策细节时才阅读完整 log
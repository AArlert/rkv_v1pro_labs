---
name: rtl-designer
description: RTL 工程师。把 design-prompt 翻译成可综合的 SystemVerilog；自查 lint/CDC/可综合性；不写测试
model: human + copilot-completion
effort: high
maxTurns: 多 session
skills:
  - manual-csr-attributes
  - manual-sv-tb-patterns
  - copilot-review-rtl
---

## Stage Sequence

1. 读 `lab*/doc/design-prompt.md`（必读完整）
2. 读 `memory/rtl/knowledge.md`
3. 写端口（不写逻辑）→ `vcs -sverilog` 编译通过
4. 按 design-prompt 顺序逐段写 always_ff / always_comb
   - **Copilot 仅允许补齐单 token / 一行**；多行补全必须看懂每一行
5. 每写完一个寄存器/一段 FSM 就编译一次（防止编译错误堆积）
6. RTL 完成后：自跑 `make lint`（如有）+ 让 Reviewer Agent 用 `copilot-review-rtl` 审一遍
7. 修 review 中的 P0 → 提交

## Tool Options

- `vcs -sverilog -full64 -lint=all`（VCS 自带 lint）
- Copilot 补齐
- `xtrace` 追 driver/load（卡 bug 时让 Copilot 帮我看）

## Loop-Back Rules

- Copilot 补的代码有任何一行说不出"为什么" → 拒绝并手写
- DV 角色提交 FR 指向我的某个 module → 我必须先复现 → 再修 → 再 close FR
- 如发现 design-prompt 有歧义 → 不要私自决策，让 Architect 角色重审

## Sign-off Criteria

- [ ] `vcs -sverilog` 0 error / warning 已分类（保留的 warning 在 log.md 记录）
- [ ] lint 0 critical（CDC / multi-driver / latch）
- [ ] 端口与 design-prompt 表 100% 一致
- [ ] Reviewer Agent 0 个 P0

## Output Format

每完成一个寄存器/模块就在 `lab*/doc/log.md` 写：
```
>>> ROLE: rtl-designer @ <ts>
- Implemented: CTRL register (RW + W1P start)
- Decisions: start_o = hit_ctrl & wdata[1] & PENABLE & ~start_o_d (单拍)
- Skipped: 暂不实现 OOB PSLVERR（留到下一段）
<<< 
```

## Behaviour Rules

- 一律 SystemVerilog，禁止 Verilog-2001 风格
- 时序逻辑用 `always_ff`，组合用 `always_comb`
- 信号命名遵循 spec
- 复位策略统一**异步 assert、同步 deassert**
- 不要为了"以防万一"加多余逻辑

## Memory

读：`memory/rtl/knowledge.md`
写：`memory/rtl/experiences.jsonl`（决策+教训）

## Design State

`labs.<lab>.rtl: wip → done` 当所有 module 编译通过且 Reviewer 签字

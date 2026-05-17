---
name: dv-engineer
description: 验证工程师。写 testplan、SV/UVM TB、跑回归、收 5 类覆盖率；发现 bug 写 fix_request 给 RTL
model: human + copilot-completion
effort: high
maxTurns: 多 session
skills:
  - manual-sv-tb-patterns
  - manual-uvm-env-skeleton
  - manual-coverage-closure
  - copilot-log-triage
  - copilot-wave-analyze
  - copilot-review-tb
---

## Stage Sequence

1. 读 `lab*/doc/design-prompt.md`（理解被验证对象）
2. 读 `memory/dv/knowledge.md`
3. **先写 testplan.md**：每条 TC 含 name/feature/spec-ref/input/expected/check-points
4. 写 TB 顶层（clk/rst/DUT/stub/dump）
5. 写 task: `apb_write/read`、`build_packet`、`check_*`
6. 按 testplan 顺序逐条实现 TC，每跑通一条立刻 commit
7. 全 TC PASS 后：跑 cov、分析未覆盖、加 covergroup 或 TC 直到 ≥ 90%
8. Lab4：把 SV TC 翻译为 UVM tests，跑 `make uvm`

## Tool Options

- VCS 仿真 + Verdi 看波形
- `xwave ai query` 让 Copilot 直接读 FSDB，免去手开 Verdi
- `copilot-log-triage` 让 Copilot 看 run.log 自动归类 FAIL
- `copilot-review-tb` 让 Copilot 审 TB 是否有"假 PASS"风险

## Loop-Back Rules

- TC FAIL：先用 `xwave` 看波形 → 判断 RTL bug or TB bug
  - RTL bug：写 fix_request，append `memory/design_state.json fix_requests[]`，path/line/expected/observed 填全
  - TB bug：自修
- 覆盖率项打不到：写新 TC 或 covergroup；不能轻易豁免
- 豁免必须在 `lab*/doc/coverage_exclusion.md` 写明 reason + spec 引用

## Sign-off Criteria

- [ ] testplan.md 覆盖 spec §11.x 所有必做（每条对应 ≥1 TC）
- [ ] 所有 TC PASS（self-check 而非肉眼）
- [ ] 5 类覆盖率 ≥ 90%
- [ ] 每个 FAIL 至少有 1 条 experiences.jsonl 记录根因

## Output Format

每条 TC 的 PASS/FAIL 用约定字符串：
```
[CMP_FINAL_PASS] TC1 CSR_DEFAULT
[CMP_FINAL_FAIL] TC5 RO_PROTECT — PSLVERR expected 1 got 0 @ time 235ns
```
方便 Makefile `grep` 统计。

## Behaviour Rules

- 永远写 self-check，不允许"看波形判定"作为 sign-off
- 一条 TC 一个事；不要在 TC1 里塞 TC2 的检查
- ref model 必须独立于 RTL 实现（避免循环论证）
- 不要为了 PASS 而宽松 check

## Memory

读：`memory/dv/knowledge.md`、Lab1-3 的 testplan.md
写：`memory/dv/experiences.jsonl`（FAIL 根因、特殊 TC 设计思路）

## Design State

`labs.<lab>.tb / cov / accept` 推进

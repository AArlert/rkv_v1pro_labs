# template: `lab*/doc/acceptance.md` 关单自检

> DV 主要维护；ORCH 关单前查；REV labclose 报告会引用本文件勾选项。

```markdown
# Lab<N> Acceptance Checklist

## 必做（任一未勾不准关单）
- [ ] 所有 testplan.md TC 在 svtb/sim/run.log 显示 `[CMP_FINAL_PASS]`
- [ ] 5 类覆盖率 ≥ 90%（line / cond / fsm / branch / tgl）— 报告路径：`svtb/cov/urgReport`
- [ ] Spyglass `lint_rtl` 0 critical 0 error — 报告：`svtb/spyglass_reports/moresimple/lint_rtl/`
- [ ] REV labclose 报告 0 P0 — 路径：`doc/review_report/<YYYYMMDD>-<HHMM>-labclose-full.md`
- [ ] `memory/state.md` 中本 lab 所有 phase 为 `done`
- [ ] `doc/handoff.md` 到下个 lab 已写（用 `template/handoff.md`）

## 可选 / 例外
- [ ] cov 豁免项已登记到 `doc/coverage_exclusion.md` 并引 spec §（用 `template/coverage-exclusion-row.md`）
- [ ] 已知 P1 全部 deferred 并在 state.md History 留底

## 关单签字
- 关单时间: YYYY-MM-DD
- 关单 RISK 复盘条数: N（见 `memory/orchestrator/experiences.md` 同日条目）
```

# lab4 — 全系统回归 + 覆盖率 + 完整 UVM env

> Spec：[`../doc/ppa-lite-spec.md`](../doc/ppa-lite-spec.md) §11.5
> 工作流：[`../doc/workflow.md`](../doc/workflow.md)

## 目标

1. lab1–3 全部必做 testcase 转入结构化 UVM 回归
2. 五类覆盖率达标：line + branch + condition + FSM + toggle，≥ 90%
3. `make regress` + `make cov` 一键回归 + 覆盖率报告
4. testplan 文档化（与 spec §11.5 必做3 一致）

## 目录速览

```
lab4/
├── doc/{design-note.md, testplan.md, progress.md, regression-result.md}
├── rtl/                      不新增 RTL；通过 sim/filelist.f 引用 lab1–3
├── verif/
│   ├── tb/{tb_top.sv, hdl_top.sv}     UVM TB（hdl_top 例化 DUT + interface）
│   ├── env/{ppa_env.sv, ppa_env_pkg.sv, ppa_scoreboard.sv, ppa_coverage.sv}
│   ├── agents/apb_agent/    完整 APB agent（driver/monitor/sequencer/agent/pkg）
│   ├── sequences/           virtual seq + 各 feature seq
│   ├── tests/               base_test + 各回归 test
│   ├── ref_model/           端到端 packet ref model（独立实现）
│   └── common/              ppa_test_pkg.sv（汇总 import）
└── sim/{Makefile, filelist.f, regress.list}
```

## 阶段流转

| 阶段 | REV 报告 |
|---|---|
| V (UVM env build) | `tb-env` |
| R (Regression) | `regression-full` |

## 强约束（与 spec §11.5 一致）

- 助教当场执行 `make regress` 全 PASS（不接受截图）
- 覆盖率：≥90% 合格，≥95% 优良，100% 优秀
- testplan 必须列出每条 testcase 的 (输入摘要 / 期望输出 / 结果)

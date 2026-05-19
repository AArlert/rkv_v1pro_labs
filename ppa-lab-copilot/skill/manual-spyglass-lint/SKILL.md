---
name: manual-spyglass-lint
description: Spyglass 2018 静态检查（lint / CDC / 可综合性）速查，RTL sign-off 前必跑一次
license: MIT
when_to_use: RTL 写完一个 module 或 lab close 前；DV 不直接用，但要看懂报告
inputs:
  - lab*/rtl/*.sv
  - 一个 goal（lint_rtl / cdc_setup / cdc_advanced）
outputs:
  - moresimple/spyglass_reports/<goal>/*.rpt
  - 一句话结论（PASS / N critical / N error）
tools: [spyglass]
---

# Spyglass 2018 Lint 速查（人用）

## Purpose

把 Spyglass 当成"sign-off 前的静态守门员"——抓 latch / multi-driver / CDC / 可综合性问题。

## When to Use

| 场景 | goal |
|---|---|
| 写完单个 RTL module，sign-off 前 | `lint_rtl` |
| 整 lab close 前，多时钟域已接齐 | `cdc_setup` 然后 `cdc_advanced` |
| 综合前最终把关 | `lint_rtl + cdc_advanced` 各跑一次 |

## How to Use

最小命令序列：

```bash
# 启动（GUI 模式调试 / 批模式跑 sign-off）
spyglass -tcl spyglass.tcl
# 或
spyglass -batch -tcl spyglass.tcl -goals lint_rtl
```

`spyglass.tcl` 骨架：

```tcl
new_project ppa_lint
read_file -type sourcelist filelist.f
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff
current_goal lint/lint_rtl -top ppa_packet_sram
run_goal
write_report -reportdir reports moresimple
exit
```

`filelist.f`：
```
+incdir+../rtl
../rtl/ppa_packet_sram.sv
../rtl/ppa_apb_slave_if.sv
../rtl/ppa_packet_proc_core.sv
```

## 必须关闭的 0 critical 规则（人去逐条核）

| 规则 ID | 含义 | 处理 |
|---|---|---|
| `STARC05-1.4.3.5` | latch inferred | 改写 `always_comb` 默认赋值 |
| `STARC-2.10.3.6`  | multi-driver | 改 case / mux |
| `Ac_unsynth01`    | non-synth 构造 | 移到 tb |
| `Clock_info01`    | 时钟未声明 | 在 SGDC 中声明 |
| `Ar_resetcross01` | reset 跨域 | 同步 deassert |

## Sign-off 判定

- `lint_rtl` 0 critical + 0 error → RTL Sign-off Criteria 第 2 条 ✅
- `cdc_advanced` 0 critical → labclose 前 REV 会查这份报告

## Notes / Gotchas

- 项目使用 Spyglass 2018；2020+ 的 GuideWare 路径不一样
- `current_methodology` 必须显式设置，否则部分规则不启用
- 报告路径写到 `lab*/svtb/sim/spyglass_reports/`，commit 时只 commit `moresimple/*.rpt`（轻量）
- 与 VCS `-lint=all` 互补；不替代

## 与 REV 的关系

REV 不再直接跑 Spyglass（EDA 许可只在本机），但**会读** `moresimple/lint_rtl/lint_rtl.rpt`。所以 RTL 必须在 sign-off 前把这份报告 commit 进仓。

---
name: review-uvm-env
description: 审 UVM 树结构、phase 顺序、TLM 连接、virtual sequencer 用法（lab4 专属）
license: MIT
when_to_use: REV 处理 lab4 phase=tb 或 phase=regression
inputs:
  - lab4/verif/env/*.sv
  - lab4/verif/agents/**/*.sv
  - lab4/verif/sequences/*.sv
  - lab4/verif/tests/*.sv
outputs:
  - 报告 "Where / How-to-fix / Why / How-it-was-done" 四段填充
tools:
  - Read, Grep
---

# Skill: Review UVM Environment

## Purpose

PPA-Lite 在 lab4 才上完整 UVM env。审查重点：UVM 树是否搭对，phase 顺序是否合规，TLM 连接是否丢失，virtual sequencer 是否正确。

## When to Use

- 仅 lab4 适用
- lab1–3 的 `verif/env` 多为占位，**不**触发本 skill

## Checklist

### A. UVM 树结构（P0）
- [ ] `*_env` 在 `build_phase` 中实例化所有子组件
- [ ] agent 的 `is_active` 字段正确（passive 不 build sequencer/driver）
- [ ] scoreboard 与 monitor 之间有 TLM `analysis_port` 连接（`connect_phase`）

### B. Phase 顺序（P0）
- [ ] `build_phase` 中不 `start` sequence
- [ ] `run_phase` 中正确 `raise_objection` / `drop_objection`
- [ ] virtual sequence 在 `run_phase` 中启动到 virtual sequencer

### C. UVM_ERROR/UVM_FATAL（P1）
- [ ] 错误用 `UVM_ERROR` 而不是 `$display`
- [ ] mismatch 升级为 `UVM_ERROR`，超时升级为 `UVM_FATAL`

### D. Config DB / Factory（P1）
- [ ] virtual interface 通过 `uvm_config_db#(virtual *_if)::set/get` 传递
- [ ] 测试通过 `+UVM_TESTNAME` 选择，不硬编码

### E. 命名（P2）
- [ ] 文件名与类名一致（`apb_driver.sv` 内是 `apb_driver`）

## Output Mapping

| Checklist 项 | Why 引用 |
|---|---|
| A. TLM 漏接 | UVM 方法学 + design-note §"env 结构" |
| B. phase 错位 | UVM 1.2 / 1800.2 LRM phase 章节 |
| D. config 硬编码 | UVM 方法学 + manual-uvm-env-skeleton（仅引概念，不直接调） |

## Notes / Gotchas

- 学生第一次写 UVM 最常见错误：`build_phase` 里 `start` sequence（应该在 `run_phase`），列为 P0 标准案例
- 不抠风格（class 排序、import 顺序），只抠"跑不起来 / 跑起来不报错"

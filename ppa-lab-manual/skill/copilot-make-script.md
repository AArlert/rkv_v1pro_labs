---
name: copilot-make-script
description: 生成/修订 VCS+Verdi 的 Makefile（comp/run/wave/cov/uvm 目标）
license: MIT
when_to_use: 新建 lab 的 sim/Makefile，或要加新目标（如 cov_merge）
inputs:
  - lab 路径、RTL 文件列表、TB 类型（SV/UVM）
outputs:
  - Makefile 文本
tools: []
---

# Copilot: Make Script

## Standard Targets

| 目标 | 含义 |
|---|---|
| `comp` | vcs 编译生成 simv |
| `run` | ./simv 跑 + log |
| `wave` | verdi -ssf novas.fsdb |
| `cov` | -cm line+cond+fsm+branch+tgl + urg |
| `regress` | 多 lab 串行跑 + 汇总 PASS/FAIL |
| `uvm` | 循环 +UVM_TESTNAME 跑所有 test |
| `uvm_cov` | UVM 跑 + 合 vdb + urg HTML |
| `clean` | 清产物 |

## VCS Flag Set

参考 `manual-vcs-flags`。FSDB 必须 link `novas.tab + pli.a`。

## Output Convention

`run.log` 中用：
- `[CMP_FINAL_PASS] TC_NAME`
- `[CMP_FINAL_FAIL] TC_NAME reason`

便于上层 grep 统计。

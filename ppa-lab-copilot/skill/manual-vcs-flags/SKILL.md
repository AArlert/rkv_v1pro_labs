---
name: manual-vcs-flags
description: VCS 编译/仿真常用 flag 速查
license: MIT
when_to_use: 写 Makefile 或在命令行临时跑 vcs 时
inputs: []
outputs: []
tools: [vcs]
---

# VCS Flag 速查（待 0 周补全）

## 编译

| 用途 | flag |
|---|---|
| SV | `-full64 -sverilog -timescale=1ns/1ps` |
| 调试可见 | `-debug_access+all -kdb -lca` |
| FSDB | `-P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a` |
| 覆盖率 | `-cm line+cond+fsm+branch+tgl -cm_hier cov.cfg` |
| UVM | `-ntb_opts uvm-1.2` |

## 仿真

| 用途 | flag |
|---|---|
| 随机种子 | `+ntb_random_seed=N` |
| 覆盖率 | `-cm line+cond+fsm+branch+tgl -cm_dir x.vdb -cm_name <test>` |
| UVM 测试名 | `+UVM_TESTNAME=ppa_basic_test +UVM_VERBOSITY=UVM_LOW` |

## 覆盖率合并/报告

```bash
urg -dir t1.vdb -dir t2.vdb -dbname merged.vdb
urg -dir merged.vdb -format both -report urgReport
```

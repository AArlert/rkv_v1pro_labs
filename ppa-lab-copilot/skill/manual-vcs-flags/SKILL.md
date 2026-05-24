---
name: manual-vcs-flags
description: VCS 编译/仿真常用 flag 速查
license: MIT
when_to_use: 写 Makefile / 在命令行临时跑 vcs
inputs: []
outputs: []
tools:
  - vcs
---

# VCS Flag 速查

## 编译

| 用途                   | flag                                                                                     | 备注     |
| -------------------- | ---------------------------------------------------------------------------------------- | ------ |
| SV                   | `-full64 -sverilog -timescale=1ns/1ps`                                                   |        |
| 调试可见                 | `-debug_access+all -kdb -lca`                                                            |        |
| 输出                   | `-l comp.log -o simv`                                                                    |        |
| 特定版本编译选项(防 undefine) | `-LDFLAGS '-Wl,--no-as-needed'`                                                          | 一定要加   |
| FSDB                 | `-P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a` |        |
| 覆盖率                  | `-cm line+cond+fsm+branch+tgl -cm_hier cov.cfg`                                          | 待实验和蒸馏 |
| UVM                  | `-ntb_opts uvm-1.2`                                                                      | 待实验和蒸馏 |

## 仿真

| 用途      | flag                                                         | 备注                   |
| ------- | ------------------------------------------------------------ | -------------------- |
| 随机种子    | `+ntb_random_seed=$(SEED)`                                   | `$(SEED)` 宏定义更利于统一管理 |
| 覆盖率     | `-cm line+cond+fsm+branch+tgl -cm_dir x.vdb -cm_name <test>` | 待实验和蒸馏               |
| UVM 测试名 | `+UVM_TESTNAME=ppa_basic_test +UVM_VERBOSITY=UVM_LOW`        | 待实验和蒸馏               |

## 覆盖率合并/报告

```bash
urg -dir t1.vdb -dir t2.vdb -dbname merged.vdb
urg -dir merged.vdb -format both -report urgReport
```

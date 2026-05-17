---
name: manual-make-templates
description: smoke/regress/cov/uvm 四个标准目标的 Makefile 模板
license: MIT
when_to_use: 新建 lab 的 sim/Makefile 时
inputs: []
outputs: []
tools: [vcs, verdi, urg]
---

# Makefile 模板（在 Lab1 完成后补全）

## 单 Lab 最小（lab1/svtb/sim/Makefile）

```makefile
TB       ?= ppa_tb
SEED     ?= 1
RTL      = ../../rtl/ppa_apb_slave_if.sv ../../rtl/ppa_packet_sram.sv
TBSV     = ../tb/$(TB).sv

VCS_OPTS = -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca \
           +define+DUMP_FSDB \
           -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
              $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a
SIM_OPTS = +ntb_random_seed=$(SEED)

comp:	; vcs $(VCS_OPTS) $(RTL) $(TBSV) -l comp.log -o simv
run:	; ./simv $(SIM_OPTS) -l run.log
wave:	; verdi -ssf novas.fsdb -nologo &
clean:	; rm -rf simv* csrc *.log *.fsdb *.daidir *.key ucli.key novas* verdiLog
```

## 多 Lab 回归（lab4/svtb/sim/Makefile）

```makefile
LABS := lab1 lab2 lab3
regress:
	@total=0; pass=0; fail=0; \
	for l in $(LABS); do \
	  $(MAKE) -C ../../../$$l/svtb/sim clean comp run; \
	  p=$$(grep -c "\[CMP_FINAL_PASS\]" ../../../$$l/svtb/sim/run.log); \
	  f=$$(grep -c "\[CMP_FINAL_FAIL\]" ../../../$$l/svtb/sim/run.log); \
	  total=$$((total+p+f)); pass=$$((pass+p)); fail=$$((fail+f)); \
	done; \
	echo "Total: $$total  PASS: $$pass  FAIL: $$fail" | tee result_summary.txt
```

## 覆盖率（参考 ppa-plan §8.3）

略——见 `manual-coverage-closure`

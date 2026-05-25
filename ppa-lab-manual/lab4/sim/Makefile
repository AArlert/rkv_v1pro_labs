# lab4 Makefile —— UVM 回归 + 覆盖率
# 学生维护。仿真器命令按本机替换（vlog/vsim 或 vcs/xrun/xmsim）。

REGRESS_LIST ?= regress.list

.PHONY: smoke regress cov wave clean

smoke:
	@echo "[lab4] UVM smoke (csr_default_test)"
	# TODO(student): single test run

regress:
	@echo "[lab4] full regression"
	# TODO(student): foreach test in $(REGRESS_LIST), 跑一次，汇总 PASS/FAIL

cov:
	@echo "[lab4] merge ucdb + 生成 HTML 报告"
	# TODO(student): vcover merge / vcover report -html

wave:
	# TODO(student): 生成 fsdb（按需，回归默认关）

clean:
	rm -rf work transcript *.log *.fsdb *.vcd waves cov_report ucdb *.ucdb

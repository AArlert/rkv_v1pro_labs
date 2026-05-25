# Lab1 Makefile — smoke / wave / clean
# 仿真器：Questasim（与 spec §1.4 一致）。学生可按本机环境替换 vlog/vsim 为 vcs/xrun。
# 触发：在本目录 `make smoke`
# REV：跑完后在 ../doc/progress.md 追加 ">>> CALL REV ... phase=tb" 调审查

FILELIST   ?= filelist.f
TOP        ?= tb_top
WAVE_FORMAT ?= fsdb

.PHONY: smoke wave clean

smoke:
	@echo "[lab1] compile + run smoke"
	# TODO(student): vlog -f $(FILELIST) ; vsim -c $(TOP) -do "run -all; quit"

wave:
	@echo "[lab1] dump wave to sim/waves/"
	# TODO(student): 在 TB 内 $fsdbDumpvars 或 $dumpvars

clean:
	rm -rf work transcript *.log *.fsdb *.vcd waves

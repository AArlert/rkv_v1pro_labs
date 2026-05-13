#############################
# Lab4 — Unified Regression & Coverage Makefile
#############################
# Targets:
#   make smoke   — quick sanity (Lab1 only, 11 TC / 74 checks)
#   make regress — full regression (Lab1+2+3, 42 TC / 224 checks)
#   make cov     — full regression + Questa coverage (line/branch/condition/FSM/toggle → HTML)
#   make clean   — remove all generated artifacts
#############################

SHELL := /bin/bash

#############################
# Paths (relative to this Makefile location: lab4/svtb/sim/)
#############################
LAB_ROOT := ../../..

LAB1_SIM := $(LAB_ROOT)/lab1/svtb/sim
LAB2_SIM := $(LAB_ROOT)/lab2/svtb/sim
LAB3_SIM := $(LAB_ROOT)/lab3/svtb/sim

# RTL sources
RTL_LAB1 := $(LAB_ROOT)/lab1/rtl/ppa_apb_slave_if.sv \
            $(LAB_ROOT)/lab1/rtl/ppa_packet_sram.sv

RTL_LAB2 := $(LAB_ROOT)/lab2/rtl/ppa_packet_proc_core.sv

RTL_LAB3 := $(LAB_ROOT)/lab3/rtl/ppa_top.sv

RTL_ALL  := $(RTL_LAB1) $(RTL_LAB2) $(RTL_LAB3)

# Testbench sources
TB_LAB1  := $(LAB_ROOT)/lab1/svtb/tb/ppa_tb.sv
TB_LAB2  := $(LAB_ROOT)/lab2/svtb/tb/ppa_tb.sv
TB_LAB3  := $(LAB_ROOT)/lab3/svtb/tb/ppa_tb.sv

#############################
# Simulation settings
#############################
TB       := ppa_tb
SEED     ?= 1

# Coverage: b=branch c=condition s=statement(line) f=FSM t=toggle
COV_COMP := -cover bcstf
COV_RUN  := -coverage -cvgperinstance

#############################
# Tool commands
#############################
VLIB     = vlib
VLOG     = vlog -sv -timescale=1ns/1ps
VSIM     = vsim -voptargs=+acc -sv_seed $(SEED) $(TB)
VCOVER   = vcover

#############################
# Coverage output paths
#############################
COV_DIR    := covdata
COV_HTML   := covhtmlreport
UCDB_LAB1  := $(COV_DIR)/lab1.ucdb
UCDB_LAB2  := $(COV_DIR)/lab2.ucdb
UCDB_LAB3  := $(COV_DIR)/lab3.ucdb
UCDB_MERGE := $(COV_DIR)/merged.ucdb

#############################
# smoke — quick sanity via Lab1 (CSR + SRAM, 11 TC)
#############################
smoke:
	@echo "==== [SMOKE] Lab1: 11 TC / 74 checks ===="
	$(MAKE) -C $(LAB1_SIM) clean comp run
	@echo "==== [SMOKE] PASS ===="

#############################
# regress — full 42 TC across Lab1 + Lab2 + Lab3
#############################
regress:
	@echo "==== [REGRESS] Lab1: 11 TC / 74 checks ===="
	$(MAKE) -C $(LAB1_SIM) clean comp run
	@echo "==== [REGRESS] Lab2: 17 TC / 94 checks ===="
	$(MAKE) -C $(LAB2_SIM) clean comp run
	@echo "==== [REGRESS] Lab3: 14 TC / 56 checks ===="
	$(MAKE) -C $(LAB3_SIM) clean comp run
	@echo "==== [REGRESS] ALL 42 TC / 224 checks DONE ===="

#############################
# cov — compile with coverage, run all labs, merge, generate HTML report
#############################
cov: cov_clean cov_run_lab1 cov_run_lab2 cov_run_lab3 cov_merge cov_report
	@echo "==== [COV] HTML report: $(COV_HTML)/index.html ===="

cov_clean:
	rm -rf work_lab1 work_lab2 work_lab3 $(COV_DIR) $(COV_HTML)
	mkdir -p $(COV_DIR)

cov_run_lab1:
	@echo "---- [COV] Lab1: compile + run ----"
	$(VLIB) work_lab1
	$(VLOG) -work work_lab1 $(COV_COMP) -l comp_lab1.log $(RTL_LAB1)
	$(VLOG) -work work_lab1 -l comp_lab1_tb.log $(TB_LAB1)
	$(VSIM) -work work_lab1 $(COV_RUN) -l run_lab1.log \
	    -c -do "coverage save -onexit $(UCDB_LAB1); run -all; quit -f"

cov_run_lab2:
	@echo "---- [COV] Lab2: compile + run ----"
	$(VLIB) work_lab2
	$(VLOG) -work work_lab2 $(COV_COMP) -l comp_lab2.log $(RTL_LAB2)
	$(VLOG) -work work_lab2 -l comp_lab2_tb.log $(TB_LAB2)
	$(VSIM) -work work_lab2 $(COV_RUN) -l run_lab2.log \
	    -c -do "coverage save -onexit $(UCDB_LAB2); run -all; quit -f"

cov_run_lab3:
	@echo "---- [COV] Lab3: compile + run ----"
	$(VLIB) work_lab3
	$(VLOG) -work work_lab3 $(COV_COMP) -l comp_lab3.log $(RTL_ALL)
	$(VLOG) -work work_lab3 -l comp_lab3_tb.log $(TB_LAB3)
	$(VSIM) -work work_lab3 $(COV_RUN) -l run_lab3.log \
	    -c -do "coverage save -onexit $(UCDB_LAB3); run -all; quit -f"

cov_merge:
	@echo "---- [COV] Merging coverage databases ----"
	$(VCOVER) merge $(UCDB_MERGE) $(UCDB_LAB1) $(UCDB_LAB2) $(UCDB_LAB3)

cov_report:
	@echo "---- [COV] Generating HTML report ----"
	$(VCOVER) report -html -output $(COV_HTML) $(UCDB_MERGE)

#############################
# clean — remove all generated artifacts
#############################
clean:
	rm -rf work_lab1 work_lab2 work_lab3 $(COV_DIR) $(COV_HTML)
	rm -f *.log *.wlf transcript
	$(MAKE) -C $(LAB1_SIM) clean
	$(MAKE) -C $(LAB2_SIM) clean
	$(MAKE) -C $(LAB3_SIM) clean

.PHONY: smoke regress cov cov_clean cov_run_lab1 cov_run_lab2 cov_run_lab3 \
        cov_merge cov_report clean

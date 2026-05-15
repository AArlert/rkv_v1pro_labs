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
clean: uvm_clean
	rm -rf work_lab1 work_lab2 work_lab3 $(COV_DIR) $(COV_HTML)
	rm -f *.log *.wlf transcript
	$(MAKE) -C $(LAB1_SIM) clean
	$(MAKE) -C $(LAB2_SIM) clean
	$(MAKE) -C $(LAB3_SIM) clean

#############################
# UVM (Lab4 Phase 3) — equivalent regression in UVM env covering Lab1-3 scenarios
#############################
TB_UVM    := ../tb/ppa_apb_if.sv ../tb/ppa_ref_model.sv ../tb/ppa_pkg.sv ../tb/ppa_uvm_tb.sv
WORK_UVM  := work_uvm
UVM_TOP   := ppa_uvm_tb
UVM_TESTS := ppa_csr_default_test ppa_csr_rw_test ppa_csr_ro_test ppa_csr_slverr_test \
             ppa_w1p_test ppa_pkt_mem_rw_test ppa_basic_test ppa_payload_unaligned_test \
             ppa_two_frame_test ppa_error_test ppa_algo_bypass_test ppa_exp_pkt_len_test \
             ppa_irq_done_test ppa_irq_err_test ppa_busy_write_protect_test \
             ppa_mid_sim_reset_test ppa_toggle_exercise_test ppa_regression_test

UCDB_UVM_DIR := covdata_uvm
COV_HTML_UVM := covhtml_uvm

uvm_compile:
	@echo "==== [UVM] Compile ===="
	$(VLIB) $(WORK_UVM)
	$(VLOG) -work $(WORK_UVM) -L mtiUvm -l comp_uvm.log $(RTL_ALL) $(TB_UVM)

uvm: uvm_compile
	@set -e; for t in $(UVM_TESTS); do \
		echo "==== [UVM] Run test: $$t ===="; \
		vsim -c -L mtiUvm -sv_seed $(SEED) -work $(WORK_UVM) $(UVM_TOP) \
		    +UVM_TESTNAME=$$t +UVM_VERBOSITY=UVM_LOW \
		    -l run_uvm_$$t.log -do "run -all; quit -f"; \
	done
	@echo "==== [UVM] Per-test results ===="
	@for t in $(UVM_TESTS); do \
		pass=$$(grep -c "\[CMP_FINAL_PASS\]" run_uvm_$$t.log || true); \
		errs=$$(grep -E "^UVM_ERROR :" run_uvm_$$t.log | tail -1); \
		fats=$$(grep -E "^UVM_FATAL :" run_uvm_$$t.log | tail -1); \
		printf "  %-40s pass=%s  %s  %s\n" "$$t" "$$pass" "$$errs" "$$fats"; \
	done
	@echo "==== [UVM] DONE ===="

uvm_cov: uvm_cov_clean
	@echo "==== [UVM_COV] Compile with coverage ===="
	$(VLIB) $(WORK_UVM)
	$(VLOG) -work $(WORK_UVM) -L mtiUvm $(COV_COMP) -l comp_uvm_cov.log $(RTL_ALL) $(TB_UVM)
	mkdir -p $(UCDB_UVM_DIR)
	@set -e; for t in $(UVM_TESTS); do \
		echo "---- [UVM_COV] $$t ----"; \
		vsim -c -L mtiUvm -sv_seed $(SEED) -work $(WORK_UVM) $(UVM_TOP) \
		    +UVM_TESTNAME=$$t $(COV_RUN) \
		    -l run_uvm_cov_$$t.log \
		    -do "coverage save -onexit $(UCDB_UVM_DIR)/$$t.ucdb; run -all; quit -f"; \
	done
	@echo "---- [UVM_COV] Merge ----"
	$(VCOVER) merge $(UCDB_UVM_DIR)/merged.ucdb $(UCDB_UVM_DIR)/*.ucdb
	@echo "---- [UVM_COV] HTML ----"
	$(VCOVER) report -html -output $(COV_HTML_UVM) $(UCDB_UVM_DIR)/merged.ucdb
	@echo "==== [UVM_COV] HTML report: $(COV_HTML_UVM)/index.html ===="

uvm_cov_clean:
	rm -rf $(WORK_UVM) $(UCDB_UVM_DIR) $(COV_HTML_UVM)
	rm -f run_uvm_cov_*.log comp_uvm_cov.log

uvm_clean:
	rm -rf $(WORK_UVM) $(UCDB_UVM_DIR) $(COV_HTML_UVM)
	rm -f run_uvm_*.log comp_uvm*.log

.PHONY: smoke regress cov cov_clean cov_run_lab1 cov_run_lab2 cov_run_lab3 \
        cov_merge cov_report clean uvm uvm_compile uvm_cov uvm_cov_clean uvm_clean

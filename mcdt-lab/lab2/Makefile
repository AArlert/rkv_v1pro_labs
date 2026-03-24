#############################
# User variables
#############################
TB       ?= tb
SEED     ?= 1
SIMDIR   ?= .
LIBDIR   ?= .
TESTNAME ?= mcdt_basic_test

DFILES   = $(SIMDIR)/../mcdt/arbiter.v \
           $(SIMDIR)/../mcdt/slave_fifo.v \
           $(SIMDIR)/../mcdt/mcdt.v

VFILES   = $(SIMDIR)/mcdt_pkg.sv \
           $(SIMDIR)/$(TB).sv


#############################
# Environment variables
#############################
VCOMP    = vlog -work $(LIBDIR)/work -sv -timescale=1ns/1ps -l comp.log +incdir+$(SIMDIR)/../mcdt
RUN      = vsim -work $(LIBDIR)/work $(TB) -l run.log -sv_seed $(SEED) +TESTNAME=$(TESTNAME)

comp:
	$(VCOMP) $(DFILES) $(VFILES)

run:
	$(RUN) -c -do "run -all; quit -f"

rung:
	$(RUN) -i

clean:
	rm -rf VRMDATA vrmhtmlreport
	rm -rf *.log* work *.wlf

#############################
# User variables
#############################
TB       ?= tb
SEED     ?= 1
SIMDIR   ?= .
LIBDIR   ?= .

DFILES   = $(SIMDIR)/../../rtl/hello.sv

VFILES   = $(SIMDIR)/../tb/$(TB).sv

#############################
# Environment variables
#############################
VERDI_PLI_DIR = $(VERDI_HOME)/share/PLI/VCS/LINUX64
VCS      = vcs -full64 -sverilog -debug_all -l comp.log -o simv \
           -LDFLAGS '-Wl,--no-as-needed' \
           -P $(VERDI_PLI_DIR)/novas.tab $(VERDI_PLI_DIR)/pli.a
RUN      = ./simv +ntb_random_seed=$(SEED) -l run.log

comp:
	$(VCS) $(DFILES) $(VFILES)

run:
	$(RUN)

rung:
	$(RUN) -gui

run_fsdb:
	$(RUN)

verdi: run_fsdb
	verdi -ssf sim.fsdb &

clean:
	rm -rf simv simv.daidir csrc
	rm -rf *.log *.fsdb *.vpd
	rm -rf ucli.key novas.* DVEfiles verdiLog
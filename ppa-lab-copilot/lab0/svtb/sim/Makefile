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
VCS      = vcs -full64 -sverilog -timescale=1ns/1ps \
		   -debug_access+all -kdb -lca \
		   -l comp.log -o simv \
           -LDFLAGS '-Wl,--no-as-needed' \
           -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a
RUN      = ./simv +ntb_random_seed=$(SEED) -l run.log

comp:
	$(VCS) $(DFILES) $(VFILES)

run:
	$(RUN)

rung:
	$(RUN) -gui

verdi: run
	verdi -ssf sim.fsdb &

clean:
	rm -rf simv simv.daidir csrc
	rm -rf *.log *.fsdb *.vpd
	rm -rf ucli.key novas.* DVEfiles verdiLog
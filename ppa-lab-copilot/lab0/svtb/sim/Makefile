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
VCS      = vcs -full64 -sverilog -debug_all -l comp.log -o simv -LDFLAGS -Wl,--no-as-needed
VCOMP    = $(VCS)
RUN      = ./simv +ntb_random_seed=$(SEED) -l run.log
RUN_OPTS = -R
RUN_VPD  = ./simv +ntb_random_seed=$(SEED) +vcs+vpdfile=sim.vpd -l run.log -R

comp:
	$(VCOMP) $(DFILES) $(VFILES)

run:
	$(RUN) $(RUN_OPTS)

rung:
	$(RUN) -i

run_vpd:
	$(RUN_VPD)

verdi: run_vpd
	verdi -vpd sim.vpd &

clean:
	rm -rf work *.log *.wlf transcript
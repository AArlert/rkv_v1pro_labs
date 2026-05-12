#############################
# User variables
#############################
TB       ?= ppa_tb
SEED     ?= 1
SIMDIR   ?= .
LIBDIR   ?= .

DFILES   = $(SIMDIR)/../../rtl/ppa_top.sv \
           $(SIMDIR)/../../../lab1/rtl/ppa_apb_slave_if.sv \
           $(SIMDIR)/../../../lab1/rtl/ppa_packet_sram.sv \
           $(SIMDIR)/../../../lab2/rtl/ppa_packet_proc_core.sv

VFILES   = $(SIMDIR)/../tb/$(TB).sv

#############################
# Environment variables
#############################
VCOMP    = vlog -work $(LIBDIR)/work -sv -timescale=1ns/1ps -l comp.log
RUN      = vsim -voptargs=+acc -work $(LIBDIR)/work $(TB) -l run.log -sv_seed $(SEED)

comp:
	$(VCOMP) $(DFILES) $(VFILES)

run:
	$(RUN) -c -do "run -all; quit -f"

rung:
	$(RUN) -i

clean:
	rm -rf work *.log *.wlf transcript

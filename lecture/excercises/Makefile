#############################
# User variables
#############################
TB       ?= data_types_verilog_diff_sv # 你可以在这里指定默认的测试平台
SEED     ?= 1
SIMDIR   ?= .
LIBDIR   ?= .

VFILES   = $(SIMDIR)/array_assignment.sv \
           $(SIMDIR)/constraint_dynamic_control.sv \
           $(SIMDIR)/data_types_verilog_diff_sv.sv


#############################
# Environment variables
#############################
VCOMP    = vlog -work $(LIBDIR)/work -sv -timescale=1ns/1ps -l comp.log
RUN      = vsim -work $(LIBDIR)/work $(TB) -l run.log -sv_seed $(SEED)

comp:
	$(VCOMP) $(VFILES)

run:
	$(RUN) -c -do "run -all; quit -f"

rung:
	$(RUN) -i

clean:
	rm -rf *.log* work *.wlf

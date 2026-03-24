#############################
# User variables
#############################
TB       ?= constrained_random # 你可以在这里指定默认的测试平台，如果不指定则使用 constrained_random.sv 作为默认测试平台
SEED     ?= 1
SIMDIR   ?= .
LIBDIR   ?= .

VFILES   = $(SIMDIR)/constrained_random.sv \
           $(SIMDIR)/interprocess_sync.sv \
           $(SIMDIR)/task_and_function.sv \
           $(SIMDIR)/thread_control.sv \
           $(SIMDIR)/virtual_methods.sv


#############################
# Environment variables
#############################
VCOMP    = vlog -work $(LIBDIR)/work -sv -timescale=1ns/1ps -l comp.log
RUN      = vsim -voptargs=+acc -work $(LIBDIR)/work $(TB) -l run.log -sv_seed $(SEED)

comp:
	$(VCOMP) $(VFILES)

run:
	$(RUN) -c -do "run -all; quit -f"

rung:
	$(RUN) -i

clean:
	rm -rf *.log* work *.wlf

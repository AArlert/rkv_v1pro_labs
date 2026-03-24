#############################
# User variables
#############################
TB       ?= data_type # 你可以在这里指定默认的测试平台，如果不指定则使用 data_type.sv 作为默认测试平台
SIMDIR   ?= .
LIBDIR   ?= .

VFILES   = $(SIMDIR)/data_type.sv \
           $(SIMDIR)/interface_type.sv \
           $(SIMDIR)/string_type.sv \
           $(SIMDIR)/sv_for_design.sv 


#############################
# Environment variables
#############################
VCOMP    = vlog -work $(LIBDIR)/work -sv -timescale=1ns/1ps -l comp.log
RUN      = vsim -work $(LIBDIR)/work $(TB) -l run.log 

comp:
	$(VCOMP) $(VFILES)

run:
	$(RUN) -c -do "run -all; quit -f"

rung:
	$(RUN) -i

clean:
	rm -rf *.log* work *.wlf

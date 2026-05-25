# lab4 filelist —— UVM env + 跨 lab RTL
+incdir+../verif/common
+incdir+../verif/agents/apb_agent
+incdir+../verif/env
+incdir+../../lab1/verif/common
+incdir+../../lab2/verif/common

../../lab1/verif/common/ppa_reg_pkg.sv
../../lab2/verif/common/ppa_packet_pkg.sv

# RTL（来自前 3 个 lab）
../../lab1/rtl/packet_sram.sv
../../lab1/rtl/apb_slave_if.sv
../../lab2/rtl/packet_proc_core.sv
../../lab3/rtl/ppa_top.sv

# Verif (UVM)
# TODO(student): 学生构建后取消注释
# ../verif/agents/apb_agent/apb_pkg.sv
# ../verif/env/ppa_env_pkg.sv
# ../verif/tests/ppa_test_pkg.sv
../verif/tb/hdl_top.sv
../verif/tb/tb_top.sv

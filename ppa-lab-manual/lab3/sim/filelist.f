# lab3 filelist —— 跨 lab 引用 lab1/lab2 的 RTL，避免重复维护
+incdir+../verif/common
+incdir+../../lab1/verif/common
+incdir+../../lab2/verif/common

../../lab1/verif/common/ppa_reg_pkg.sv
../../lab2/verif/common/ppa_packet_pkg.sv

# RTL：来自前两个 lab 的成品
../../lab1/rtl/packet_sram.sv
../../lab1/rtl/apb_slave_if.sv
../../lab2/rtl/packet_proc_core.sv
../rtl/ppa_top.sv

# Verif
../verif/tb/tb_top.sv

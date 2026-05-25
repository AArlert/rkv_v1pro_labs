# lab1 filelist — 编译顺序：common → rtl → verif
# 学生维护；新增文件时追加在合适分组
+incdir+../verif/common
../verif/common/ppa_reg_pkg.sv

# RTL
../rtl/packet_sram.sv
../rtl/apb_slave_if.sv

# Verif
../verif/tb/tb_top.sv

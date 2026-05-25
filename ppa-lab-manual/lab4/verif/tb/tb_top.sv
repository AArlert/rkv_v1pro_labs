// ---------------------------------------------------------------------------
// tb_top — UVM 顶层
// ---------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    initial begin
        // TODO(student): import ppa_test_pkg::*;
        run_test();  // 通过 +UVM_TESTNAME 选择
    end
endmodule

// ---------------------------------------------------------------------------
// hdl_top — DUT + interface 例化层（HDL 域）
// ---------------------------------------------------------------------------
`timescale 1ns/1ps

module hdl_top;
    logic PCLK = 0, PRESETn;
    always #5 PCLK = ~PCLK;
    initial begin
        PRESETn = 0;
        repeat (4) @(posedge PCLK);
        PRESETn = 1;
    end

    // TODO(student): 例化 apb_if(PCLK, PRESETn) intf；
    // TODO(student): 例化 ppa_top，DUT 端口与 intf 信号绑定；
    // TODO(student): uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", intf);
endmodule

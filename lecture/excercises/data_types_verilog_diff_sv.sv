interface intf(
  input clk,
  input rstn
);
  logic req;
  logic rsp;
  modport master(input clk,input rstn, input req, output rsp);
  modport slave(input clk, input rstn, output req, input rsp);
endinterface

module master(
  input clk,
  input rstn,
  intf mstmp
  //input rsp,
  //output req
);
  // mstmp.req
  // mstmp.rsp
endmodule

module slave(
  input clk,
  input rstn,
  intf slvmp
  //output rsp,
  //input req
);
  // slvmp.req
  // slvmp.rsp
endmodule



module data_types_verilog_diff_sv;
  logic clk;
  logic rstn;
  logic req, rsp;

  intf if0(
    .clk(clk)
    ,.rstn(rstn)
  );

  master mst(
     .clk(clk)
    ,.rstn(rstn)
    ,.mstmp(if0.master)
    //,.req(if0.master.req)
    //,.rsp(if0.master.rsp)
  );
  slave slv(
     .clk(clk)
    ,.rstn(rstn)
    ,.slvmp(if0.slave)
    //,.req(if0.slave.req)
    //,.rsp(if0.slave.rsp)
  );

endmodule

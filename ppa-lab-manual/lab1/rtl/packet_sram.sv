// ---------------------------------------------------------------------------
// packet_sram  (M2)
// ---------------------------------------------------------------------------
// Spec reference: doc/ppa-lite-spec.md §2.3 (M2 ports) + §4 (SRAM behavior)
// 8 × 32-bit 双端口同步 SRAM。写端口来自 M1；读端口来自 M3。
// 不做任何包语义判断。
// ---------------------------------------------------------------------------

module packet_sram (
    input  logic        clk,
    input  logic        rst_n,
    // 写端口（来自 M1）
    input  logic        wr_en,
    input  logic [2:0]  wr_addr,
    input  logic [31:0] wr_data,
    // 读端口（来自 M3）
    input  logic        rd_en,
    input  logic [2:0]  rd_addr,
    output logic [31:0] rd_data
);

    // TODO(student): 8 entry × 32-bit storage
    // TODO(student): write 同步；read 行为 = 同步 / 异步（由 spec §4 决定）

    assign rd_data = 32'b0;

endmodule

// ============================================================================
// Module: ppa_packet_sram
// Description: 8x32-bit 双端口同步 SRAM
//   - 写端口来自 M1（APB 写入 PKT_MEM）
//   - 读端口来自 M3（处理阶段读取包数据）
//   - 复位时清零所有存储
// Ports: 详见 ppa-lite-spec.md 2.3 节 M2 端口表
// ============================================================================

module ppa_packet_sram (
    input  logic        clk,
    input  logic        rst_n,        // 复位（低有效，来自 ppa_top.PRESETn 映射）
    // 写端口（来自 M1）
    input  logic        wr_en,
    input  logic [2:0]  wr_addr,
    input  logic [31:0] wr_data,
    // 读端口（来自 M3）
    input  logic        rd_en,
    input  logic [2:0]  rd_addr,
    output logic [31:0] rd_data
);
    // ========================================================================
    // 存储单元
    // ========================================================================
    logic [31:0] mem [0:7];    // 约定：位宽大端在前，地址小端在后

    // ========================================================================
    // 写端口（同步写）
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= '{default:32'b0};    // SystemVerilog 语法：数组整体赋值为默认值
        end
        else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // ========================================================================
    // 读端口（同步读）
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin : blockName
        if (!rst_n) begin
            rd_data <= 32'b0;
        end
        else if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
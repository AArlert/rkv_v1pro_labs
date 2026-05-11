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

	// ========================================================================
	// 存储体：8 个 32-bit word
	// ========================================================================
	logic [31:0] mem [0:7];

	// ========================================================================
	// 写端口（同步写）
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			for (int i = 0; i < 8; i++)
				mem[i] <= 32'h0;
		end else if (wr_en) begin
			mem[wr_addr] <= wr_data;
		end
	end

	// ========================================================================
	// 读端口（同步读）
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			rd_data <= 32'h0;
		else if (rd_en)
			rd_data <= mem[rd_addr];
	end

endmodule

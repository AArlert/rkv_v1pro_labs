// ============================================================================
// Module: ppa_top
// Description: PPA-Lite 顶层模块
//   - 三子模块纯连线：M1(APB+CSR) / M2(SRAM) / M3(FSM+算法核)
//   - 统一分发 PCLK/PRESETn 到 M1/M2/M3
//   - M2 读端口仲裁：M3 处理时优先，空闲时 M1 APB 读 PKT_MEM
//   - 无额外状态逻辑
// Ports: 详见 ppa-lite-spec.md 2.3 节 Top 端口表
// ============================================================================

module ppa_top (
	// APB 接口
	input  logic        PCLK,
	input  logic        PRESETn,
	input  logic        PSEL,
	input  logic        PENABLE,
	input  logic        PWRITE,
	input  logic [11:0] PADDR,
	input  logic [31:0] PWDATA,
	output logic [31:0] PRDATA,
	output logic        PREADY,
	output logic        PSLVERR,

	// 中断输出
	output logic        irq_o
);

	// ========================================================================
	// 内部连线
	// ========================================================================

	// M1 -> M2 写端口
	logic        m1_pkt_mem_we;
	logic [2:0]  m1_pkt_mem_addr;
	logic [31:0] m1_pkt_mem_wdata;

	// M1 PKT_MEM 读请求
	logic        m1_pkt_mem_re;

	// M1 -> M3 控制信号
	logic        m1_start;
	logic        m1_algo_mode;
	logic [3:0]  m1_type_mask;
	logic [5:0]  m1_exp_pkt_len;

	// M3 -> M1 状态/结果
	logic        m3_busy;
	logic        m3_done;
	logic        m3_format_ok;
	logic        m3_length_error;
	logic        m3_type_error;
	logic        m3_chk_error;
	logic [5:0]  m3_res_pkt_len;
	logic [7:0]  m3_res_pkt_type;
	logic [7:0]  m3_res_payload_sum;
	logic [7:0]  m3_res_payload_xor;

	// M3 -> M2 读端口
	logic        m3_mem_rd_en;
	logic [2:0]  m3_mem_rd_addr;

	// M2 读端口（仲裁后）
	logic        m2_rd_en;
	logic [2:0]  m2_rd_addr;
	logic [31:0] m2_rd_data;

	// ========================================================================
	// M2 读端口仲裁：M3 优先，空闲时 M1 可 APB 读 PKT_MEM
	// ========================================================================
	assign m2_rd_en   = m3_mem_rd_en | m1_pkt_mem_re;
	assign m2_rd_addr = m3_mem_rd_en ? m3_mem_rd_addr : m1_pkt_mem_addr;

	// ========================================================================
	// M1: APB 从接口 + CSR
	// ========================================================================
	ppa_apb_slave_if u_m1 (
		.PCLK              (PCLK),
		.PRESETn           (PRESETn),
		.PSEL              (PSEL),
		.PENABLE           (PENABLE),
		.PWRITE            (PWRITE),
		.PADDR             (PADDR),
		.PWDATA            (PWDATA),
		.PRDATA            (PRDATA),
		.PREADY            (PREADY),
		.PSLVERR           (PSLVERR),
		.enable_o          (),
		.start_o           (m1_start),
		.algo_mode_o       (m1_algo_mode),
		.type_mask_o       (m1_type_mask),
		.exp_pkt_len_o     (m1_exp_pkt_len),
		.done_irq_en_o     (),
		.err_irq_en_o      (),
		.pkt_mem_we_o      (m1_pkt_mem_we),
		.pkt_mem_addr_o    (m1_pkt_mem_addr),
		.pkt_mem_wdata_o   (m1_pkt_mem_wdata),
		.pkt_mem_rdata_i   (m2_rd_data),
		.pkt_mem_re_o      (m1_pkt_mem_re),
		.busy_i            (m3_busy),
		.done_i            (m3_done),
		.format_ok_i       (m3_format_ok),
		.length_error_i    (m3_length_error),
		.type_error_i      (m3_type_error),
		.chk_error_i       (m3_chk_error),
		.res_pkt_len_i     (m3_res_pkt_len),
		.res_pkt_type_i    (m3_res_pkt_type),
		.res_payload_sum_i (m3_res_payload_sum),
		.res_payload_xor_i (m3_res_payload_xor),
		.irq_o             (irq_o)
	);

	// ========================================================================
	// M2: 8x32-bit 双端口同步 SRAM
	// ========================================================================
	ppa_packet_sram u_m2 (
		.clk     (PCLK),
		.rst_n   (PRESETn),
		.wr_en   (m1_pkt_mem_we),
		.wr_addr (m1_pkt_mem_addr),
		.wr_data (m1_pkt_mem_wdata),
		.rd_en   (m2_rd_en),
		.rd_addr (m2_rd_addr),
		.rd_data (m2_rd_data)
	);

	// ========================================================================
	// M3: 包处理核心（FSM + 算法）
	// ========================================================================
	ppa_packet_proc_core u_m3 (
		.clk               (PCLK),
		.rst_n             (PRESETn),
		.start_i           (m1_start),
		.algo_mode_i       (m1_algo_mode),
		.type_mask_i       (m1_type_mask),
		.exp_pkt_len_i     (m1_exp_pkt_len),
		.mem_rd_en_o       (m3_mem_rd_en),
		.mem_rd_addr_o     (m3_mem_rd_addr),
		.mem_rd_data_i     (m2_rd_data),
		.busy_o            (m3_busy),
		.done_o            (m3_done),
		.res_pkt_len_o     (m3_res_pkt_len),
		.res_pkt_type_o    (m3_res_pkt_type),
		.res_payload_sum_o (m3_res_payload_sum),
		.res_payload_xor_o (m3_res_payload_xor),
		.format_ok_o       (m3_format_ok),
		.length_error_o    (m3_length_error),
		.type_error_o      (m3_type_error),
		.chk_error_o       (m3_chk_error)
	);

endmodule

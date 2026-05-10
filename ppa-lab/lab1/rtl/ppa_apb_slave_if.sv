// ============================================================================
// Module: ppa_apb_slave_if
// Description: APB 3.0 从接口 + CSR 寄存器组
//   - 两段式传输：SETUP -> ACCESS
//   - PREADY 固定为 1，无等待状态
//   - CSR 区 0x000~0x028，PKT_MEM 区 0x040~0x05C
//   - 寄存器属性：RW / RO / W1P / RW1C
// Ports: 详见 ppa-lite-spec.md 2.3 节 M1 端口表
// ============================================================================

module ppa_apb_slave_if (
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

	// CSR 输出（送 M3 / 顶层）
	output logic        enable_o,
	output logic        start_o,
	output logic        algo_mode_o,
	output logic [3:0]  type_mask_o,
	output logic [5:0]  exp_pkt_len_o,
	output logic        done_irq_en_o,
	output logic        err_irq_en_o,

	// PKT_MEM 写端口（送 M2）
	output logic        pkt_mem_we_o,
	output logic [2:0]  pkt_mem_addr_o,
	output logic [31:0] pkt_mem_wdata_o,

	// M3 状态/结果输入
	input  logic        busy_i,
	input  logic        done_i,
	input  logic        format_ok_i,
	input  logic        length_error_i,
	input  logic        type_error_i,
	input  logic        chk_error_i,
	input  logic [5:0]  res_pkt_len_i,
	input  logic [7:0]  res_pkt_type_i,
	input  logic [7:0]  res_payload_sum_i,
	input  logic [7:0]  res_payload_xor_i,

	// 中断输出
	output logic        irq_o
);

	// ========================================================================
	// 内部信号
	// ========================================================================
	logic apb_write;
	logic apb_read;

	assign PREADY = 1'b1;
	assign apb_write = PSEL & PENABLE & PWRITE;
	assign apb_read  = PSEL & PENABLE & ~PWRITE;

	// ========================================================================
	// CSR 寄存器定义
	// ========================================================================
	logic        reg_enable;
	logic        start_pulse;

	logic        reg_algo_mode;
	logic [3:0]  reg_type_mask;

	logic        reg_done_irq_en;
	logic        reg_err_irq_en;

	logic        reg_done_irq;
	logic        reg_err_irq;

	logic [5:0]  reg_exp_pkt_len;

	logic        done_i_d;
	logic        done_rising;

	logic        slverr_comb;

	// ========================================================================
	// 地址常量
	// ========================================================================
	localparam logic [11:0] ADDR_CTRL            = 12'h000;
	localparam logic [11:0] ADDR_CFG             = 12'h004;
	localparam logic [11:0] ADDR_STATUS          = 12'h008;
	localparam logic [11:0] ADDR_IRQ_EN          = 12'h00C;
	localparam logic [11:0] ADDR_IRQ_STA         = 12'h010;
	localparam logic [11:0] ADDR_PKT_LEN_EXP     = 12'h014;
	localparam logic [11:0] ADDR_RES_PKT_LEN     = 12'h018;
	localparam logic [11:0] ADDR_RES_PKT_TYPE    = 12'h01C;
	localparam logic [11:0] ADDR_RES_PAYLOAD_SUM = 12'h020;
	localparam logic [11:0] ADDR_RES_PAYLOAD_XOR = 12'h024;
	localparam logic [11:0] ADDR_ERR_FLAG        = 12'h028;
	localparam logic [11:0] ADDR_PKT_MEM_BASE    = 12'h040;
	localparam logic [11:0] ADDR_PKT_MEM_END     = 12'h05C;

	// ========================================================================
	// PKT_MEM 地址范围判断
	// ========================================================================
	logic is_pkt_mem;
	logic is_csr;
	logic is_valid_addr;

	assign is_pkt_mem = (PADDR >= ADDR_PKT_MEM_BASE) && (PADDR <= ADDR_PKT_MEM_END)
	                    && (PADDR[1:0] == 2'b00);
	assign is_csr = (PADDR <= ADDR_ERR_FLAG) && (PADDR[1:0] == 2'b00);
	assign is_valid_addr = is_csr || is_pkt_mem;

	// ========================================================================
	// 判断只读寄存器写操作
	// ========================================================================
	logic write_ro;
	assign write_ro = apb_write && (
		PADDR == ADDR_STATUS          ||
		PADDR == ADDR_RES_PKT_LEN     ||
		PADDR == ADDR_RES_PKT_TYPE    ||
		PADDR == ADDR_RES_PAYLOAD_SUM ||
		PADDR == ADDR_RES_PAYLOAD_XOR ||
		PADDR == ADDR_ERR_FLAG
	);

	// ========================================================================
	// PSLVERR 生成
	// ========================================================================
	logic write_pktmem_busy;
	assign write_pktmem_busy = apb_write && is_pkt_mem && busy_i;

	always_comb begin
		slverr_comb = 1'b0;
		if (PSEL && PENABLE) begin
			if (!is_valid_addr)
				slverr_comb = 1'b1;
			else if (write_ro)
				slverr_comb = 1'b1;
			else if (write_pktmem_busy)
				slverr_comb = 1'b1;
		end
	end

	assign PSLVERR = slverr_comb;

	// ========================================================================
	// start 脉冲逻辑：仅在 enable=1 && busy=0 时接受
	// ========================================================================
	logic start_accepted;
	assign start_accepted = apb_write && (PADDR == ADDR_CTRL)
	                        && PWDATA[1] && reg_enable && !busy_i;

	// ========================================================================
	// CSR 写逻辑（时序）
	// ========================================================================
	always_ff @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			reg_enable       <= 1'b0;
			reg_algo_mode    <= 1'b1;
			reg_type_mask    <= 4'b1111;
			reg_done_irq_en  <= 1'b0;
			reg_err_irq_en   <= 1'b0;
			reg_exp_pkt_len  <= 6'b0;
			reg_done_irq     <= 1'b0;
			reg_err_irq      <= 1'b0;
			done_i_d         <= 1'b0;
			start_pulse      <= 1'b0;
		end else begin
			done_i_d <= done_i;

			start_pulse <= start_accepted;

			if (apb_write && (PADDR == ADDR_CTRL))
				reg_enable <= PWDATA[0];

			if (apb_write && (PADDR == ADDR_CFG)) begin
				reg_algo_mode <= PWDATA[0];
				reg_type_mask <= PWDATA[7:4];
			end

			if (apb_write && (PADDR == ADDR_IRQ_EN)) begin
				reg_done_irq_en <= PWDATA[0];
				reg_err_irq_en  <= PWDATA[1];
			end

			if (apb_write && (PADDR == ADDR_PKT_LEN_EXP))
				reg_exp_pkt_len <= PWDATA[5:0];

			if (apb_write && (PADDR == ADDR_IRQ_STA)) begin
				if (PWDATA[0]) reg_done_irq <= 1'b0;
				if (PWDATA[1]) reg_err_irq  <= 1'b0;
			end else begin
				if (done_rising && reg_done_irq_en)
					reg_done_irq <= 1'b1;
				if (done_rising && (length_error_i | type_error_i | chk_error_i) && reg_err_irq_en)
					reg_err_irq <= 1'b1;
			end
		end
	end

	assign done_rising = done_i & ~done_i_d;

	// ========================================================================
	// CSR 读逻辑（组合）
	// ========================================================================
	always_comb begin
		PRDATA = 32'h0;
		if (apb_read) begin
			case (PADDR)
				ADDR_CTRL:            PRDATA = {30'b0, 1'b0, reg_enable};
				ADDR_CFG:             PRDATA = {24'b0, reg_type_mask, 3'b0, reg_algo_mode};
				ADDR_STATUS:          PRDATA = {28'b0, format_ok_i, (length_error_i | type_error_i | chk_error_i), done_i, busy_i};
				ADDR_IRQ_EN:          PRDATA = {30'b0, reg_err_irq_en, reg_done_irq_en};
				ADDR_IRQ_STA:         PRDATA = {30'b0, reg_err_irq, reg_done_irq};
				ADDR_PKT_LEN_EXP:     PRDATA = {26'b0, reg_exp_pkt_len};
				ADDR_RES_PKT_LEN:     PRDATA = {26'b0, res_pkt_len_i};
				ADDR_RES_PKT_TYPE:    PRDATA = {24'b0, res_pkt_type_i};
				ADDR_RES_PAYLOAD_SUM: PRDATA = {24'b0, res_payload_sum_i};
				ADDR_RES_PAYLOAD_XOR: PRDATA = {24'b0, res_payload_xor_i};
				ADDR_ERR_FLAG:        PRDATA = {29'b0, chk_error_i, type_error_i, length_error_i};
				default: PRDATA = 32'h0;
			endcase
		end
	end

	// ========================================================================
	// PKT_MEM 写端口输出
	// ========================================================================
	assign pkt_mem_we_o    = apb_write && is_pkt_mem && !busy_i;
	assign pkt_mem_addr_o  = PADDR[4:2];
	assign pkt_mem_wdata_o = PWDATA;

	// ========================================================================
	// CSR 输出端口映射
	// ========================================================================
	assign enable_o       = reg_enable;
	assign start_o        = start_pulse;
	assign algo_mode_o    = reg_algo_mode;
	assign type_mask_o    = reg_type_mask;
	assign exp_pkt_len_o  = reg_exp_pkt_len;
	assign done_irq_en_o  = reg_done_irq_en;
	assign err_irq_en_o   = reg_err_irq_en;

	// ========================================================================
	// 中断输出
	// ========================================================================
	assign irq_o = reg_done_irq | reg_err_irq;

endmodule

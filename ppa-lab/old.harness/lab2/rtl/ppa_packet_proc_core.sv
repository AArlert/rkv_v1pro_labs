// ============================================================================
// Module: ppa_packet_proc_core
// Description: M3 包处理核心 - 3 态 FSM + 包头解析 + 格式检查 + payload 计算
//   - IDLE→PROCESS→DONE 三态状态机
//   - 从 SRAM(M2) 读取包数据，解析包头，执行格式检查
//   - 计算 payload 字节和(sum) 与逐位异或(XOR)
//   - 三类错误(length/type/chk)可并行成立
//   - DONE 态结果保持至下次 start
// Ports: 详见 ppa-lite-spec.md §2.3 M3 端口表
// Parameters: 无
// ============================================================================

module ppa_packet_proc_core (
	input  logic        clk,
	input  logic        rst_n,

	// 控制输入（来自 M1）
	input  logic        start_i,
	input  logic        algo_mode_i,
	input  logic [3:0]  type_mask_i,
	input  logic [5:0]  exp_pkt_len_i,

	// SRAM 读端口（连接 M2）
	output logic        mem_rd_en_o,
	output logic [2:0]  mem_rd_addr_o,
	input  logic [31:0] mem_rd_data_i,

	// 状态输出
	output logic        busy_o,
	output logic        done_o,

	// 结果输出
	output logic [5:0]  res_pkt_len_o,
	output logic [7:0]  res_pkt_type_o,
	output logic [7:0]  res_payload_sum_o,
	output logic [7:0]  res_payload_xor_o,

	// 格式检查输出
	output logic        format_ok_o,
	output logic        length_error_o,
	output logic        type_error_o,
	output logic        chk_error_o
);

	// ========================================================================
	// FSM 状态编码
	// ========================================================================
	typedef enum logic [1:0] {
		ST_IDLE    = 2'b00,
		ST_PROCESS = 2'b01,
		ST_DONE    = 2'b10
	} state_t;

	state_t state, next_state;

	// ========================================================================
	// 内部寄存器
	// ========================================================================
	logic [3:0] word_cnt;
	logic [3:0] total_words;
	logic [7:0] pkt_len_reg;

	logic [5:0]  res_pkt_len_reg;
	logic [7:0]  res_pkt_type_reg;
	logic [7:0]  payload_sum;
	logic [7:0]  payload_xor;
	logic        format_ok_reg;
	logic        len_err_reg;
	logic        type_err_reg;
	logic        chk_err_reg;

	// ========================================================================
	// 组合逻辑：从 rd_data 提取 header 字段（仅在 word_cnt==0 时有效）
	// ========================================================================
	logic [7:0] raw_pkt_len;
	logic [7:0] raw_pkt_type;
	logic [7:0] raw_flags;
	logic [7:0] raw_hdr_chk;

	assign raw_pkt_len  = mem_rd_data_i[7:0];
	assign raw_pkt_type = mem_rd_data_i[15:8];
	assign raw_flags    = mem_rd_data_i[23:16];
	assign raw_hdr_chk  = mem_rd_data_i[31:24];

	// ========================================================================
	// 组合逻辑：total_words 计算 = ceil(pkt_len/4), clamp [1,8]
	// ========================================================================
	logic [3:0] total_words_comb;

	always_comb begin
		logic [5:0] tw_raw;
		tw_raw = {raw_pkt_len[7:2]} + ({5'b0, |raw_pkt_len[1:0]});
		if (tw_raw == 6'd0)
			total_words_comb = 4'd1;
		else if (tw_raw > 6'd8)
			total_words_comb = 4'd8;
		else
			total_words_comb = tw_raw[3:0];
	end

	logic [3:0] total_words_active;
	assign total_words_active = (state == ST_PROCESS && word_cnt == 4'd0)
	                          ? total_words_comb : total_words;

	// ========================================================================
	// 组合逻辑：格式检查（在 word_cnt==0 时基于 rd_data 计算）
	// ========================================================================
	logic len_err_comb, type_err_comb, chk_err_comb, fmt_ok_comb;

	always_comb begin
		len_err_comb = (raw_pkt_len < 8'd4) || (raw_pkt_len > 8'd32)
		             || (exp_pkt_len_i != 6'd0 && raw_pkt_len != {2'b0, exp_pkt_len_i});

		case (raw_pkt_type)
			8'h01:   type_err_comb = ~type_mask_i[0];
			8'h02:   type_err_comb = ~type_mask_i[1];
			8'h04:   type_err_comb = ~type_mask_i[2];
			8'h08:   type_err_comb = ~type_mask_i[3];
			default: type_err_comb = 1'b1;
		endcase

		if (algo_mode_i)
			chk_err_comb = (raw_hdr_chk != (raw_pkt_len ^ raw_pkt_type ^ raw_flags));
		else
			chk_err_comb = 1'b0;

		fmt_ok_comb = ~(len_err_comb | type_err_comb | chk_err_comb);
	end

	// ========================================================================
	// 组合逻辑：payload 字节处理（word_cnt > 0 时有效）
	// ========================================================================
	logic [7:0] b0, b1, b2, b3;
	assign b0 = mem_rd_data_i[7:0];
	assign b1 = mem_rd_data_i[15:8];
	assign b2 = mem_rd_data_i[23:16];
	assign b3 = mem_rd_data_i[31:24];

	logic [2:0] last_word_bytes;
	always_comb begin
		case (pkt_len_reg[1:0])
			2'b00: last_word_bytes = 3'd4;
			2'b01: last_word_bytes = 3'd1;
			2'b10: last_word_bytes = 3'd2;
			2'b11: last_word_bytes = 3'd3;
		endcase
	end

	logic is_last_word;
	assign is_last_word = (word_cnt == total_words - 4'd1);

	logic [2:0] valid_bytes;
	assign valid_bytes = is_last_word ? last_word_bytes : 3'd4;

	logic [7:0] word_sum, word_xor;
	always_comb begin
		word_sum = 8'd0;
		word_xor = 8'd0;
		if (valid_bytes >= 3'd1) begin word_sum = b0;              word_xor = b0; end
		if (valid_bytes >= 3'd2) begin word_sum = word_sum + b1;   word_xor = word_xor ^ b1; end
		if (valid_bytes >= 3'd3) begin word_sum = word_sum + b2;   word_xor = word_xor ^ b2; end
		if (valid_bytes >= 3'd4) begin word_sum = word_sum + b3;   word_xor = word_xor ^ b3; end
	end

	// ========================================================================
	// FSM：状态寄存器
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			state <= ST_IDLE;
		else
			state <= next_state;
	end

	// ========================================================================
	// FSM：次态逻辑
	// ========================================================================
	always_comb begin
		next_state = state;
		case (state)
			ST_IDLE: begin
				if (start_i)
					next_state = ST_PROCESS;
			end
			ST_PROCESS: begin
				if (word_cnt == total_words_active - 4'd1)
					next_state = ST_DONE;
			end
			ST_DONE: begin
				if (start_i)
					next_state = ST_PROCESS;
			end
			default: next_state = ST_IDLE;
		endcase
	end

	// ========================================================================
	// 数据通路：寄存器更新
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			word_cnt        <= 4'd0;
			total_words     <= 4'd1;
			pkt_len_reg     <= 8'd0;
			res_pkt_len_reg <= 6'd0;
			res_pkt_type_reg<= 8'd0;
			payload_sum     <= 8'd0;
			payload_xor     <= 8'd0;
			format_ok_reg   <= 1'b0;
			len_err_reg     <= 1'b0;
			type_err_reg    <= 1'b0;
			chk_err_reg     <= 1'b0;
		end else begin
			case (state)
				ST_IDLE, ST_DONE: begin
					if (start_i) begin
						word_cnt        <= 4'd0;
						payload_sum     <= 8'd0;
						payload_xor     <= 8'd0;
						res_pkt_len_reg <= 6'd0;
						res_pkt_type_reg<= 8'd0;
						format_ok_reg   <= 1'b0;
						len_err_reg     <= 1'b0;
						type_err_reg    <= 1'b0;
						chk_err_reg     <= 1'b0;
					end
				end

				ST_PROCESS: begin
					if (word_cnt == 4'd0) begin
						pkt_len_reg      <= raw_pkt_len;
						total_words      <= total_words_comb;
						res_pkt_len_reg  <= raw_pkt_len[5:0];
						res_pkt_type_reg <= raw_pkt_type;
						len_err_reg      <= len_err_comb;
						type_err_reg     <= type_err_comb;
						chk_err_reg      <= chk_err_comb;
						format_ok_reg    <= fmt_ok_comb;
						word_cnt         <= 4'd1;
					end else begin
						payload_sum <= payload_sum + word_sum;
						payload_xor <= payload_xor ^ word_xor;
						word_cnt    <= word_cnt + 4'd1;
					end
				end

				default: ;
			endcase
		end
	end

	// ========================================================================
	// 输出赋值
	// ========================================================================
	assign busy_o = (state == ST_PROCESS);
	assign done_o = (state == ST_DONE);

	assign res_pkt_len_o     = res_pkt_len_reg;
	assign res_pkt_type_o    = res_pkt_type_reg;
	assign res_payload_sum_o = payload_sum;
	assign res_payload_xor_o = payload_xor;
	assign format_ok_o       = format_ok_reg;
	assign length_error_o    = len_err_reg;
	assign type_error_o      = type_err_reg;
	assign chk_error_o       = chk_err_reg;

	// ========================================================================
	// SRAM 读控制（Mealy 输出：转移时预取 Word0）
	// ========================================================================
	always_comb begin
		mem_rd_en_o   = 1'b0;
		mem_rd_addr_o = 3'd0;

		case (state)
			ST_IDLE, ST_DONE: begin
				if (start_i) begin
					mem_rd_en_o   = 1'b1;
					mem_rd_addr_o = 3'd0;
				end
			end
			ST_PROCESS: begin
				if (word_cnt == 4'd0) begin
					if (total_words_comb > 4'd1) begin
						mem_rd_en_o   = 1'b1;
						mem_rd_addr_o = 3'd1;
					end
				end else if (word_cnt < total_words - 4'd1) begin
					mem_rd_en_o   = 1'b1;
					mem_rd_addr_o = word_cnt[2:0] + 3'd1;
				end
			end
			default: ;
		endcase
	end

endmodule

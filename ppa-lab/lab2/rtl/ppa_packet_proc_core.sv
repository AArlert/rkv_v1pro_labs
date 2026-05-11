// ============================================================================
// Module: ppa_packet_proc_core
// Description: M3 包处理核心
//   - 3 态 FSM：IDLE -> PROCESS -> DONE（spec §7.1 §7.2）
//   - 从 M2 同步 SRAM 流式读取（1 拍读延迟）
//   - 解析包头、长度/类型/头校验、payload sum/XOR
//   - mem_rd_en_o / mem_rd_addr_o 为组合输出，保证 start 当拍即可启动 word0 读
//   - 错误三类并行（spec §9.1 §9.2）；DONE 态结果保持至下次 start 接受
// Ports: 详见 ppa-lite-spec.md 2.3 节 M3 端口表
// ============================================================================

module ppa_packet_proc_core (
	input  logic        clk,
	input  logic        rst_n,

	// 控制
	input  logic        start_i,
	input  logic        algo_mode_i,
	input  logic [3:0]  type_mask_i,
	input  logic [5:0]  exp_pkt_len_i,

	// SRAM 读端口
	output logic        mem_rd_en_o,
	output logic [2:0]  mem_rd_addr_o,
	input  logic [31:0] mem_rd_data_i,

	// 状态
	output logic        busy_o,
	output logic        done_o,

	// 解析结果
	output logic [5:0]  res_pkt_len_o,
	output logic [7:0]  res_pkt_type_o,
	output logic [7:0]  res_payload_sum_o,
	output logic [7:0]  res_payload_xor_o,

	// 错误标志
	output logic        format_ok_o,
	output logic        length_error_o,
	output logic        type_error_o,
	output logic        chk_error_o
);

	// ========================================================================
	// FSM 状态
	// ========================================================================
	typedef enum logic [1:0] {
		S_IDLE    = 2'd0,
		S_PROCESS = 2'd1,
		S_DONE    = 2'd2
	} state_t;

	state_t     state;
	logic [3:0] issue_idx;     // 下一拍要发起读的 word 索引（0..8）
	logic [3:0] consume_idx;   // 下一个待消费的 word 索引（0..8）
	logic [3:0] words_total;   // 本帧需读取的 word 总数（1..8）
	logic [5:0] pkt_len_q;     // 已锁存的 pkt_len，用于 payload 字节有效性判断

	// ========================================================================
	// 包头解析组合逻辑
	// ========================================================================
	logic [7:0] hdr_b0, hdr_b1, hdr_b2, hdr_b3;
	logic       hdr_type_one_hot;
	logic [1:0] hdr_type_idx;
	logic       hdr_type_allowed;
	logic       hdr_len_err;
	logic       hdr_type_err;
	logic       hdr_chk_err;
	logic [3:0] hdr_words_total;
	logic [5:0] hdr_pkt_len_p3;

	assign hdr_b0 = mem_rd_data_i[7:0];
	assign hdr_b1 = mem_rd_data_i[15:8];
	assign hdr_b2 = mem_rd_data_i[23:16];
	assign hdr_b3 = mem_rd_data_i[31:24];

	always_comb begin
		hdr_type_one_hot = 1'b1;
		hdr_type_idx     = 2'd0;
		case (hdr_b1)
			8'h01: hdr_type_idx = 2'd0;
			8'h02: hdr_type_idx = 2'd1;
			8'h04: hdr_type_idx = 2'd2;
			8'h08: hdr_type_idx = 2'd3;
			default: hdr_type_one_hot = 1'b0;
		endcase
	end
	assign hdr_type_allowed = hdr_type_one_hot && type_mask_i[hdr_type_idx];

	assign hdr_len_err  = (hdr_b0 < 8'd4) || (hdr_b0 > 8'd32) ||
	                      ((exp_pkt_len_i != 6'd0) && (hdr_b0[5:0] != exp_pkt_len_i));
	assign hdr_type_err = !hdr_type_allowed;
	assign hdr_chk_err  = algo_mode_i && (hdr_b3 != (hdr_b0 ^ hdr_b1 ^ hdr_b2));

	// 越界时只消费 1 word（防卡死，F2-13）；合法时 ceil(pkt_len/4)
	assign hdr_pkt_len_p3  = hdr_b0[5:0] + 6'd3;
	assign hdr_words_total = ((hdr_b0 < 8'd4) || (hdr_b0 > 8'd32))
	                         ? 4'd1
	                         : {1'b0, hdr_pkt_len_p3[5:2]};

	// ========================================================================
	// SRAM 读端口组合输出
	//   - IDLE/DONE 收到 start_i：当拍发起 word0 读
	//   - PROCESS 中：当 issue_idx < words_total 时继续发起
	// ========================================================================
	always_comb begin
		mem_rd_en_o   = 1'b0;
		mem_rd_addr_o = 3'd0;
		if ((state == S_IDLE && start_i) || (state == S_DONE && start_i)) begin
			mem_rd_en_o   = 1'b1;
			mem_rd_addr_o = 3'd0;
		end else if (state == S_PROCESS) begin
			if (issue_idx < words_total) begin
				mem_rd_en_o   = 1'b1;
				mem_rd_addr_o = issue_idx[2:0];
			end
		end
	end

	// ========================================================================
	// 主时序逻辑
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin : main_seq
		automatic logic [7:0] sum_n;
		automatic logic [7:0] xor_n;
		automatic logic [7:0] payload_byte;
		automatic logic [6:0] byte_offset;
		automatic int         k;

		if (!rst_n) begin
			state             <= S_IDLE;
			busy_o            <= 1'b0;
			done_o            <= 1'b0;
			issue_idx         <= 4'd0;
			consume_idx       <= 4'd0;
			words_total       <= 4'd0;
			pkt_len_q         <= 6'd0;
			res_pkt_len_o     <= 6'd0;
			res_pkt_type_o    <= 8'd0;
			res_payload_sum_o <= 8'd0;
			res_payload_xor_o <= 8'd0;
			format_ok_o       <= 1'b0;
			length_error_o    <= 1'b0;
			type_error_o      <= 1'b0;
			chk_error_o       <= 1'b0;
		end else begin
			case (state)
				// ------------------------------------------------------------
				S_IDLE: begin
					busy_o <= 1'b0;
					if (start_i) begin
						state             <= S_PROCESS;
						busy_o            <= 1'b1;
						done_o            <= 1'b0;
						// 清结果/错误（spec §9.3）
						res_pkt_len_o     <= 6'd0;
						res_pkt_type_o    <= 8'd0;
						res_payload_sum_o <= 8'd0;
						res_payload_xor_o <= 8'd0;
						format_ok_o       <= 1'b0;
						length_error_o    <= 1'b0;
						type_error_o      <= 1'b0;
						chk_error_o       <= 1'b0;
						// 组合逻辑已驱动 rd_en=1, addr=0 → SRAM 本拍锁存 word0
						issue_idx         <= 4'd1;   // 下一拍发起 word1 读
						consume_idx       <= 4'd0;
						words_total       <= 4'd8;   // 暂用默认，header 到来时更新
						pkt_len_q         <= 6'd0;
					end
				end

				// ------------------------------------------------------------
				S_PROCESS: begin
					// 本拍 mem_rd_data_i 对应 word[consume_idx]
					if (consume_idx == 4'd0) begin
						// ---- 处理 header ----
						res_pkt_len_o  <= hdr_b0[5:0];
						res_pkt_type_o <= hdr_b1;
						pkt_len_q      <= hdr_b0[5:0];
						length_error_o <= hdr_len_err;
						type_error_o   <= hdr_type_err;
						chk_error_o    <= hdr_chk_err;
						words_total    <= hdr_words_total;

						if (hdr_words_total == 4'd1) begin
							state       <= S_DONE;
							busy_o      <= 1'b0;
							done_o      <= 1'b1;
							format_ok_o <= !hdr_len_err && !hdr_type_err && !hdr_chk_err;
						end
						consume_idx <= consume_idx + 4'd1;
					end else begin
						// ---- 处理 payload word ----
						sum_n = res_payload_sum_o;
						xor_n = res_payload_xor_o;
						for (k = 0; k < 4; k = k + 1) begin
							byte_offset  = {3'b0, consume_idx} * 7'd4 + k[6:0];
							payload_byte = mem_rd_data_i[8*k +: 8];
							if (byte_offset < {1'b0, pkt_len_q}) begin
								sum_n = sum_n + payload_byte;
								xor_n = xor_n ^ payload_byte;
							end
						end
						res_payload_sum_o <= sum_n;
						res_payload_xor_o <= xor_n;

						if (consume_idx == (words_total - 4'd1)) begin
							state       <= S_DONE;
							busy_o      <= 1'b0;
							done_o      <= 1'b1;
							format_ok_o <= !length_error_o && !type_error_o && !chk_error_o;
						end
						consume_idx <= consume_idx + 4'd1;
					end

					// 推进 issue_idx（组合逻辑已驱动本拍 rd_en/addr）
					if (issue_idx < words_total)
						issue_idx <= issue_idx + 4'd1;
				end

				// ------------------------------------------------------------
				S_DONE: begin
					busy_o <= 1'b0;
					if (start_i) begin
						state             <= S_PROCESS;
						busy_o            <= 1'b1;
						done_o            <= 1'b0;
						res_pkt_len_o     <= 6'd0;
						res_pkt_type_o    <= 8'd0;
						res_payload_sum_o <= 8'd0;
						res_payload_xor_o <= 8'd0;
						format_ok_o       <= 1'b0;
						length_error_o    <= 1'b0;
						type_error_o      <= 1'b0;
						chk_error_o       <= 1'b0;
						issue_idx         <= 4'd1;
						consume_idx       <= 4'd0;
						words_total       <= 4'd8;
						pkt_len_q         <= 6'd0;
					end
				end

				default: state <= S_IDLE;
			endcase
		end
	end : main_seq

endmodule

// ============================================================================
// Module: ppa_packet_proc_core
// Description: 包处理核心模块（M3）
//   - 3 态 FSM：IDLE → PROCESS → DONE
//   - 包头解析：pkt_len / pkt_type / flags / hdr_chk
//   - 格式检查：长度范围 [4,32]、类型 one-hot + type_mask、头校验
//   - Payload 计算：字节累加和（sum）与逐位异或（xor），8-bit 截断
//   - 同步读 SRAM：发出地址后下一拍返回数据
// Ports: 详见 ppa-lite-spec.md 2.3 节 M3 端口表
// Parameters: 无
// ============================================================================

module ppa_packet_proc_core (
	input  logic        clk,
	input  logic        rst_n,

	// 来自 M1 的控制信号
	input  logic        start_i,
	input  logic        algo_mode_i,
	input  logic [3:0]  type_mask_i,
	input  logic [5:0]  exp_pkt_len_i,

	// SRAM 读端口（连接 M2）
	output logic        mem_rd_en_o,
	output logic [2:0]  mem_rd_addr_o,
	input  logic [31:0] mem_rd_data_i,

	// 状态输出（送 M1）
	output logic        busy_o,
	output logic        done_o,

	// 结果输出（送 M1）
	output logic [5:0]  res_pkt_len_o,
	output logic [7:0]  res_pkt_type_o,
	output logic [7:0]  res_payload_sum_o,
	output logic [7:0]  res_payload_xor_o,

	// 错误与格式标志（送 M1）
	output logic        format_ok_o,
	output logic        length_error_o,
	output logic        type_error_o,
	output logic        chk_error_o
);

	// ========================================================================
	// FSM 状态定义
	// ========================================================================
	typedef enum logic [1:0] {
		S_IDLE    = 2'b00,
		S_PROCESS = 2'b01,
		S_DONE    = 2'b10
	} state_t;

	state_t state, next_state;

	// ========================================================================
	// 内部寄存器
	// ========================================================================
	// beat: PROCESS 态内的拍计数器
	//   beat=0: 收到 Word0（头部），解析并执行检查
	//   beat=1..N-1: 收到 Word1..N-1（payload），逐字节累加
	//   SRAM 同步读有 1 拍延迟：转移拍发出 addr=0，beat=0 收到数据
	logic [3:0]  beat;
	logic        hdr_valid;       // 头部已解析标志（beat=0 时设置，beat=1 可用）
	logic [3:0]  eff_total_words; // 需要读取的有效 word 数（1~8）
	logic [5:0]  pkt_len;         // 解析出的 6-bit 包长
	logic [7:0]  pkt_type;        // 解析出的包类型
	logic [5:0]  payload_len;     // 有效 payload 字节数 = pkt_len - 4
	logic [5:0]  bytes_processed; // 已处理的 payload 字节数
	logic [7:0]  sum_acc;         // payload 字节累加和
	logic [7:0]  xor_acc;         // payload 字节 XOR
	logic        len_err;         // 长度错误标志
	logic        typ_err;         // 类型错误标志
	logic        chk_err;         // 校验错误标志

	// ========================================================================
	// 组合信号：payload 逐字节处理
	// ========================================================================
	logic [7:0]  new_sum;
	logic [7:0]  new_xor;
	logic [5:0]  remaining;
	logic [2:0]  valid_bytes;
	logic        do_payload;      // 本拍是否处理 payload 数据

	// ========================================================================
	// FSM 状态寄存器
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) state <= S_IDLE;
		else        state <= next_state;
	end

	// ========================================================================
	// FSM 次态逻辑
	// ========================================================================
	always_comb begin
		next_state = state;
		case (state)
			S_IDLE:    if (start_i) next_state = S_PROCESS;
			S_PROCESS: if (hdr_valid && (beat + 4'd1 >= eff_total_words))
			               next_state = S_DONE;
			S_DONE:    if (start_i) next_state = S_PROCESS;
			default:   next_state = S_IDLE;
		endcase
	end

	// ========================================================================
	// busy_o：PROCESS 态为 1
	// ========================================================================
	assign busy_o = (state == S_PROCESS);

	// ========================================================================
	// SRAM 读端口（组合）
	// 转移拍：发出 addr=0
	// beat=0：发出 addr=1（乐观发出，不等 eff_total_words）
	// beat>=1：若还有后续 word 则继续发出
	// ========================================================================
	always_comb begin
		mem_rd_en_o   = 1'b0;
		mem_rd_addr_o = 3'd0;
		if ((state == S_IDLE || state == S_DONE) && start_i) begin
			// IDLE/DONE → PROCESS 转移拍，发出首个读请求
			mem_rd_en_o   = 1'b1;
			mem_rd_addr_o = 3'd0;
		end else if (state == S_PROCESS) begin
			if (!hdr_valid) begin
				// beat=0：头部数据本拍到达，乐观发出 addr=1
				mem_rd_en_o   = 1'b1;
				mem_rd_addr_o = 3'd1;
			end else if (beat + 4'd1 < eff_total_words && beat < 4'd7) begin
				// 还有后续 word，发出下一个地址
				mem_rd_en_o   = 1'b1;
				mem_rd_addr_o = beat[2:0] + 3'd1;
			end
		end
	end

	// ========================================================================
	// Payload 逐字节处理（组合）
	// 在 PROCESS 态，hdr_valid=1 且 beat 对应有效 payload word 时执行
	// ========================================================================
	always_comb begin
		new_sum    = sum_acc;
		new_xor    = xor_acc;
		do_payload = 1'b0;
		remaining  = 6'd0;
		valid_bytes = 3'd0;

		if (state == S_PROCESS && hdr_valid && beat >= 4'd1 && beat < eff_total_words) begin
			do_payload = 1'b1;
			remaining  = payload_len - bytes_processed;
			valid_bytes = (remaining >= 6'd4) ? 3'd4 : remaining[2:0];

			if (valid_bytes >= 3'd1) begin
				new_sum = new_sum + mem_rd_data_i[7:0];
				new_xor = new_xor ^ mem_rd_data_i[7:0];
			end
			if (valid_bytes >= 3'd2) begin
				new_sum = new_sum + mem_rd_data_i[15:8];
				new_xor = new_xor ^ mem_rd_data_i[15:8];
			end
			if (valid_bytes >= 3'd3) begin
				new_sum = new_sum + mem_rd_data_i[23:16];
				new_xor = new_xor ^ mem_rd_data_i[23:16];
			end
			if (valid_bytes >= 3'd4) begin
				new_sum = new_sum + mem_rd_data_i[31:24];
				new_xor = new_xor ^ mem_rd_data_i[31:24];
			end
		end
	end

	// ========================================================================
	// 主数据通路（时序）
	// ========================================================================
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			beat            <= 4'd0;
			hdr_valid       <= 1'b0;
			eff_total_words <= 4'd1;
			pkt_len         <= 6'd0;
			pkt_type        <= 8'd0;
			payload_len     <= 6'd0;
			bytes_processed <= 6'd0;
			sum_acc         <= 8'd0;
			xor_acc         <= 8'd0;
			len_err         <= 1'b0;
			typ_err         <= 1'b0;
			chk_err         <= 1'b0;
			done_o            <= 1'b0;
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
				// --------------------------------------------------------
				// IDLE：等待 start
				// --------------------------------------------------------
				S_IDLE: begin
					if (start_i) begin
						// 初始化所有内部状态
						beat            <= 4'd0;
						hdr_valid       <= 1'b0;
						eff_total_words <= 4'd1;
						sum_acc         <= 8'd0;
						xor_acc         <= 8'd0;
						bytes_processed <= 6'd0;
						len_err         <= 1'b0;
						typ_err         <= 1'b0;
						chk_err         <= 1'b0;
						// 清除上一帧输出
						done_o            <= 1'b0;
						res_pkt_len_o     <= 6'd0;
						res_pkt_type_o    <= 8'd0;
						res_payload_sum_o <= 8'd0;
						res_payload_xor_o <= 8'd0;
						format_ok_o       <= 1'b0;
						length_error_o    <= 1'b0;
						type_error_o      <= 1'b0;
						chk_error_o       <= 1'b0;
					end
				end

				// --------------------------------------------------------
				// PROCESS：读取和处理数据
				// --------------------------------------------------------
				S_PROCESS: begin
					beat <= beat + 4'd1;

					// --- beat=0：解析 Word0 头部 ---
					if (beat == 4'd0) begin
						hdr_valid <= 1'b1;
						pkt_len   <= mem_rd_data_i[5:0];
						pkt_type  <= mem_rd_data_i[15:8];

						// 有效 total words 计算
						// ceil(pkt_len/4)，对长度越界则只读 1 word（头部）
						if (mem_rd_data_i[7:0] < 8'd4 || mem_rd_data_i[7:0] > 8'd32) begin
							eff_total_words <= 4'd1;
							payload_len     <= 6'd0;
						end else begin
							// (pkt_len + 3) >> 2 = ceil(pkt_len / 4)
							eff_total_words <= ({2'b00, mem_rd_data_i[5:0]} + 8'd3) >> 2;
							payload_len     <= mem_rd_data_i[5:0] - 6'd4;
						end

						// 长度检查
						len_err <= (mem_rd_data_i[7:0] < 8'd4 || mem_rd_data_i[7:0] > 8'd32) ||
						           (exp_pkt_len_i != 6'd0 && mem_rd_data_i[5:0] != exp_pkt_len_i);

						// 类型检查
						case (mem_rd_data_i[15:8])
							8'h01:   typ_err <= !type_mask_i[0];
							8'h02:   typ_err <= !type_mask_i[1];
							8'h04:   typ_err <= !type_mask_i[2];
							8'h08:   typ_err <= !type_mask_i[3];
							default: typ_err <= 1'b1;
						endcase

						// 头校验检查
						if (algo_mode_i)
							chk_err <= (mem_rd_data_i[31:24] !=
							           (mem_rd_data_i[7:0] ^ mem_rd_data_i[15:8] ^ mem_rd_data_i[23:16]));
						else
							chk_err <= 1'b0;
					end

					// --- beat>=1：累加 payload ---
					sum_acc         <= new_sum;
					xor_acc         <= new_xor;
					if (do_payload)
						bytes_processed <= bytes_processed + {3'd0, valid_bytes};

					// --- 进入 DONE 时写结果 ---
					if (next_state == S_DONE) begin
						res_pkt_len_o     <= pkt_len;
						res_pkt_type_o    <= pkt_type;
						res_payload_sum_o <= new_sum;
						res_payload_xor_o <= new_xor;
						length_error_o    <= len_err;
						type_error_o      <= typ_err;
						chk_error_o       <= chk_err;
						format_ok_o       <= !(len_err | typ_err | chk_err);
						done_o            <= 1'b1;
					end
				end

				// --------------------------------------------------------
				// DONE：保持结果，等待下一次 start
				// --------------------------------------------------------
				S_DONE: begin
					if (start_i) begin
						beat            <= 4'd0;
						hdr_valid       <= 1'b0;
						eff_total_words <= 4'd1;
						sum_acc         <= 8'd0;
						xor_acc         <= 8'd0;
						bytes_processed <= 6'd0;
						len_err         <= 1'b0;
						typ_err         <= 1'b0;
						chk_err         <= 1'b0;
						done_o            <= 1'b0;
						res_pkt_len_o     <= 6'd0;
						res_pkt_type_o    <= 8'd0;
						res_payload_sum_o <= 8'd0;
						res_payload_xor_o <= 8'd0;
						format_ok_o       <= 1'b0;
						length_error_o    <= 1'b0;
						type_error_o      <= 1'b0;
						chk_error_o       <= 1'b0;
					end
				end

				default: ;
			endcase
		end
	end

endmodule

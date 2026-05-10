// ============================================================================
// Module: ppa_tb
// Description: Lab2 Testbench - M3 packet_proc_core 独立验证
//   - SV 数组行为模型替代 M2（同步读，1 拍延迟）
//   - 覆盖必做：合法包处理、长度越界、busy/done 时序
//   - 覆盖选做：type 合法性、type_mask、hdr_chk 校验、payload sum/XOR
// ============================================================================

`timescale 1ns/1ps

module ppa_tb;

	// ========================================================================
	// 信号定义
	// ========================================================================
	logic        clk;
	logic        rst_n;

	// M3 控制输入
	logic        start_i;
	logic        algo_mode_i;
	logic [3:0]  type_mask_i;
	logic [5:0]  exp_pkt_len_i;

	// SRAM 读端口
	logic        mem_rd_en;
	logic [2:0]  mem_rd_addr;
	logic [31:0] mem_rd_data;

	// M3 状态输出
	logic        busy_o;
	logic        done_o;

	// M3 结果输出
	logic [5:0]  res_pkt_len_o;
	logic [7:0]  res_pkt_type_o;
	logic [7:0]  res_payload_sum_o;
	logic [7:0]  res_payload_xor_o;

	// M3 错误标志
	logic        format_ok_o;
	logic        length_error_o;
	logic        type_error_o;
	logic        chk_error_o;

	// 测试计数
	int pass_cnt = 0;
	int fail_cnt = 0;

	// ========================================================================
	// DUT 实例化
	// ========================================================================
	ppa_packet_proc_core u_dut (
		.clk               (clk),
		.rst_n             (rst_n),
		.start_i           (start_i),
		.algo_mode_i       (algo_mode_i),
		.type_mask_i       (type_mask_i),
		.exp_pkt_len_i     (exp_pkt_len_i),
		.mem_rd_en_o       (mem_rd_en),
		.mem_rd_addr_o     (mem_rd_addr),
		.mem_rd_data_i     (mem_rd_data),
		.busy_o            (busy_o),
		.done_o            (done_o),
		.res_pkt_len_o     (res_pkt_len_o),
		.res_pkt_type_o    (res_pkt_type_o),
		.res_payload_sum_o (res_payload_sum_o),
		.res_payload_xor_o (res_payload_xor_o),
		.format_ok_o       (format_ok_o),
		.length_error_o    (length_error_o),
		.type_error_o      (type_error_o),
		.chk_error_o       (chk_error_o)
	);

	// ========================================================================
	// SRAM 行为模型（同步读，匹配 M2 ppa_packet_sram 时序）
	// ========================================================================
	logic [31:0] sram_model [0:7];

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			mem_rd_data <= 32'h0;
		else if (mem_rd_en)
			mem_rd_data <= sram_model[mem_rd_addr];
	end

	// ========================================================================
	// 时钟生成：10ns 周期
	// ========================================================================
	initial clk = 0;
	always #5 clk = ~clk;

	// ========================================================================
	// 辅助 task：加载 packet 到 SRAM 模型
	// ========================================================================
	task automatic load_packet(input logic [7:0] bytes[], input int num_bytes);
		int word_idx, byte_idx;
		// 清空 SRAM
		for (int i = 0; i < 8; i++)
			sram_model[i] = 32'h0;
		// 按小端序填充
		for (int i = 0; i < num_bytes && i < 32; i++) begin
			word_idx = i / 4;
			byte_idx = i % 4;
			sram_model[word_idx][byte_idx*8 +: 8] = bytes[i];
		end
	endtask

	// ========================================================================
	// 辅助 task：发出 start 脉冲（单拍）
	// ========================================================================
	task automatic pulse_start();
		@(posedge clk);
		start_i <= 1'b1;
		@(posedge clk);
		start_i <= 1'b0;
	endtask

	// ========================================================================
	// 辅助 task：等待 done_o=1
	// ========================================================================
	task automatic wait_done(input int timeout = 100);
		int cnt = 0;
		while (!done_o && cnt < timeout) begin
			@(posedge clk);
			cnt++;
		end
		if (cnt >= timeout)
			$display("[ERROR] Timeout waiting for done_o");
	endtask

	// ========================================================================
	// 比较辅助 task
	// ========================================================================
	task automatic check_word(input string name, input logic [31:0] actual, input logic [31:0] expected);
		if (actual === expected) begin
			$display("[PASS] %s: got 0x%08h", name, actual);
			pass_cnt++;
		end else begin
			$display("[FAIL] %s: got 0x%08h, expected 0x%08h", name, actual, expected);
			fail_cnt++;
		end
	endtask

	task automatic check_flag(input string name, input logic actual, input logic expected);
		if (actual === expected) begin
			$display("[PASS] %s: got %0b", name, actual);
			pass_cnt++;
		end else begin
			$display("[FAIL] %s: got %0b, expected %0b", name, actual, expected);
			fail_cnt++;
		end
	endtask

	// ========================================================================
	// 主测试流程
	// ========================================================================
	initial begin
		// 初始化
		start_i       = 0;
		algo_mode_i   = 1;        // 默认启用 hdr_chk 校验
		type_mask_i   = 4'b1111;  // 默认允许所有类型
		exp_pkt_len_i = 6'd0;     // 默认不检查期望包长
		rst_n         = 0;

		repeat(5) @(posedge clk);
		rst_n = 1;
		repeat(2) @(posedge clk);

		// ==============================================================
		// TC1: 合法包完整处理（必做1）
		// pkt_len=8, pkt_type=0x01, flags=0x00, hdr_chk=0x09
		// payload = {0x01, 0x02, 0x03, 0x04}
		// ==============================================================
		$display("\n========== TC1: Valid Packet (8 bytes) ==========");
		begin
			logic [7:0] pkt[];
			pkt = new[8];
			pkt[0] = 8'd8;    // pkt_len
			pkt[1] = 8'h01;   // pkt_type
			pkt[2] = 8'h00;   // flags
			pkt[3] = 8'd8 ^ 8'h01 ^ 8'h00;  // hdr_chk = 0x09
			pkt[4] = 8'h01;   // payload
			pkt[5] = 8'h02;
			pkt[6] = 8'h03;
			pkt[7] = 8'h04;
			load_packet(pkt, 8);
		end

		pulse_start();
		wait_done();

		check_word("TC1 res_pkt_len",  {26'd0, res_pkt_len_o},  32'd8);
		check_word("TC1 res_pkt_type", {24'd0, res_pkt_type_o}, 32'h01);
		check_word("TC1 res_payload_sum", {24'd0, res_payload_sum_o}, 32'h0A);  // 1+2+3+4=10=0x0A
		check_word("TC1 res_payload_xor", {24'd0, res_payload_xor_o}, 32'h04);  // 1^2^3^4=0x04
		check_flag("TC1 done_o",        done_o,        1'b1);
		check_flag("TC1 format_ok_o",   format_ok_o,   1'b1);
		check_flag("TC1 length_error",  length_error_o, 1'b0);
		check_flag("TC1 type_error",    type_error_o,   1'b0);
		check_flag("TC1 chk_error",     chk_error_o,    1'b0);

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC2a: 长度下溢 pkt_len=3（必做2）
		// ==============================================================
		$display("\n========== TC2a: Length Underflow (pkt_len=3) ==========");
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd3;    // pkt_len=3（非法）
			pkt[1] = 8'h01;
			pkt[2] = 8'h00;
			pkt[3] = 8'd3 ^ 8'h01 ^ 8'h00;
			load_packet(pkt, 4);
		end

		pulse_start();
		wait_done();

		check_flag("TC2a done_o",        done_o,         1'b1);
		check_flag("TC2a length_error",  length_error_o, 1'b1);
		check_flag("TC2a format_ok_o",   format_ok_o,    1'b0);

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC2b: 长度上溢 pkt_len=33（必做2）
		// ==============================================================
		$display("\n========== TC2b: Length Overflow (pkt_len=33) ==========");
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd33;   // pkt_len=33（非法）
			pkt[1] = 8'h02;
			pkt[2] = 8'h00;
			pkt[3] = 8'd33 ^ 8'h02 ^ 8'h00;
			load_packet(pkt, 4);
		end

		pulse_start();
		wait_done();

		check_flag("TC2b done_o",        done_o,         1'b1);
		check_flag("TC2b length_error",  length_error_o, 1'b1);
		check_flag("TC2b format_ok_o",   format_ok_o,    1'b0);

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC3: busy/done 时序 + 连续两帧处理（必做3）
		// ==============================================================
		$display("\n========== TC3: Busy/Done Timing + Two Frames ==========");

		// --- 第一帧：pkt_len=4（最小合法包）---
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd4;
			pkt[1] = 8'h01;
			pkt[2] = 8'h00;
			pkt[3] = 8'd4 ^ 8'h01 ^ 8'h00;  // 0x05
			load_packet(pkt, 4);
		end

		// 发出 start 脉冲
		@(posedge clk);
		start_i <= 1'b1;
		@(posedge clk);
		start_i <= 1'b0;

		// start 有效后第 1 拍检查 busy_o
		check_flag("TC3 busy after start (frame1)", busy_o, 1'b1);
		check_flag("TC3 done cleared after start",  done_o, 1'b0);

		wait_done();
		check_flag("TC3 done_o frame1",       done_o,       1'b1);
		check_flag("TC3 busy_o in DONE",      busy_o,       1'b0);
		check_word("TC3 res_pkt_len frame1",   {26'd0, res_pkt_len_o}, 32'd4);
		check_word("TC3 res_pkt_type frame1",  {24'd0, res_pkt_type_o}, 32'h01);
		check_word("TC3 res_payload_sum frame1", {24'd0, res_payload_sum_o}, 32'h00);
		check_word("TC3 res_payload_xor frame1", {24'd0, res_payload_xor_o}, 32'h00);

		// done_o 在 DONE 态持续保持
		repeat(3) @(posedge clk);
		check_flag("TC3 done_o held in DONE", done_o, 1'b1);

		// --- 第二帧：pkt_len=8 ---
		begin
			logic [7:0] pkt[];
			pkt = new[8];
			pkt[0] = 8'd8;
			pkt[1] = 8'h02;
			pkt[2] = 8'h00;
			pkt[3] = 8'd8 ^ 8'h02 ^ 8'h00;  // 0x0A
			pkt[4] = 8'hAA;
			pkt[5] = 8'hBB;
			pkt[6] = 8'hCC;
			pkt[7] = 8'hDD;
			load_packet(pkt, 8);
		end

		// 从 DONE 发出 start
		@(posedge clk);
		start_i <= 1'b1;
		@(posedge clk);
		start_i <= 1'b0;

		// done 应清零
		check_flag("TC3 done cleared for frame2", done_o, 1'b0);
		check_flag("TC3 busy after start (frame2)", busy_o, 1'b1);

		wait_done();
		check_flag("TC3 done_o frame2", done_o, 1'b1);
		check_word("TC3 res_pkt_len frame2",  {26'd0, res_pkt_len_o},  32'd8);
		check_word("TC3 res_pkt_type frame2", {24'd0, res_pkt_type_o}, 32'h02);
		// payload sum: 0xAA+0xBB+0xCC+0xDD = 782 = 0x30E, 8-bit truncated = 0x0E
		check_word("TC3 res_payload_sum frame2", {24'd0, res_payload_sum_o}, 32'h0E);
		// payload xor: 0xAA^0xBB^0xCC^0xDD
		// 0xAA^0xBB = 0x11, 0xCC^0xDD = 0x11, 0x11^0x11 = 0x00
		check_word("TC3 res_payload_xor frame2", {24'd0, res_payload_xor_o}, 32'h00);

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC4a: 非法 pkt_type（选做4）
		// ==============================================================
		$display("\n========== TC4a: Invalid pkt_type (0x03) ==========");
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd4;
			pkt[1] = 8'h03;   // 非 one-hot
			pkt[2] = 8'h00;
			pkt[3] = 8'd4 ^ 8'h03 ^ 8'h00;
			load_packet(pkt, 4);
		end

		pulse_start();
		wait_done();

		check_flag("TC4a type_error",  type_error_o,  1'b1);
		check_flag("TC4a format_ok_o", format_ok_o,   1'b0);

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC4b: type_mask 屏蔽（选做4）
		// ==============================================================
		$display("\n========== TC4b: type_mask blocks pkt_type=0x01 ==========");
		type_mask_i = 4'b1110;  // 屏蔽 bit[0]，不允许 pkt_type=0x01
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd4;
			pkt[1] = 8'h01;   // pkt_type=0x01，被 mask 屏蔽
			pkt[2] = 8'h00;
			pkt[3] = 8'd4 ^ 8'h01 ^ 8'h00;
			load_packet(pkt, 4);
		end

		pulse_start();
		wait_done();

		check_flag("TC4b type_error",  type_error_o,  1'b1);
		check_flag("TC4b format_ok_o", format_ok_o,   1'b0);

		type_mask_i = 4'b1111;  // 恢复默认

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC5a: hdr_chk 校验错误（选做5）
		// ==============================================================
		$display("\n========== TC5a: hdr_chk error (algo_mode=1) ==========");
		algo_mode_i = 1;
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd4;
			pkt[1] = 8'h01;
			pkt[2] = 8'h00;
			pkt[3] = 8'hFF;   // 错误的 hdr_chk（正确值=0x05）
			load_packet(pkt, 4);
		end

		pulse_start();
		wait_done();

		check_flag("TC5a chk_error",   chk_error_o,   1'b1);
		check_flag("TC5a format_ok_o", format_ok_o,    1'b0);

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC5b: algo_mode=0 旁路校验（选做5）
		// ==============================================================
		$display("\n========== TC5b: algo_mode=0 bypass ==========");
		algo_mode_i = 0;
		begin
			logic [7:0] pkt[];
			pkt = new[4];
			pkt[0] = 8'd4;
			pkt[1] = 8'h01;
			pkt[2] = 8'h00;
			pkt[3] = 8'hFF;   // 同一个错误 hdr_chk
			load_packet(pkt, 4);
		end

		pulse_start();
		wait_done();

		check_flag("TC5b chk_error",   chk_error_o,   1'b0);  // 旁路，不报错
		check_flag("TC5b format_ok_o", format_ok_o,    1'b1);

		algo_mode_i = 1;  // 恢复默认

		repeat(3) @(posedge clk);

		// ==============================================================
		// TC5c: payload sum/XOR 验证（选做5）
		// pkt_len=8, payload = {0x01, 0x02, 0x03, 0x04}
		// sum = 0x0A, xor = 0x04
		// ==============================================================
		$display("\n========== TC5c: Payload Sum/XOR ==========");
		begin
			logic [7:0] pkt[];
			pkt = new[8];
			pkt[0] = 8'd8;
			pkt[1] = 8'h02;
			pkt[2] = 8'h00;
			pkt[3] = 8'd8 ^ 8'h02 ^ 8'h00;  // 0x0A
			pkt[4] = 8'h01;
			pkt[5] = 8'h02;
			pkt[6] = 8'h03;
			pkt[7] = 8'h04;
			load_packet(pkt, 8);
		end

		pulse_start();
		wait_done();

		check_word("TC5c res_payload_sum", {24'd0, res_payload_sum_o}, 32'h0A);
		check_word("TC5c res_payload_xor", {24'd0, res_payload_xor_o}, 32'h04);
		check_flag("TC5c format_ok_o",    format_ok_o,    1'b1);

		repeat(3) @(posedge clk);

		// ==============================================================
		// 测试结束
		// ==============================================================
		$display("\n========== Test Summary ==========");
		$display("PASS: %0d", pass_cnt);
		$display("FAIL: %0d", fail_cnt);
		if (fail_cnt == 0)
			$display("ALL TESTS PASSED");
		else
			$display("SOME TESTS FAILED");
		$finish;
	end

endmodule

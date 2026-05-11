// ============================================================================
// Module: ppa_tb
// Description: Lab2 M3 独立 Testbench（行为级 SRAM 模型，不依赖 Lab1）
//   TC1: 最小合法包（pkt_len=4）
//   TC2: 8 字节合法包（含 4B payload，sum/XOR 校验）
//   TC3: 长度下溢（pkt_len=3，length_error=1，不卡死）
//   TC4: 长度上溢（pkt_len=33，length_error=1，不卡死）
//   TC5: busy/done 时序检查
//   TC6: 连续两帧处理
//   TC7: pkt_type 非 one-hot（type_error）
//   TC8: type_mask 屏蔽合法类型（type_error）
//   TC9: hdr_chk 校验失败（chk_error）
//   TC10: algo_mode=0 旁路 hdr_chk
//   TC11: 三类错误并行成立
//   TC12: exp_pkt_len 不匹配（length_error）
//   TC13: exp_pkt_len 匹配（正向确认）
//   TC14: payload 非对齐尾 word（sum/XOR 边界）
// ============================================================================

`timescale 1ns/1ps

module ppa_tb;

	// ========================================================================
	// 信号
	// ========================================================================
	logic        clk;
	logic        rst_n;

	logic        start_i;
	logic        algo_mode_i;
	logic [3:0]  type_mask_i;
	logic [5:0]  exp_pkt_len_i;

	logic        mem_rd_en;
	logic [2:0]  mem_rd_addr;
	logic [31:0] mem_rd_data;

	logic        busy_o;
	logic        done_o;
	logic [5:0]  res_pkt_len_o;
	logic [7:0]  res_pkt_type_o;
	logic [7:0]  res_payload_sum_o;
	logic [7:0]  res_payload_xor_o;
	logic        format_ok_o;
	logic        length_error_o;
	logic        type_error_o;
	logic        chk_error_o;

	int pass_cnt = 0;
	int fail_cnt = 0;

	// ========================================================================
	// 行为级 SRAM 模型（8 word，1 拍同步读延迟）
	// ========================================================================
	logic [31:0] mem [0:7];

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) mem_rd_data <= 32'h0;
		else if (mem_rd_en) mem_rd_data <= mem[mem_rd_addr];
	end

	// ========================================================================
	// DUT
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
	// 时钟/复位
	// ========================================================================
	initial clk = 1'b0;
	always #5 clk = ~clk;

	// ========================================================================
	// 工具任务
	// ========================================================================
	task automatic do_reset();
		rst_n         = 1'b0;
		start_i       = 1'b0;
		algo_mode_i   = 1'b1;
		type_mask_i   = 4'b1111;
		exp_pkt_len_i = 6'd0;
		for (int i = 0; i < 8; i++) mem[i] = 32'h0;
		repeat (3) @(posedge clk);
		rst_n = 1'b1;
		@(posedge clk);
	endtask

	task automatic pulse_start();
		@(negedge clk);
		start_i = 1'b1;
		@(negedge clk);
		start_i = 1'b0;
	endtask

	task automatic wait_done(input int timeout = 200);
		int t;
		t = 0;
		while (!done_o && t < timeout) begin
			@(posedge clk);
			t = t + 1;
		end
		if (!done_o)
			$display("[%0t] TIMEOUT: done_o not asserted within %0d cycles", $time, timeout);
	endtask

	task automatic check(input string name, input logic [31:0] actual, input logic [31:0] expected);
		if (actual === expected) begin
			$display("[PASS] %s: got 0x%08h", name, actual);
			pass_cnt++;
		end else begin
			$display("[FAIL] %s: got 0x%08h, expected 0x%08h", name, actual, expected);
			fail_cnt++;
		end
	endtask

	function automatic logic [31:0] pack_hdr(input [7:0] len, type_, flags, chk);
		return {chk, flags, type_, len};
	endfunction

	// ========================================================================
	// Testcases
	// ========================================================================
	initial begin
		do_reset();

		// --------------------------------------------------------------------
		// TC1: 最小合法包 pkt_len=4, type=0x01, hdr_chk=0x05
		// --------------------------------------------------------------------
		$display("\n========== TC1: tc_min_legal_pkt ==========");
		mem[0] = pack_hdr(8'd4, 8'h01, 8'h00, 8'h05);
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("done_o",       {31'b0, done_o},          32'h1);
		check("busy_o",       {31'b0, busy_o},          32'h0);
		check("res_pkt_len",  {26'b0, res_pkt_len_o},   32'd4);
		check("res_pkt_type", {24'b0, res_pkt_type_o},  32'h01);
		check("format_ok",    {31'b0, format_ok_o},     32'h1);
		check("length_error", {31'b0, length_error_o},  32'h0);
		check("type_error",   {31'b0, type_error_o},    32'h0);
		check("chk_error",    {31'b0, chk_error_o},     32'h0);
		check("payload_sum",  {24'b0, res_payload_sum_o}, 32'h00);

		// --------------------------------------------------------------------
		// TC2: 8 字节合法包 pkt_len=8, type=0x02, payload=0x04030201
		//   hdr_chk = 0x08 ^ 0x02 ^ 0x00 = 0x0A
		//   payload bytes (LE order in word: 0x01,0x02,0x03,0x04)
		//   sum = 0x01+0x02+0x03+0x04 = 0x0A
		//   xor = 0x01^0x02^0x03^0x04 = 0x04
		// --------------------------------------------------------------------
		$display("\n========== TC2: tc_8byte_legal ==========");
		mem[0] = pack_hdr(8'd8, 8'h02, 8'h00, 8'h0A);
		mem[1] = 32'h04030201;
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("res_pkt_len",   {26'b0, res_pkt_len_o},     32'd8);
		check("res_pkt_type",  {24'b0, res_pkt_type_o},    32'h02);
		check("payload_sum",   {24'b0, res_payload_sum_o}, 32'h0A);
		check("payload_xor",   {24'b0, res_payload_xor_o}, 32'h04);
		check("format_ok",     {31'b0, format_ok_o},       32'h1);
		check("err flags",     {29'b0, length_error_o, type_error_o, chk_error_o}, 32'h0);

		// --------------------------------------------------------------------
		// TC3: 长度下溢 pkt_len=3
		// --------------------------------------------------------------------
		$display("\n========== TC3: tc_length_underflow ==========");
		mem[0] = pack_hdr(8'd3, 8'h01, 8'h00, 8'h02);
		pulse_start();
		wait_done();
		check("done_o",       {31'b0, done_o},         32'h1);
		check("length_error", {31'b0, length_error_o}, 32'h1);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);
		check("busy released", {31'b0, busy_o},        32'h0);

		// --------------------------------------------------------------------
		// TC4: 长度上溢 pkt_len=33
		// --------------------------------------------------------------------
		$display("\n========== TC4: tc_length_overflow ==========");
		mem[0] = pack_hdr(8'd33, 8'h01, 8'h00, 8'h20);
		pulse_start();
		wait_done();
		check("done_o",       {31'b0, done_o},         32'h1);
		check("length_error", {31'b0, length_error_o}, 32'h1);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);
		check("busy released", {31'b0, busy_o},        32'h0);

		// --------------------------------------------------------------------
		// TC5: busy/done 时序检查（合法 12B 包）
		//   hdr_chk = 0x0C ^ 0x04 ^ 0x00 = 0x08
		// --------------------------------------------------------------------
		$display("\n========== TC5: tc_busy_done_timing ==========");
		mem[0] = pack_hdr(8'd12, 8'h04, 8'h00, 8'h08);
		mem[1] = 32'h08070605;
		mem[2] = 32'h0C0B0A09;
		fork
			begin : busy_check
				@(negedge clk);
				start_i = 1'b1;
				@(posedge clk);
				// 第 1 拍后 busy 应该为 1
				@(posedge clk);
				check("busy after start", {31'b0, busy_o}, 32'h1);
				check("done during proc", {31'b0, done_o}, 32'h0);
				@(negedge clk);
				start_i = 1'b0;
			end
		join
		wait_done();
		check("done held in DONE", {31'b0, done_o}, 32'h1);
		check("busy in DONE",      {31'b0, busy_o}, 32'h0);
		// 在 DONE 态保持几拍，结果应保持
		repeat (5) @(posedge clk);
		check("done still held",   {31'b0, done_o},         32'h1);
		check("res_pkt_len held",  {26'b0, res_pkt_len_o},  32'd12);

		// --------------------------------------------------------------------
		// TC6: 连续两帧（DONE 态接受新 start）
		// --------------------------------------------------------------------
		$display("\n========== TC6: tc_two_frames ==========");
		// 第二帧：pkt_len=4, type=0x08, hdr_chk=0x0C
		mem[0] = pack_hdr(8'd4, 8'h08, 8'h00, 8'h0C);
		pulse_start();
		// start 接受后 done 应清零
		@(posedge clk);
		check("done cleared after new start", {31'b0, done_o}, 32'h0);
		wait_done();
		check("frame2 res_pkt_len",   {26'b0, res_pkt_len_o},  32'd4);
		check("frame2 res_pkt_type",  {24'b0, res_pkt_type_o}, 32'h08);
		check("frame2 format_ok",     {31'b0, format_ok_o},    32'h1);

		// --------------------------------------------------------------------
		// TC7: pkt_type 非 one-hot（F2-06）
		//   pkt_type=0x03 不在 {0x01,0x02,0x04,0x08} → type_error=1
		//   hdr_chk = 0x04 ^ 0x03 ^ 0x00 = 0x07
		// --------------------------------------------------------------------
		$display("\n========== TC7: tc_type_not_one_hot ==========");
		mem[0] = pack_hdr(8'd4, 8'h03, 8'h00, 8'h07);
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("type_error",   {31'b0, type_error_o},   32'h1);
		check("length_error", {31'b0, length_error_o}, 32'h0);
		check("chk_error",    {31'b0, chk_error_o},    32'h0);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);

		// --------------------------------------------------------------------
		// TC8: type_mask 屏蔽合法 one-hot 类型（F2-06）
		//   pkt_type=0x01 (idx=0) 但 type_mask=4'b1110（bit0 禁止）→ type_error=1
		//   hdr_chk = 0x04 ^ 0x01 ^ 0x00 = 0x05
		// --------------------------------------------------------------------
		$display("\n========== TC8: tc_type_mask_filter ==========");
		mem[0] = pack_hdr(8'd4, 8'h01, 8'h00, 8'h05);
		algo_mode_i = 1'b1; type_mask_i = 4'b1110; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("type_error",   {31'b0, type_error_o},   32'h1);
		check("length_error", {31'b0, length_error_o}, 32'h0);
		check("chk_error",    {31'b0, chk_error_o},    32'h0);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);

		// --------------------------------------------------------------------
		// TC9: hdr_chk 校验失败（F2-07）
		//   pkt_len=4, type=0x01, flags=0x00, 正确 chk=0x05, 实际填 0xFF
		//   algo_mode=1 → chk_error=1
		// --------------------------------------------------------------------
		$display("\n========== TC9: tc_hdr_chk_error ==========");
		mem[0] = pack_hdr(8'd4, 8'h01, 8'h00, 8'hFF);
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("chk_error",    {31'b0, chk_error_o},    32'h1);
		check("length_error", {31'b0, length_error_o}, 32'h0);
		check("type_error",   {31'b0, type_error_o},   32'h0);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);

		// --------------------------------------------------------------------
		// TC10: algo_mode=0 旁路 hdr_chk（F2-08）
		//   与 TC9 相同包但 algo_mode=0 → chk_error=0，format_ok=1
		// --------------------------------------------------------------------
		$display("\n========== TC10: tc_algo_mode_bypass ==========");
		mem[0] = pack_hdr(8'd4, 8'h01, 8'h00, 8'hFF);
		algo_mode_i = 1'b0; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("chk_error",    {31'b0, chk_error_o},    32'h0);
		check("length_error", {31'b0, length_error_o}, 32'h0);
		check("type_error",   {31'b0, type_error_o},   32'h0);
		check("format_ok",    {31'b0, format_ok_o},    32'h1);

		// --------------------------------------------------------------------
		// TC11: 三类错误并行成立（F2-11）
		//   pkt_len=3（length_error）, type=0x03（type_error）
		//   正确 chk=0x03^0x03^0x00=0x00, 填 0xFF（chk_error）
		//   algo_mode=1
		// --------------------------------------------------------------------
		$display("\n========== TC11: tc_multi_error ==========");
		mem[0] = pack_hdr(8'd3, 8'h03, 8'h00, 8'hFF);
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("length_error", {31'b0, length_error_o}, 32'h1);
		check("type_error",   {31'b0, type_error_o},   32'h1);
		check("chk_error",    {31'b0, chk_error_o},    32'h1);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);
		check("done_o",       {31'b0, done_o},         32'h1);

		// --------------------------------------------------------------------
		// TC12: exp_pkt_len 不匹配（F2-14）
		//   pkt_len=8（合法范围），exp_pkt_len_i=6'd10（非零且≠8）→ length_error=1
		//   hdr_chk = 0x08 ^ 0x02 ^ 0x00 = 0x0A
		// --------------------------------------------------------------------
		$display("\n========== TC12: tc_exp_pkt_len_mismatch ==========");
		mem[0] = pack_hdr(8'd8, 8'h02, 8'h00, 8'h0A);
		mem[1] = 32'h04030201;
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd10;
		pulse_start();
		wait_done();
		check("length_error", {31'b0, length_error_o}, 32'h1);
		check("type_error",   {31'b0, type_error_o},   32'h0);
		check("chk_error",    {31'b0, chk_error_o},    32'h0);
		check("format_ok",    {31'b0, format_ok_o},    32'h0);

		// --------------------------------------------------------------------
		// TC13: exp_pkt_len 匹配（F2-14 正向确认）
		//   pkt_len=8, exp_pkt_len_i=6'd8（匹配）→ length_error=0
		//   hdr_chk = 0x08 ^ 0x02 ^ 0x00 = 0x0A
		// --------------------------------------------------------------------
		$display("\n========== TC13: tc_exp_pkt_len_match ==========");
		mem[0] = pack_hdr(8'd8, 8'h02, 8'h00, 8'h0A);
		mem[1] = 32'h04030201;
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd8;
		pulse_start();
		wait_done();
		check("length_error", {31'b0, length_error_o}, 32'h0);
		check("format_ok",    {31'b0, format_ok_o},    32'h1);
		check("payload_sum",  {24'b0, res_payload_sum_o}, 32'h0A);
		check("payload_xor",  {24'b0, res_payload_xor_o}, 32'h04);

		// --------------------------------------------------------------------
		// TC14: payload 非对齐尾 word（F2-09/F2-10 边界）
		//   pkt_len=5 → words_total=ceil(5/4)=2, word1 仅 byte[4] 有效
		//   word1=32'hDEADBF42 → 只有 0x42 参与 sum/XOR
		//   hdr_chk = 0x05 ^ 0x01 ^ 0x00 = 0x04
		// --------------------------------------------------------------------
		$display("\n========== TC14: tc_payload_unaligned ==========");
		mem[0] = pack_hdr(8'd5, 8'h01, 8'h00, 8'h04);
		mem[1] = 32'hDEADBF42;
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("format_ok",    {31'b0, format_ok_o},       32'h1);
		check("payload_sum",  {24'b0, res_payload_sum_o}, 32'h42);
		check("payload_xor",  {24'b0, res_payload_xor_o}, 32'h42);
		check("res_pkt_len",  {26'b0, res_pkt_len_o},     32'd5);

		// --------------------------------------------------------------------
		// 总结
		// --------------------------------------------------------------------
		$display("\n========== Test Summary ==========");
		$display("PASS: %0d", pass_cnt);
		$display("FAIL: %0d", fail_cnt);
		if (fail_cnt == 0)
			$display("ALL TESTS PASSED");
		else
			$display("SOME TESTS FAILED");
		$finish;
	end

	// 安全网：避免极端情况下无限挂起
	initial begin
		#100000;
		$display("[%0t] GLOBAL TIMEOUT", $time);
		$finish;
	end

endmodule

// ============================================================================
// Module: ppa_tb
// Description: Lab2 Testbench - M3 包处理核心独立验证
//   - 行为 SRAM 模型（替代 M2，同步读时序）
//   - TC1~TC5: 必做验收覆盖（正常包/长度越界/busy-done时序/连续两帧）
//   - TC6~TC11: 选做验收覆盖（类型/校验/旁路/payload/多错误/exp_pkt_len）
// ============================================================================

`timescale 1ns/1ps

module ppa_tb;

	// ========================================================================
	// 信号定义
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
	logic [5:0]  res_pkt_len;
	logic [7:0]  res_pkt_type;
	logic [7:0]  res_payload_sum;
	logic [7:0]  res_payload_xor;
	logic        format_ok;
	logic        length_error;
	logic        type_error;
	logic        chk_error;

	int pass_cnt = 0;
	int fail_cnt = 0;

	// ========================================================================
	// 行为 SRAM 模型（同步读，匹配 M2 时序）
	// ========================================================================
	logic [31:0] sram [0:7];

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			mem_rd_data <= 32'h0;
		else if (mem_rd_en)
			mem_rd_data <= sram[mem_rd_addr];
	end

	// ========================================================================
	// DUT 实例化
	// ========================================================================
	ppa_packet_proc_core dut (
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
		.res_pkt_len_o     (res_pkt_len),
		.res_pkt_type_o    (res_pkt_type),
		.res_payload_sum_o (res_payload_sum),
		.res_payload_xor_o (res_payload_xor),
		.format_ok_o       (format_ok),
		.length_error_o    (length_error),
		.type_error_o      (type_error),
		.chk_error_o       (chk_error)
	);

	// ========================================================================
	// 时钟生成：10ns 周期
	// ========================================================================
	initial clk = 0;
	always #5 clk = ~clk;

	// ========================================================================
	// 辅助 task
	// ========================================================================
	task automatic do_reset();
		rst_n         = 0;
		start_i       = 0;
		algo_mode_i   = 1;
		type_mask_i   = 4'b1111;
		exp_pkt_len_i = 6'd0;
		for (int i = 0; i < 8; i++) sram[i] = 32'h0;
		repeat(5) @(posedge clk);
		rst_n = 1;
		repeat(2) @(posedge clk);
	endtask

	task automatic write_sram(input int idx, input logic [31:0] data);
		sram[idx] = data;
	endtask

	task automatic trigger_start();
		@(posedge clk);
		start_i <= 1;
		@(posedge clk);
		start_i <= 0;
	endtask

	task automatic wait_done(input int timeout = 100);
		int cnt = 0;
		while (!done_o && cnt < timeout) begin
			@(posedge clk);
			cnt++;
		end
		if (cnt >= timeout)
			$display("[TIMEOUT] wait_done exceeded %0d cycles", timeout);
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

	task automatic check1(input string name, input logic actual, input logic expected);
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
		do_reset();

		// ==============================================================
		// TC1: tc_normal_min_pkt - 最小合法包（pkt_len=4，纯头部）
		// ==============================================================
		$display("\n========== TC1: tc_normal_min_pkt ==========");
		// pkt_len=4, pkt_type=0x01, flags=0x00, hdr_chk = 4^1^0 = 5
		write_sram(0, 32'h05_00_01_04);
		trigger_start();
		wait_done();

		check1("done_o", done_o, 1'b1);
		check1("busy_o", busy_o, 1'b0);
		check("res_pkt_len", {26'b0, res_pkt_len}, 32'd4);
		check("res_pkt_type", {24'b0, res_pkt_type}, 32'h01);
		check("res_payload_sum", {24'b0, res_payload_sum}, 32'h00);
		check("res_payload_xor", {24'b0, res_payload_xor}, 32'h00);
		check1("format_ok", format_ok, 1'b1);
		check1("length_error", length_error, 1'b0);
		check1("type_error", type_error, 1'b0);
		check1("chk_error", chk_error, 1'b0);

		// ==============================================================
		// TC2: tc_normal_payload - 8 字节合法包（含 4B payload）
		// ==============================================================
		$display("\n========== TC2: tc_normal_payload ==========");
		// pkt_len=8, pkt_type=0x02, flags=0x00, hdr_chk = 8^2^0 = 0x0A
		write_sram(0, 32'h0A_00_02_08);
		// payload: 0x01, 0x02, 0x03, 0x04
		write_sram(1, 32'h04_03_02_01);
		trigger_start();
		wait_done();

		check1("done_o", done_o, 1'b1);
		check("res_pkt_len", {26'b0, res_pkt_len}, 32'd8);
		check("res_pkt_type", {24'b0, res_pkt_type}, 32'h02);
		// sum = 1+2+3+4 = 10 = 0x0A
		check("res_payload_sum", {24'b0, res_payload_sum}, 32'h0A);
		// xor = 1^2^3^4 = 0x04
		check("res_payload_xor", {24'b0, res_payload_xor}, 32'h04);
		check1("format_ok", format_ok, 1'b1);

		// ==============================================================
		// TC3: tc_len_underflow - 长度下溢（pkt_len=3）
		// ==============================================================
		$display("\n========== TC3: tc_len_underflow ==========");
		// pkt_len=3, pkt_type=0x01, flags=0x00, hdr_chk=3^1^0=2
		write_sram(0, 32'h02_00_01_03);
		trigger_start();
		wait_done(20);

		check1("done_o (underflow)", done_o, 1'b1);
		check1("length_error (underflow)", length_error, 1'b1);
		check1("format_ok (underflow)", format_ok, 1'b0);

		// ==============================================================
		// TC4: tc_len_overflow - 长度上溢（pkt_len=33）
		// ==============================================================
		$display("\n========== TC4: tc_len_overflow ==========");
		// pkt_len=33=0x21, pkt_type=0x01, flags=0x00, hdr_chk=0x21^0x01^0x00=0x20
		write_sram(0, 32'h20_00_01_21);
		for (int i = 1; i < 8; i++) write_sram(i, 32'hAA_BB_CC_DD);
		trigger_start();
		wait_done(20);

		check1("done_o (overflow)", done_o, 1'b1);
		check1("length_error (overflow)", length_error, 1'b1);
		check1("format_ok (overflow)", format_ok, 1'b0);

		// ==============================================================
		// TC5: tc_busy_done_timing - busy/done 时序
		// ==============================================================
		$display("\n========== TC5: tc_busy_done_timing ==========");
		// pkt_len=8, pkt_type=0x04, flags=0x00, hdr_chk=8^4^0=0x0C
		write_sram(0, 32'h0C_00_04_08);
		write_sram(1, 32'h11_22_33_44);

		// 验证 start 前 done 保持
		check1("done_o before start", done_o, 1'b1);

		@(posedge clk);
		start_i <= 1;
		@(posedge clk);
		start_i <= 0;

		// start 后第 1 拍 busy=1
		check1("busy_o after start", busy_o, 1'b1);
		check1("done_o cleared", done_o, 1'b0);

		wait_done();

		check1("done_o after process", done_o, 1'b1);
		check1("busy_o after done", busy_o, 1'b0);

		// done 持续保持
		repeat(5) @(posedge clk);
		check1("done_o persists", done_o, 1'b1);

		// 再次 start 后 done 清零
		@(posedge clk);
		start_i <= 1;
		@(posedge clk);
		start_i <= 0;
		check1("done_o cleared on restart", done_o, 1'b0);
		check1("busy_o on restart", busy_o, 1'b1);
		wait_done();

		// ==============================================================
		// TC6: tc_consecutive_pkts - 连续两帧处理
		// ==============================================================
		$display("\n========== TC6: tc_consecutive_pkts ==========");
		// 第一帧：pkt_len=4, pkt_type=0x01
		write_sram(0, 32'h05_00_01_04);
		trigger_start();
		wait_done();
		check("pkt1 res_pkt_len", {26'b0, res_pkt_len}, 32'd4);
		check("pkt1 res_pkt_type", {24'b0, res_pkt_type}, 32'h01);

		// 第二帧：pkt_len=8, pkt_type=0x08
		write_sram(0, 32'h01_00_08_08);  // hdr_chk=8^8^0=0x00... wait
		// hdr_chk = 8 ^ 8 ^ 0 = 0, so 32'h00_00_08_08
		write_sram(0, 32'h00_00_08_08);
		write_sram(1, 32'hFF_EE_DD_CC);
		trigger_start();
		wait_done();
		check("pkt2 res_pkt_len", {26'b0, res_pkt_len}, 32'd8);
		check("pkt2 res_pkt_type", {24'b0, res_pkt_type}, 32'h08);
		// sum = 0xCC+0xDD+0xEE+0xFF = 0x398 & 0xFF = 0x98
		check("pkt2 res_payload_sum", {24'b0, res_payload_sum}, 32'h98);
		// xor = 0xCC^0xDD^0xEE^0xFF = 0xCC^0xDD = 0x11, 0xEE^0xFF = 0x11, 0x11^0x11 = 0x00
		check("pkt2 res_payload_xor", {24'b0, res_payload_xor}, 32'h00);

		// ==============================================================
		// TC7: tc_type_error - 非法 pkt_type（非 one-hot）
		// ==============================================================
		$display("\n========== TC7: tc_type_error ==========");
		// pkt_len=4, pkt_type=0x03, flags=0x00, hdr_chk=4^3^0=7
		write_sram(0, 32'h07_00_03_04);
		trigger_start();
		wait_done();

		check1("type_error (0x03)", type_error, 1'b1);
		check1("format_ok (type err)", format_ok, 1'b0);

		// ==============================================================
		// TC8: tc_type_mask - type_mask 屏蔽
		// ==============================================================
		$display("\n========== TC8: tc_type_mask ==========");
		// pkt_type=0x01, type_mask=4'b1110 (bit0 disabled)
		type_mask_i = 4'b1110;
		write_sram(0, 32'h05_00_01_04);
		trigger_start();
		wait_done();

		check1("type_error (masked)", type_error, 1'b1);
		check1("format_ok (masked)", format_ok, 1'b0);
		type_mask_i = 4'b1111;

		// ==============================================================
		// TC9: tc_chk_error - hdr_chk 校验错误（algo_mode=1）
		// ==============================================================
		$display("\n========== TC9: tc_chk_error ==========");
		// pkt_len=4, pkt_type=0x01, flags=0x00, hdr_chk=0xFF (wrong, should be 5)
		write_sram(0, 32'hFF_00_01_04);
		algo_mode_i = 1;
		trigger_start();
		wait_done();

		check1("chk_error (bad chk)", chk_error, 1'b1);
		check1("format_ok (chk err)", format_ok, 1'b0);

		// ==============================================================
		// TC10: tc_algo_bypass - algo_mode=0 旁路校验
		// ==============================================================
		$display("\n========== TC10: tc_algo_bypass ==========");
		// 同一个 packet 但 algo_mode=0
		write_sram(0, 32'hFF_00_01_04);
		algo_mode_i = 0;
		trigger_start();
		wait_done();

		check1("chk_error (bypassed)", chk_error, 1'b0);
		algo_mode_i = 1;

		// ==============================================================
		// TC11: tc_multi_error - 三类错误并行
		// ==============================================================
		$display("\n========== TC11: tc_multi_error ==========");
		// pkt_len=3 (length_error), pkt_type=0x03 (type_error), bad hdr_chk (chk_error)
		write_sram(0, 32'hFF_00_03_03);
		algo_mode_i = 1;
		trigger_start();
		wait_done();

		check1("length_error (multi)", length_error, 1'b1);
		check1("type_error (multi)", type_error, 1'b1);
		check1("chk_error (multi)", chk_error, 1'b1);
		check1("format_ok (multi)", format_ok, 1'b0);

		// ==============================================================
		// TC12: tc_exp_pkt_len - PKT_LEN_EXP 不符
		// ==============================================================
		$display("\n========== TC12: tc_exp_pkt_len ==========");
		// pkt_len=8, exp_pkt_len=12 (mismatch)
		write_sram(0, 32'h0A_00_02_08);
		write_sram(1, 32'h01_02_03_04);
		exp_pkt_len_i = 6'd12;
		trigger_start();
		wait_done();

		check1("length_error (exp mismatch)", length_error, 1'b1);
		exp_pkt_len_i = 6'd0;

		// exp_pkt_len = 0 时不检查
		trigger_start();
		wait_done();
		check1("length_error (exp=0 skip)", length_error, 1'b0);

		// ==============================================================
		// TC13: tc_max_pkt - 最大合法包（pkt_len=32）
		// ==============================================================
		$display("\n========== TC13: tc_max_pkt ==========");
		// pkt_len=32=0x20, pkt_type=0x04, flags=0x00, hdr_chk=0x20^0x04^0x00=0x24
		write_sram(0, 32'h24_00_04_20);
		for (int i = 1; i < 8; i++) write_sram(i, 32'h01_01_01_01);
		trigger_start();
		wait_done();

		check1("done_o (max pkt)", done_o, 1'b1);
		check("res_pkt_len (max)", {26'b0, res_pkt_len}, 32'd32);
		check("res_pkt_type (max)", {24'b0, res_pkt_type}, 32'h04);
		check1("format_ok (max)", format_ok, 1'b1);
		// 28 payload bytes, each 0x01: sum = 28 = 0x1C, xor = 0 (even count)
		check("res_payload_sum (max)", {24'b0, res_payload_sum}, 32'h1C);
		check("res_payload_xor (max)", {24'b0, res_payload_xor}, 32'h00);

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

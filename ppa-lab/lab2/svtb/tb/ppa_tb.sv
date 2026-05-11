// ============================================================================
// Module: ppa_tb
// Description: Lab2 M3 独立 Testbench（行为级 SRAM 模型，不依赖 Lab1）
//   TC1: 最小合法包（pkt_len=4）
//   TC2: 8 字节合法包（含 4B payload，sum/XOR 校验）
//   TC3: 长度下溢（pkt_len=3，length_error=1，不卡死）
//   TC4: 长度上溢（pkt_len=33，length_error=1，不卡死）
//   TC5: busy/done 时序检查
//   TC6: 连续两帧处理
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

	task automatic check(input string name, input bit cond);
		if (cond) begin
			pass_cnt++;
			$display("[%0t] PASS: %s", $time, name);
		end else begin
			fail_cnt++;
			$display("[%0t] FAIL: %s", $time, name);
		end
	endtask

	function automatic logic [31:0] pack_hdr(input [7:0] len, type_, flags, chk);
		return {chk, flags, type_, len};
	endfunction

	// ========================================================================
	// Testcases
	// ========================================================================
	initial begin
		$display("==================== Lab2 TB START ====================");
		do_reset();

		// --------------------------------------------------------------------
		// TC1: 最小合法包 pkt_len=4, type=0x01, hdr_chk=0x05
		// --------------------------------------------------------------------
		$display("---- TC1: tc_min_legal_pkt ----");
		mem[0] = pack_hdr(8'd4, 8'h01, 8'h00, 8'h05);
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("TC1 done_o=1",          done_o === 1'b1);
		check("TC1 busy_o=0",          busy_o === 1'b0);
		check("TC1 res_pkt_len=4",     res_pkt_len_o === 6'd4);
		check("TC1 res_pkt_type=0x01", res_pkt_type_o === 8'h01);
		check("TC1 format_ok=1",       format_ok_o === 1'b1);
		check("TC1 length_error=0",    length_error_o === 1'b0);
		check("TC1 type_error=0",      type_error_o === 1'b0);
		check("TC1 chk_error=0",       chk_error_o === 1'b0);
		check("TC1 payload_sum=0",     res_payload_sum_o === 8'h00);

		// --------------------------------------------------------------------
		// TC2: 8 字节合法包 pkt_len=8, type=0x02, payload=0x04030201
		//   hdr_chk = 0x08 ^ 0x02 ^ 0x00 = 0x0A
		//   payload bytes (LE order in word: 0x01,0x02,0x03,0x04)
		//   sum = 0x01+0x02+0x03+0x04 = 0x0A
		//   xor = 0x01^0x02^0x03^0x04 = 0x04
		// --------------------------------------------------------------------
		$display("---- TC2: tc_8byte_legal ----");
		mem[0] = pack_hdr(8'd8, 8'h02, 8'h00, 8'h0A);
		mem[1] = 32'h04030201;
		algo_mode_i = 1'b1; type_mask_i = 4'b1111; exp_pkt_len_i = 6'd0;
		pulse_start();
		wait_done();
		check("TC2 res_pkt_len=8",       res_pkt_len_o === 6'd8);
		check("TC2 res_pkt_type=0x02",   res_pkt_type_o === 8'h02);
		check("TC2 payload_sum=0x0A",    res_payload_sum_o === 8'h0A);
		check("TC2 payload_xor=0x04",    res_payload_xor_o === 8'h04);
		check("TC2 format_ok=1",         format_ok_o === 1'b1);
		check("TC2 no errors",           {length_error_o,type_error_o,chk_error_o} === 3'b000);

		// --------------------------------------------------------------------
		// TC3: 长度下溢 pkt_len=3
		// --------------------------------------------------------------------
		$display("---- TC3: tc_length_underflow ----");
		mem[0] = pack_hdr(8'd3, 8'h01, 8'h00, 8'h02);
		pulse_start();
		wait_done();
		check("TC3 done_o=1",            done_o === 1'b1);
		check("TC3 length_error=1",      length_error_o === 1'b1);
		check("TC3 format_ok=0",         format_ok_o === 1'b0);
		check("TC3 busy released",       busy_o === 1'b0);

		// --------------------------------------------------------------------
		// TC4: 长度上溢 pkt_len=33
		// --------------------------------------------------------------------
		$display("---- TC4: tc_length_overflow ----");
		mem[0] = pack_hdr(8'd33, 8'h01, 8'h00, 8'h20);
		pulse_start();
		wait_done();
		check("TC4 done_o=1",            done_o === 1'b1);
		check("TC4 length_error=1",      length_error_o === 1'b1);
		check("TC4 format_ok=0",         format_ok_o === 1'b0);
		check("TC4 busy released",       busy_o === 1'b0);

		// --------------------------------------------------------------------
		// TC5: busy/done 时序检查（合法 12B 包）
		//   hdr_chk = 0x0C ^ 0x04 ^ 0x00 = 0x08
		// --------------------------------------------------------------------
		$display("---- TC5: tc_busy_done_timing ----");
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
				check("TC5 busy=1 after start", busy_o === 1'b1);
				check("TC5 done=0 during proc", done_o === 1'b0);
				@(negedge clk);
				start_i = 1'b0;
			end
		join
		wait_done();
		check("TC5 done held in DONE",   done_o === 1'b1);
		check("TC5 busy=0 in DONE",      busy_o === 1'b0);
		// 在 DONE 态保持几拍，结果应保持
		repeat (5) @(posedge clk);
		check("TC5 done still held",     done_o === 1'b1);
		check("TC5 res_pkt_len held=12", res_pkt_len_o === 6'd12);

		// --------------------------------------------------------------------
		// TC6: 连续两帧（DONE 态接受新 start）
		// --------------------------------------------------------------------
		$display("---- TC6: tc_two_frames ----");
		// 第二帧：pkt_len=4, type=0x08, hdr_chk=0x0C
		mem[0] = pack_hdr(8'd4, 8'h08, 8'h00, 8'h0C);
		pulse_start();
		// start 接受后 done 应清零
		@(posedge clk);
		check("TC6 done cleared after new start", done_o === 1'b0);
		wait_done();
		check("TC6 frame2 res_pkt_len=4",   res_pkt_len_o === 6'd4);
		check("TC6 frame2 res_pkt_type=0x08", res_pkt_type_o === 8'h08);
		check("TC6 frame2 format_ok=1",     format_ok_o === 1'b1);

		// --------------------------------------------------------------------
		// 总结
		// --------------------------------------------------------------------
		$display("==================== Lab2 TB SUMMARY ====================");
		$display("PASS: %0d   FAIL: %0d", pass_cnt, fail_cnt);
		if (fail_cnt == 0)
			$display(">>> ALL TESTS PASSED <<<");
		else
			$display(">>> THERE ARE FAILURES <<<");
		$finish;
	end

	// 安全网：避免极端情况下无限挂起
	initial begin
		#100000;
		$display("[%0t] GLOBAL TIMEOUT", $time);
		$finish;
	end

endmodule

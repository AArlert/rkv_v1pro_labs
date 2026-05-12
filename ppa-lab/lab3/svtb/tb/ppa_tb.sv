// ============================================================================
// Module: ppa_tb
// Description: Lab3 集成级 Testbench（端到端验证 ppa_top）
//   TC1: 端到端基本包处理（8B 合法包，验收必做 1）
//   TC2: 连续两帧顺序处理（验收必做 2）
//   TC3: STATUS 总线通路检查（busy/done 状态位，验收必做 3）
// ============================================================================

`timescale 1ns/1ps

module ppa_tb;

	// ========================================================================
	// 信号
	// ========================================================================
	logic        PCLK;
	logic        PRESETn;
	logic        PSEL;
	logic        PENABLE;
	logic        PWRITE;
	logic [11:0] PADDR;
	logic [31:0] PWDATA;
	logic [31:0] PRDATA;
	logic        PREADY;
	logic        PSLVERR;
	logic        irq_o;

	int pass_cnt = 0;
	int fail_cnt = 0;

	// ========================================================================
	// DUT
	// ========================================================================
	ppa_top u_dut (
		.PCLK    (PCLK),
		.PRESETn (PRESETn),
		.PSEL    (PSEL),
		.PENABLE (PENABLE),
		.PWRITE  (PWRITE),
		.PADDR   (PADDR),
		.PWDATA  (PWDATA),
		.PRDATA  (PRDATA),
		.PREADY  (PREADY),
		.PSLVERR (PSLVERR),
		.irq_o   (irq_o)
	);

	// ========================================================================
	// 时钟生成：10ns 周期
	// ========================================================================
	initial PCLK = 0;
	always #5 PCLK = ~PCLK;

	// ========================================================================
	// APB Write Task
	// ========================================================================
	task automatic apb_write(input logic [11:0] addr, input logic [31:0] data);
		@(posedge PCLK);
		PSEL    <= 1'b1;
		PENABLE <= 1'b0;
		PWRITE  <= 1'b1;
		PADDR   <= addr;
		PWDATA  <= data;
		@(posedge PCLK);
		PENABLE <= 1'b1;
		@(posedge PCLK);
		PSEL    <= 1'b0;
		PENABLE <= 1'b0;
		PWRITE  <= 1'b0;
	endtask

	// ========================================================================
	// APB Read Task
	// ========================================================================
	task automatic apb_read(input logic [11:0] addr, output logic [31:0] data);
		@(posedge PCLK);
		PSEL    <= 1'b1;
		PENABLE <= 1'b0;
		PWRITE  <= 1'b0;
		PADDR   <= addr;
		@(posedge PCLK);
		PENABLE <= 1'b1;
		@(posedge PCLK);
		data = PRDATA;
		PSEL    <= 1'b0;
		PENABLE <= 1'b0;
	endtask

	// ========================================================================
	// 辅助 task
	// ========================================================================
	task automatic check(input string name, input logic [31:0] actual, input logic [31:0] expected);
		if (actual === expected) begin
			$display("[PASS] %s: got 0x%08h", name, actual);
			pass_cnt++;
		end else begin
			$display("[FAIL] %s: got 0x%08h, expected 0x%08h", name, actual, expected);
			fail_cnt++;
		end
	endtask

	task automatic poll_done(input int timeout = 100);
		logic [31:0] status;
		int t;
		t = 0;
		do begin
			apb_read(12'h008, status);
			t++;
		end while (!status[1] && t < timeout);
		if (!status[1])
			$display("[%0t] TIMEOUT: done not asserted within %0d polls", $time, timeout);
	endtask

	// ========================================================================
	// 主测试流程
	// ========================================================================
	logic [31:0] rd_data;

	initial begin
		PSEL    = 0;
		PENABLE = 0;
		PWRITE  = 0;
		PADDR   = 0;
		PWDATA  = 0;
		PRESETn = 0;
		repeat (5) @(posedge PCLK);
		PRESETn = 1;
		repeat (2) @(posedge PCLK);

		// ==============================================================
		// TC1: tc_e2e_basic - 端到端基本包处理
		//   pkt_len=8, type=0x02, flags=0x00, hdr_chk=0x08^0x02^0x00=0x0A
		//   payload word1=0x04030201 → sum=0x0A, xor=0x04
		// ==============================================================
		$display("\n========== TC1: tc_e2e_basic ==========");

		// 写 PKT_MEM
		apb_write(12'h040, {8'h0A, 8'h00, 8'h02, 8'h08});  // Word0: hdr
		apb_write(12'h044, 32'h04030201);                    // Word1: payload

		// 使能 + 触发
		apb_write(12'h000, 32'h0000_0001);  // enable=1
		apb_write(12'h000, 32'h0000_0003);  // start (W1P)

		// 轮询 done
		poll_done();

		// 读结果
		apb_read(12'h018, rd_data);
		check("TC1 RES_PKT_LEN",     rd_data, 32'h0000_0008);
		apb_read(12'h01C, rd_data);
		check("TC1 RES_PKT_TYPE",    rd_data, 32'h0000_0002);
		apb_read(12'h020, rd_data);
		check("TC1 RES_PAYLOAD_SUM", rd_data, 32'h0000_000A);
		apb_read(12'h024, rd_data);
		check("TC1 RES_PAYLOAD_XOR", rd_data, 32'h0000_0004);
		apb_read(12'h008, rd_data);
		check("TC1 STATUS (done+format_ok)", rd_data, 32'h0000_000A);
		apb_read(12'h028, rd_data);
		check("TC1 ERR_FLAG (clean)", rd_data, 32'h0000_0000);

		// ==============================================================
		// TC2: tc_two_frames - 连续两帧顺序处理
		//   Frame2: pkt_len=4, type=0x01, hdr_chk=0x04^0x01^0x00=0x05
		// ==============================================================
		$display("\n========== TC2: tc_two_frames ==========");

		apb_write(12'h040, {8'h05, 8'h00, 8'h01, 8'h04});  // Word0: min pkt
		apb_write(12'h000, 32'h0000_0003);                   // start

		poll_done();

		apb_read(12'h018, rd_data);
		check("TC2 Frame2 RES_PKT_LEN",  rd_data, 32'h0000_0004);
		apb_read(12'h01C, rd_data);
		check("TC2 Frame2 RES_PKT_TYPE", rd_data, 32'h0000_0001);
		apb_read(12'h020, rd_data);
		check("TC2 Frame2 RES_PAYLOAD_SUM", rd_data, 32'h0000_0000);
		apb_read(12'h008, rd_data);
		check("TC2 Frame2 STATUS (done+format_ok)", rd_data, 32'h0000_000A);

		// ==============================================================
		// TC3: tc_status_bus - STATUS 总线通路
		//   验证 busy=1 时 STATUS[1:0]=2'b01，done=1 时 STATUS[1:0]=2'b10
		//   使用 12B 包（3 word）确保处理时间足够捕获 busy
		//   pkt_len=12, type=0x04, hdr_chk=0x0C^0x04^0x00=0x08
		// ==============================================================
		$display("\n========== TC3: tc_status_bus ==========");

		apb_write(12'h040, {8'h08, 8'h00, 8'h04, 8'h0C});  // Word0
		apb_write(12'h044, 32'h08070605);                    // Word1
		apb_write(12'h048, 32'h0C0B0A09);                    // Word2

		apb_write(12'h000, 32'h0000_0003);  // start

		// 立即读 STATUS 捕获 busy
		apb_read(12'h008, rd_data);
		check("TC3 STATUS[1:0] during busy", {30'b0, rd_data[1:0]}, 32'h0000_0001);

		// 轮询 done
		poll_done();

		apb_read(12'h008, rd_data);
		check("TC3 STATUS[1:0] during done", {30'b0, rd_data[1:0]}, 32'h0000_0002);

		// ==============================================================
		// 测试总结
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

	// 安全网
	initial begin
		#200000;
		$display("[%0t] GLOBAL TIMEOUT", $time);
		$finish;
	end

endmodule

// ============================================================================
// Module: ppa_tb
// Description: Lab1 Testbench 骨架
//   - 时钟/复位生成
//   - APB write/read task
//   - TC1: CSR 默认值检查
//   - TC2: PKT_MEM 写入映射（含 SRAM 回读自动比对）
//   - TC3: RES_* 读通路
// ============================================================================

`timescale 1ns/1ps

module ppa_tb;

	// ========================================================================
	// 信号定义
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

	logic        enable_o;
	logic        start_o;
	logic        algo_mode_o;
	logic [3:0]  type_mask_o;
	logic [5:0]  exp_pkt_len_o;
	logic        done_irq_en_o;
	logic        err_irq_en_o;

	logic        pkt_mem_we_o;
	logic [2:0]  pkt_mem_addr_o;
	logic [31:0] pkt_mem_wdata_o;

	logic        busy_stub;
	logic        done_stub;
	logic        format_ok_stub;
	logic        length_error_stub;
	logic        type_error_stub;
	logic        chk_error_stub;
	logic [5:0]  res_pkt_len_stub;
	logic [7:0]  res_pkt_type_stub;
	logic [7:0]  res_payload_sum_stub;
	logic [7:0]  res_payload_xor_stub;

	logic        irq_o;

	logic        sram_rd_en;
	logic [2:0]  sram_rd_addr;
	logic [31:0] sram_rd_data;

	int pass_cnt = 0;
	int fail_cnt = 0;

	// ========================================================================
	// DUT 实例化
	// ========================================================================
	ppa_apb_slave_if u_apb_slave (
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
		.enable_o          (enable_o),
		.start_o           (start_o),
		.algo_mode_o       (algo_mode_o),
		.type_mask_o       (type_mask_o),
		.exp_pkt_len_o     (exp_pkt_len_o),
		.done_irq_en_o     (done_irq_en_o),
		.err_irq_en_o      (err_irq_en_o),
		.pkt_mem_we_o      (pkt_mem_we_o),
		.pkt_mem_addr_o    (pkt_mem_addr_o),
		.pkt_mem_wdata_o   (pkt_mem_wdata_o),
		.busy_i            (busy_stub),
		.done_i            (done_stub),
		.format_ok_i       (format_ok_stub),
		.length_error_i    (length_error_stub),
		.type_error_i      (type_error_stub),
		.chk_error_i       (chk_error_stub),
		.res_pkt_len_i     (res_pkt_len_stub),
		.res_pkt_type_i    (res_pkt_type_stub),
		.res_payload_sum_i (res_payload_sum_stub),
		.res_payload_xor_i (res_payload_xor_stub),
		.irq_o             (irq_o)
	);

	ppa_packet_sram u_sram (
		.clk     (PCLK),
		.rst_n   (PRESETn),
		.wr_en   (pkt_mem_we_o),
		.wr_addr (pkt_mem_addr_o),
		.wr_data (pkt_mem_wdata_o),
		.rd_en   (sram_rd_en),
		.rd_addr (sram_rd_addr),
		.rd_data (sram_rd_data)
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
	// 比较辅助 task
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

	// ========================================================================
	// SRAM 回读辅助 task
	// ========================================================================
	task automatic sram_read_check(input int word_idx, input logic [31:0] expected);
		sram_rd_en   = 1;
		sram_rd_addr = word_idx[2:0];
		@(posedge PCLK);
		@(posedge PCLK);
		check($sformatf("SRAM Word[%0d]", word_idx), sram_rd_data, expected);
		sram_rd_en = 0;
	endtask

	// ========================================================================
	// 主测试流程
	// ========================================================================
	logic [31:0] rd_data;
	logic [31:0] pkt_mem_expected [0:7];

	initial begin
		PSEL    = 0;
		PENABLE = 0;
		PWRITE  = 0;
		PADDR   = 0;
		PWDATA  = 0;

		busy_stub            = 0;
		done_stub            = 0;
		format_ok_stub       = 0;
		length_error_stub    = 0;
		type_error_stub      = 0;
		chk_error_stub       = 0;
		res_pkt_len_stub     = 0;
		res_pkt_type_stub    = 0;
		res_payload_sum_stub = 0;
		res_payload_xor_stub = 0;

		sram_rd_en   = 0;
		sram_rd_addr = 0;

		PRESETn = 0;
		repeat(5) @(posedge PCLK);
		PRESETn = 1;
		repeat(2) @(posedge PCLK);

		// ==============================================================
		// TC1: tc_csr_default_rw - CSR 默认值检查
		// ==============================================================
		$display("\n========== TC1: tc_csr_default_rw ==========");

		apb_read(12'h000, rd_data);
		check("CTRL default", rd_data, 32'h0000_0000);

		apb_read(12'h004, rd_data);
		check("CFG default", rd_data, 32'h0000_00F1);

		apb_read(12'h008, rd_data);
		check("STATUS default", rd_data, 32'h0000_0000);

		apb_read(12'h00C, rd_data);
		check("IRQ_EN default", rd_data, 32'h0000_0000);

		apb_read(12'h010, rd_data);
		check("IRQ_STA default", rd_data, 32'h0000_0000);

		apb_read(12'h014, rd_data);
		check("PKT_LEN_EXP default", rd_data, 32'h0000_0000);

		apb_read(12'h018, rd_data);
		check("RES_PKT_LEN default", rd_data, 32'h0000_0000);

		apb_read(12'h01C, rd_data);
		check("RES_PKT_TYPE default", rd_data, 32'h0000_0000);

		apb_read(12'h020, rd_data);
		check("RES_PAYLOAD_SUM default", rd_data, 32'h0000_0000);

		apb_read(12'h024, rd_data);
		check("RES_PAYLOAD_XOR default", rd_data, 32'h0000_0000);

		apb_read(12'h028, rd_data);
		check("ERR_FLAG default", rd_data, 32'h0000_0000);

		// ==============================================================
		// TC2: tc_pkt_mem_write - PKT_MEM 写入映射 + SRAM 回读比对
		// ==============================================================
		$display("\n========== TC2: tc_pkt_mem_write ==========");

		pkt_mem_expected[0] = 32'h0801_0009;
		pkt_mem_expected[1] = 32'hAABB_CCDD;
		pkt_mem_expected[2] = 32'h1111_2222;
		pkt_mem_expected[3] = 32'h3333_4444;
		pkt_mem_expected[4] = 32'h5555_6666;
		pkt_mem_expected[5] = 32'h7777_8888;
		pkt_mem_expected[6] = 32'h9999_AAAA;
		pkt_mem_expected[7] = 32'hBBBB_CCCC;

		for (int i = 0; i < 8; i++) begin
			apb_write(12'h040 + i * 4, pkt_mem_expected[i]);
		end

		repeat(2) @(posedge PCLK);

		for (int i = 0; i < 8; i++) begin
			sram_read_check(i, pkt_mem_expected[i]);
		end

		// ==============================================================
		// TC3: tc_apb_basic_rw - RES_* 读通路（stub 赋值后 APB 读回）
		// ==============================================================
		$display("\n========== TC3: tc_apb_basic_rw ==========");

		res_pkt_len_stub     = 6'd8;
		res_pkt_type_stub    = 8'h02;
		res_payload_sum_stub = 8'hAB;
		res_payload_xor_stub = 8'hCD;
		format_ok_stub       = 1'b1;
		done_stub            = 1'b1;
		length_error_stub    = 1'b0;
		type_error_stub      = 1'b0;
		chk_error_stub       = 1'b0;

		repeat(2) @(posedge PCLK);

		apb_read(12'h018, rd_data);
		check("RES_PKT_LEN", rd_data, 32'h0000_0008);

		apb_read(12'h01C, rd_data);
		check("RES_PKT_TYPE", rd_data, 32'h0000_0002);

		apb_read(12'h020, rd_data);
		check("RES_PAYLOAD_SUM", rd_data, 32'h0000_00AB);

		apb_read(12'h024, rd_data);
		check("RES_PAYLOAD_XOR", rd_data, 32'h0000_00CD);

		apb_read(12'h008, rd_data);
		check("STATUS (done+format_ok)", rd_data, 32'h0000_000A);

		apb_read(12'h028, rd_data);
		check("ERR_FLAG (no error)", rd_data, 32'h0000_0000);

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

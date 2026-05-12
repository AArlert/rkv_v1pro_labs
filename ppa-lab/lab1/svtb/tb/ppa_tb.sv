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
	logic slverr_val;

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
		.pkt_mem_rdata_i   (sram_rd_data),
		.pkt_mem_re_o      (),
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

	task automatic apb_write_with_slverr(input logic [11:0] addr, input logic [31:0] data, output logic slverr);
		@(posedge PCLK);
		PSEL    <= 1'b1;
		PENABLE <= 1'b0;
		PWRITE  <= 1'b1;
		PADDR   <= addr;
		PWDATA  <= data;
		@(posedge PCLK);
		PENABLE <= 1'b1;
		@(posedge PCLK);
		slverr = PSLVERR;
		PSEL    <= 1'b0;
		PENABLE <= 1'b0;
		PWRITE  <= 1'b0;
	endtask

	task automatic apb_read_with_slverr(input logic [11:0] addr, output logic [31:0] data, output logic slverr);
		@(posedge PCLK);
		PSEL    <= 1'b1;
		PENABLE <= 1'b0;
		PWRITE  <= 1'b0;
		PADDR   <= addr;
		@(posedge PCLK);
		PENABLE <= 1'b1;
		@(posedge PCLK);
		data = PRDATA;
		slverr = PSLVERR;
		PSEL    <= 1'b0;
		PENABLE <= 1'b0;
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
		// TC4: tc_slverr_reserved - 保留/越界/非对齐地址 PSLVERR
		// ==============================================================
		$display("\n========== TC4: tc_slverr_reserved ==========");

		apb_write_with_slverr(12'h02C, 32'hAAAA_BBBB, slverr_val);
		check("SLVERR wr 0x02C reserved", {31'b0, slverr_val}, 32'h1);

		apb_read_with_slverr(12'h02C, rd_data, slverr_val);
		check("SLVERR rd 0x02C reserved", {31'b0, slverr_val}, 32'h1);

		apb_write_with_slverr(12'h030, 32'hAAAA_BBBB, slverr_val);
		check("SLVERR wr 0x030 reserved", {31'b0, slverr_val}, 32'h1);

		apb_write_with_slverr(12'h060, 32'hAAAA_BBBB, slverr_val);
		check("SLVERR wr 0x060 OOB", {31'b0, slverr_val}, 32'h1);

		apb_read_with_slverr(12'h100, rd_data, slverr_val);
		check("SLVERR rd 0x100 OOB", {31'b0, slverr_val}, 32'h1);

		apb_write_with_slverr(12'h003, 32'hAAAA_BBBB, slverr_val);
		check("SLVERR wr 0x003 unaligned", {31'b0, slverr_val}, 32'h1);

		// ==============================================================
		// TC5: tc_ro_write_protect - RO 寄存器写保护
		// ==============================================================
		$display("\n========== TC5: tc_ro_write_protect ==========");

		apb_write_with_slverr(12'h008, 32'hFFFF_FFFF, slverr_val);
		check("SLVERR wr STATUS", {31'b0, slverr_val}, 32'h1);
		apb_read(12'h008, rd_data);
		check("STATUS unchanged", rd_data, 32'h0000_000A);

		apb_write_with_slverr(12'h018, 32'hFFFF_FFFF, slverr_val);
		check("SLVERR wr RES_PKT_LEN", {31'b0, slverr_val}, 32'h1);
		apb_read(12'h018, rd_data);
		check("RES_PKT_LEN unchanged", rd_data, 32'h0000_0008);

		apb_write_with_slverr(12'h01C, 32'hFFFF_FFFF, slverr_val);
		check("SLVERR wr RES_PKT_TYPE", {31'b0, slverr_val}, 32'h1);
		apb_read(12'h01C, rd_data);
		check("RES_PKT_TYPE unchanged", rd_data, 32'h0000_0002);

		apb_write_with_slverr(12'h020, 32'hFFFF_FFFF, slverr_val);
		check("SLVERR wr RES_PAYLOAD_SUM", {31'b0, slverr_val}, 32'h1);
		apb_read(12'h020, rd_data);
		check("RES_PAYLOAD_SUM unchanged", rd_data, 32'h0000_00AB);

		apb_write_with_slverr(12'h024, 32'hFFFF_FFFF, slverr_val);
		check("SLVERR wr RES_PAYLOAD_XOR", {31'b0, slverr_val}, 32'h1);
		apb_read(12'h024, rd_data);
		check("RES_PAYLOAD_XOR unchanged", rd_data, 32'h0000_00CD);

		apb_write_with_slverr(12'h028, 32'hFFFF_FFFF, slverr_val);
		check("SLVERR wr ERR_FLAG", {31'b0, slverr_val}, 32'h1);
		apb_read(12'h028, rd_data);
		check("ERR_FLAG unchanged", rd_data, 32'h0000_0000);

		// ==============================================================
		// TC6: tc_w1p_start - W1P 行为
		// ==============================================================
		$display("\n========== TC6: tc_w1p_start ==========");

		busy_stub = 0;

		apb_write(12'h000, 32'h0000_0001);
		apb_write(12'h000, 32'h0000_0003);
		@(posedge PCLK);
		check("start_o pulse", {31'b0, start_o}, 32'h1);
		@(posedge PCLK);
		check("start_o deasserted", {31'b0, start_o}, 32'h0);

		apb_read(12'h000, rd_data);
		check("CTRL start reads 0", rd_data, 32'h0000_0001);

		apb_write(12'h000, 32'h0000_0000);
		apb_write(12'h000, 32'h0000_0002);
		@(posedge PCLK);
		check("start_o no pulse (enable=0)", {31'b0, start_o}, 32'h0);

		apb_write(12'h000, 32'h0000_0001);
		busy_stub = 1;
		apb_write(12'h000, 32'h0000_0003);
		@(posedge PCLK);
		check("start_o no pulse (busy=1)", {31'b0, start_o}, 32'h0);
		busy_stub = 0;

		// ==============================================================
		// TC7: tc_rw1c_irq_sta - RW1C 行为
		// ==============================================================
		$display("\n========== TC7: tc_rw1c_irq_sta ==========");

		done_stub = 0;
		repeat(2) @(posedge PCLK);

		apb_write(12'h00C, 32'h0000_0001);

		done_stub = 1;
		repeat(2) @(posedge PCLK);

		apb_read(12'h010, rd_data);
		check("IRQ_STA done_irq set", rd_data, 32'h0000_0001);

		apb_write(12'h010, 32'h0000_0001);
		repeat(1) @(posedge PCLK);

		apb_read(12'h010, rd_data);
		check("IRQ_STA done_irq cleared", rd_data, 32'h0000_0000);

		// ==============================================================
		// TC8: tc_busy_write_protect - busy 写保护
		// ==============================================================
		$display("\n========== TC8: tc_busy_write_protect ==========");

		busy_stub = 0;

		apb_write_with_slverr(12'h040, 32'h1234_5678, slverr_val);
		check("SLVERR wr PKT_MEM busy=0", {31'b0, slverr_val}, 32'h0);

		repeat(2) @(posedge PCLK);

		busy_stub = 1;
		apb_write_with_slverr(12'h040, 32'hDEAD_BEEF, slverr_val);
		check("SLVERR wr PKT_MEM busy=1", {31'b0, slverr_val}, 32'h1);

		busy_stub = 0;
		sram_read_check(0, 32'h1234_5678);

		// ==============================================================
		// TC9: tc_irq_logic - 中断路径完整
		// ==============================================================
		$display("\n========== TC9: tc_irq_logic ==========");

		done_stub = 0;
		length_error_stub = 0;
		type_error_stub = 0;
		chk_error_stub = 0;
		repeat(2) @(posedge PCLK);
		apb_write(12'h00C, 32'h0000_0000);
		apb_write(12'h010, 32'h0000_0003);

		apb_write(12'h00C, 32'h0000_0001);
		done_stub = 1;
		repeat(2) @(posedge PCLK);
		check("irq_o=1 (done_irq)", {31'b0, irq_o}, 32'h1);

		apb_write(12'h010, 32'h0000_0001);
		repeat(1) @(posedge PCLK);
		check("irq_o=0 (done_irq cleared)", {31'b0, irq_o}, 32'h0);

		done_stub = 0;
		repeat(2) @(posedge PCLK);
		apb_write(12'h00C, 32'h0000_0002);
		length_error_stub = 1;
		done_stub = 1;
		repeat(2) @(posedge PCLK);
		check("irq_o=1 (err_irq)", {31'b0, irq_o}, 32'h1);

		apb_write(12'h010, 32'h0000_0002);
		repeat(1) @(posedge PCLK);
		check("irq_o=0 (err_irq cleared)", {31'b0, irq_o}, 32'h0);
		length_error_stub = 0;

		// ==============================================================
		// TC10: tc_rw_readback - RW 寄存器写后读
		// ==============================================================
		$display("\n========== TC10: tc_rw_readback ==========");

		apb_write(12'h000, 32'h0000_0001);
		apb_read(12'h000, rd_data);
		check("CTRL readback", rd_data, 32'h0000_0001);

		apb_write(12'h004, 32'h0000_00A0);
		apb_read(12'h004, rd_data);
		check("CFG readback", rd_data, 32'h0000_00A0);

		apb_write(12'h00C, 32'h0000_0003);
		apb_read(12'h00C, rd_data);
		check("IRQ_EN readback", rd_data, 32'h0000_0003);

		apb_write(12'h014, 32'h0000_0020);
		apb_read(12'h014, rd_data);
		check("PKT_LEN_EXP readback", rd_data, 32'h0000_0020);

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

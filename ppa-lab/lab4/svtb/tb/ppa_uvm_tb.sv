// ============================================================================
// File: ppa_uvm_tb.sv
// Description: UVM top — clock/reset gen, ppa_top instantiation, vif binding,
//              listener for "ppa_rst_req" event so OP_RESET can re-pulse PRESETn.
// ============================================================================

`timescale 1ns/1ps

module ppa_uvm_tb;
	import uvm_pkg::*;
	import ppa_pkg::*;
	`include "uvm_macros.svh"

	// ---- clock ----
	logic PCLK = 1'b0;
	always #5 PCLK = ~PCLK;   // 100 MHz

	// ---- reset ----
	logic PRESETn = 1'b0;

	// ---- APB IF ----
	ppa_apb_if vif(.PCLK(PCLK), .PRESETn(PRESETn));

	// ---- DUT ----
	ppa_top dut (
		.PCLK    (PCLK),
		.PRESETn (PRESETn),
		.PSEL    (vif.PSEL),
		.PENABLE (vif.PENABLE),
		.PWRITE  (vif.PWRITE),
		.PADDR   (vif.PADDR),
		.PWDATA  (vif.PWDATA),
		.PRDATA  (vif.PRDATA),
		.PREADY  (vif.PREADY),
		.PSLVERR (vif.PSLVERR),
		.irq_o   (vif.irq_o)
	);

	// ---- initial reset ----
	initial begin
		PRESETn = 1'b0;
		repeat (10) @(posedge PCLK);
		PRESETn = 1'b1;
	end

	// ---- listener: re-pulse PRESETn when driver triggers OP_RESET ----
	initial begin
		uvm_event ev;
		ev = uvm_event_pool::get_global_pool().get("ppa_rst_req");
		forever begin
			ev.wait_trigger();
			ev.reset();
			@(posedge PCLK);
			PRESETn = 1'b0;
			repeat (5) @(posedge PCLK);
			PRESETn = 1'b1;
		end
	end

	// ---- UVM hookup ----
	initial begin
		uvm_config_db#(virtual ppa_apb_if)::set(null, "*", "vif", vif);
		run_test();
	end

	// ---- Waveform dump (optional, controlled by +DUMP) ----
	initial begin
		if ($test$plusargs("DUMP")) begin
			$dumpfile("ppa_uvm.vcd");
			$dumpvars(0, ppa_uvm_tb);
		end
	end

endmodule

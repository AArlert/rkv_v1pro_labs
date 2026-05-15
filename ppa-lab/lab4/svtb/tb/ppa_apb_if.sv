// ============================================================================
// File: ppa_apb_if.sv
// Description: APB interface for ppa_top + irq_o passive observation
// ============================================================================

`timescale 1ns/1ps

interface ppa_apb_if(input logic PCLK, input logic PRESETn);
	logic        PSEL;
	logic        PENABLE;
	logic        PWRITE;
	logic [11:0] PADDR;
	logic [31:0] PWDATA;
	logic [31:0] PRDATA;
	logic        PREADY;
	logic        PSLVERR;
	logic        irq_o;

	clocking drv_ck @(posedge PCLK);
		default input #1ns output #1ns;
		output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
		input  PRDATA, PREADY, PSLVERR, irq_o;
	endclocking

	clocking mon_ck @(posedge PCLK);
		default input #1ns output #1ns;
		input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR, irq_o;
	endclocking
endinterface

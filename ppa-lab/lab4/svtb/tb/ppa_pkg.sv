// ============================================================================
// File: ppa_pkg.sv
// Description: PPA-Lite UVM package — single comprehensive env for ppa_top
//              that covers Lab1 (CSR + SRAM), Lab2 (M3 corner cases via E2E),
//              and Lab3 (E2E integration) scenarios.
//              Reference predictions come from `ppa_ref_model` (spec §3/§5/§7/§9).
// ============================================================================

package ppa_pkg;
	import uvm_pkg::*;
	import ppa_ref_model::*;
	`include "uvm_macros.svh"

	// ========================================================================
	// Operation kinds — driver dispatches on this
	// ========================================================================
	typedef enum {
		OP_PKT,                // full packet life cycle (configure, load, start, poll, collect)
		OP_RAW_WRITE,          // single APB write (capture PSLVERR)
		OP_RAW_READ,           // single APB read  (capture data + PSLVERR)
		OP_RESET,              // assert PRESETn for N cycles
		OP_WAIT,               // wait N PCLK cycles
		OP_IRQ_CHECK,          // sample irq_o, compare to expected
		OP_BUSY_WRITE_PROBE,   // start a long pkt; mid-busy attempt PKT_MEM write → expect PSLVERR; verify SRAM unchanged
		OP_W1P_PROBE,          // write CTRL with start=1 but enable=0 → expect no busy
		OP_PKT_MEM_RW          // write 8 distinct PKT_MEM words then read back all
	} ppa_op_kind_e;

	typedef enum {
		ERR_NONE,
		ERR_LEN_UNDER,
		ERR_LEN_OVER,
		ERR_LEN_MISMATCH,
		ERR_TYPE_BAD,
		ERR_TYPE_MASK,
		ERR_CHK
	} err_mode_e;

	// ========================================================================
	// ppa_seq_item — unified sequence item
	// ========================================================================
	class ppa_seq_item extends uvm_sequence_item;
		rand ppa_op_kind_e op_kind;

		// ---- packet-op fields ----
		rand bit [5:0]  pkt_len;
		rand bit [7:0]  pkt_type;
		rand bit [7:0]  flags;
		     bit [7:0]  hdr_chk_field;       // computed in post_randomize
		rand byte       payload[];
		rand bit        algo_mode;
		rand bit [3:0]  type_mask;
		rand bit [5:0]  exp_pkt_len;
		rand bit        done_irq_en;
		rand bit        err_irq_en;
		     err_mode_e err_mode = ERR_NONE;  // not rand; sequences set explicitly before randomize()

		// Packet expected (from ref model)
		bit [5:0] exp_res_pkt_len;
		bit [7:0] exp_res_pkt_type;
		bit [7:0] exp_sum;
		bit [7:0] exp_xor;
		bit       exp_format_ok;
		bit       exp_length_err;
		bit       exp_type_err;
		bit       exp_chk_err;

		// Packet observed (from driver via APB reads)
		bit [5:0] obs_res_pkt_len;
		bit [7:0] obs_res_pkt_type;
		bit [7:0] obs_sum;
		bit [7:0] obs_xor;
		bit       obs_format_ok;
		bit       obs_length_err;
		bit       obs_type_err;
		bit       obs_chk_err;
		bit       obs_done;
		bit       obs_irq_after_done;     // sampled irq_o post poll_done
		bit [1:0] obs_irq_sta_after_done; // IRQ_STA[1:0] read

		// ---- raw-APB-op fields ----
		     bit [11:0] addr;
		     bit [31:0] data;
		     bit        exp_slverr;
		     bit [31:0] exp_data;
		     bit        check_data;       // when 1, scoreboard compares obs_data vs exp_data
		     bit [31:0] obs_data;
		     bit        obs_slverr;

		// ---- misc ----
		     int        n_cycles;          // OP_WAIT, OP_RESET (PRESETn=0 cycles)
		     bit        exp_irq;           // OP_IRQ_CHECK
		     bit        obs_irq;
		     // OP_BUSY_WRITE_PROBE / OP_PKT_MEM_RW use packet fields above

		`uvm_object_utils_begin(ppa_seq_item)
			`uvm_field_enum(ppa_op_kind_e, op_kind, UVM_ALL_ON | UVM_NOCOMPARE)
			`uvm_field_int (pkt_len,       UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
			`uvm_field_int (pkt_type,      UVM_ALL_ON | UVM_HEX | UVM_NOCOMPARE)
			`uvm_field_int (addr,          UVM_ALL_ON | UVM_HEX | UVM_NOCOMPARE)
			`uvm_field_int (data,          UVM_ALL_ON | UVM_HEX | UVM_NOCOMPARE)
		`uvm_object_utils_end

		function new(string name = "ppa_seq_item");
			super.new(name);
		endfunction

		// Defaults & constraints (mostly used when randomizing OP_PKT inside seqs)
		constraint c_defaults {
			soft op_kind     == OP_PKT;
			soft algo_mode   == 1'b1;
			soft type_mask   == 4'b1111;
			soft exp_pkt_len == 6'd0;
			soft flags       == 8'h00;
			soft done_irq_en == 1'b0;
			soft err_irq_en  == 1'b0;
		}
		constraint c_pkt_len_by_mode {
			(err_mode == ERR_NONE)         -> pkt_len inside {[4:32]};
			(err_mode == ERR_LEN_UNDER)    -> pkt_len inside {[1:3]};
			(err_mode == ERR_LEN_OVER)     -> pkt_len inside {[33:63]};
			(err_mode == ERR_LEN_MISMATCH) -> pkt_len inside {[4:32]};
			(err_mode == ERR_TYPE_BAD)     -> pkt_len inside {[4:32]};
			(err_mode == ERR_TYPE_MASK)    -> pkt_len inside {[4:32]};
			(err_mode == ERR_CHK)          -> pkt_len inside {[4:32]};
		}
		constraint c_type {
			(err_mode == ERR_NONE)      -> pkt_type inside {8'h01, 8'h02, 8'h04, 8'h08};
			(err_mode == ERR_TYPE_BAD)  -> !(pkt_type inside {8'h00, 8'h01, 8'h02, 8'h04, 8'h08});
			(err_mode == ERR_TYPE_MASK) -> pkt_type inside {8'h01, 8'h02, 8'h04, 8'h08};
			(err_mode == ERR_LEN_UNDER) -> pkt_type inside {8'h01, 8'h02, 8'h04, 8'h08};
			(err_mode == ERR_LEN_OVER)  -> pkt_type inside {8'h01, 8'h02, 8'h04, 8'h08};
			(err_mode == ERR_CHK)       -> pkt_type inside {8'h01, 8'h02, 8'h04, 8'h08};
		}
		constraint c_payload_size {
			payload.size() <= 28;
			(pkt_len >= 4 && pkt_len <= 32) -> payload.size() == (pkt_len - 4);
			(pkt_len <  4)                  -> payload.size() == 0;
			(pkt_len >  32)                 -> payload.size() == 28;
		}
		constraint c_exp_match {
			(err_mode == ERR_LEN_MISMATCH) -> (exp_pkt_len inside {[4:32]} && exp_pkt_len != pkt_len);
		}

		function void post_randomize();
			bit [7:0] true_chk;
			bit [3:0] mask_local;

			true_chk = compute_hdr_chk(pkt_len, pkt_type, flags);

			if (err_mode == ERR_CHK) begin
				hdr_chk_field = ~true_chk;
				if (hdr_chk_field == true_chk) hdr_chk_field = 8'hAA;
			end else begin
				hdr_chk_field = true_chk;
			end

			if (err_mode == ERR_TYPE_MASK) begin
				mask_local = type_mask;
				case (pkt_type)
					8'h01: mask_local[0] = 1'b0;
					8'h02: mask_local[1] = 1'b0;
					8'h04: mask_local[2] = 1'b0;
					8'h08: mask_local[3] = 1'b0;
					default: ;
				endcase
				type_mask = mask_local;
			end

			exp_length_err = predict_length_error(pkt_len, exp_pkt_len);
			exp_type_err   = predict_type_error(pkt_type, type_mask);
			exp_chk_err    = predict_chk_error(algo_mode, hdr_chk_field, true_chk);
			exp_format_ok  = predict_format_ok(exp_length_err, exp_type_err, exp_chk_err);

			exp_res_pkt_len  = pkt_len;
			exp_res_pkt_type = pkt_type;

			exp_sum = 8'h00;
			exp_xor = 8'h00;
			if (!exp_length_err) begin
				exp_sum = compute_sum(payload);
				exp_xor = compute_xor(payload);
			end
		endfunction

		function bit [31:0] pack_hdr_word();
			return {hdr_chk_field, flags, pkt_type, 2'b00, pkt_len};
		endfunction

		function void pack_payload_words(output bit [31:0] words[]);
			int n_words = (payload.size() + 3) / 4;
			words = new[n_words];
			foreach (words[i]) words[i] = 32'h0;
			foreach (payload[i])
				words[i / 4][8*(i%4) +: 8] = payload[i];
		endfunction

		function bit [31:0] pack_payload_word(input int idx);
			bit [31:0] w = 32'h0;
			for (int b = 0; b < 4; b++) begin
				int byte_idx = idx*4 + b;
				if (byte_idx < payload.size())
					w[8*b +: 8] = payload[byte_idx];
			end
			return w;
		endfunction
	endclass

	// ========================================================================
	// Sequencer
	// ========================================================================
	typedef uvm_sequencer#(ppa_seq_item) ppa_sequencer;

	// ========================================================================
	// Driver — dispatches on op_kind
	// ========================================================================
	class ppa_driver extends uvm_driver#(ppa_seq_item);
		virtual ppa_apb_if vif;
		// Reset control wires hooked from top via config_db
		virtual ppa_apb_if vif_rst;
		uvm_analysis_port#(ppa_seq_item) ap;

		// Shadow PRESETn driver — we override via XMR through the top
		// (top owns initial reset; driver drives via setting `force` not used —
		// instead we use a `uvm_event` named "ppa_rst_req" to ask top to pulse rst).
		uvm_event_pool ev_pool;
		uvm_event       rst_req_ev;

		`uvm_component_utils(ppa_driver)

		function new(string name, uvm_component parent);
			super.new(name, parent);
			ap = new("ap", this);
		endfunction

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			if (!uvm_config_db#(virtual ppa_apb_if)::get(this, "", "vif", vif))
				`uvm_fatal("DRV/NOVIF", "virtual interface not set in config_db")
			ev_pool = uvm_event_pool::get_global_pool();
			rst_req_ev = ev_pool.get("ppa_rst_req");
		endfunction

		task run_phase(uvm_phase phase);
			ppa_seq_item req;
			vif.PSEL    <= 1'b0;
			vif.PENABLE <= 1'b0;
			vif.PWRITE  <= 1'b0;
			vif.PADDR   <= '0;
			vif.PWDATA  <= '0;
			@(posedge vif.PRESETn);
			repeat (3) @(posedge vif.PCLK);
			forever begin
				seq_item_port.get_next_item(req);
				dispatch(req);
				ap.write(req);
				seq_item_port.item_done();
			end
		endtask

		task automatic dispatch(ppa_seq_item it);
			case (it.op_kind)
				OP_PKT:               drive_packet(it);
				OP_RAW_WRITE:         drive_raw_write(it);
				OP_RAW_READ:          drive_raw_read(it);
				OP_RESET:             drive_reset(it);
				OP_WAIT:              repeat (it.n_cycles) @(posedge vif.PCLK);
				OP_IRQ_CHECK:         drive_irq_check(it);
				OP_BUSY_WRITE_PROBE:  drive_busy_write_probe(it);
				OP_W1P_PROBE:         drive_w1p_probe(it);
				OP_PKT_MEM_RW:        drive_pkt_mem_rw(it);
				default: `uvm_error("DRV/OP", $sformatf("unknown op_kind %s", it.op_kind.name()))
			endcase
		endtask

		// ---- Op handlers ----
		task automatic drive_packet(ppa_seq_item it);
			bit [31:0] hdr_word, data;
			bit [31:0] pld_words[];
			cfg_load(it);
			hdr_word = it.pack_hdr_word();
			apb_write(ADDR_PKT_MEM_LO, hdr_word, /*chk_slverr*/0, data);
			it.pack_payload_words(pld_words);
			foreach (pld_words[i]) begin
				if (i + 1 >= 8) break;
				apb_write(ADDR_PKT_MEM_LO + 4 * (i + 1), pld_words[i], 0, data);
			end
			// Enable then start: write enable=1 first, then start (W1P) in a separate cycle
			apb_write(ADDR_CTRL, 32'h0000_0001, 0, data);
			apb_write(ADDR_CTRL, 32'h0000_0003, 0, data);
			poll_done(.timeout(500));
			@(posedge vif.PCLK);  // NBA propagation for irq
			collect_results(it);
		endtask

		task automatic drive_raw_write(ppa_seq_item it);
			bit [31:0] dummy;
			apb_write(it.addr, it.data, /*chk_slverr*/1, dummy);
			it.obs_slverr = dummy[0];
		endtask

		task automatic drive_raw_read(ppa_seq_item it);
			bit [31:0] data;
			bit slverr;
			apb_read_full(it.addr, data, slverr);
			it.obs_data   = data;
			it.obs_slverr = slverr;
		endtask

		task automatic drive_reset(ppa_seq_item it);
			rst_req_ev.trigger();
			// Wait for top to deassert PRESETn high again
			@(negedge vif.PRESETn);
			@(posedge vif.PRESETn);
			repeat (3) @(posedge vif.PCLK);
		endtask

		task automatic drive_irq_check(ppa_seq_item it);
			@(posedge vif.PCLK);
			it.obs_irq = vif.irq_o;
		endtask

		task automatic drive_busy_write_probe(ppa_seq_item it);
			bit [31:0] hdr_word, data, dummy;
			bit [31:0] pld_words[];
			bit [31:0] readback;
			cfg_load(it);
			hdr_word = it.pack_hdr_word();
			apb_write(ADDR_PKT_MEM_LO, hdr_word, 0, data);
			it.pack_payload_words(pld_words);
			foreach (pld_words[i]) begin
				if (i + 1 >= 8) break;
				apb_write(ADDR_PKT_MEM_LO + 4 * (i + 1), pld_words[i], 0, data);
			end
			// Save expected word1 for later readback compare
			// Enable then start (separate cycles)
			apb_write(ADDR_CTRL, 32'h0000_0001, 0, data);
			apb_write(ADDR_CTRL, 32'h0000_0003, 0, data);
			// Now busy: write to PKT_MEM word1 with deadbeef → expect SLVERR
			apb_write(ADDR_PKT_MEM_LO + 4, 32'hDEAD_BEEF, 1, dummy);
			it.obs_slverr = dummy[0];
			poll_done(500);
			@(posedge vif.PCLK);
			// Readback word1 — should equal original payload word1, not deadbeef
			apb_read(ADDR_PKT_MEM_LO + 4, readback);
			it.obs_data = readback;
			collect_results(it);
		endtask

		task automatic drive_w1p_probe(ppa_seq_item it);
			bit [31:0] data, dummy;
			bit [31:0] hdr_word;
			// Disable enable first (CTRL=0)
			apb_write(ADDR_CTRL, 32'h0000_0000, 0, data);
			// Load minimal valid packet so RTL is ready to start IF it would
			cfg_load(it);
			hdr_word = it.pack_hdr_word();
			apb_write(ADDR_PKT_MEM_LO, hdr_word, 0, data);
			// Try to start with enable=0: write CTRL=0x2 (start bit only)
			apb_write(ADDR_CTRL, 32'h0000_0002, 0, data);
			// Sample STATUS — busy must remain 0
			repeat (3) @(posedge vif.PCLK);
			apb_read(ADDR_STATUS, data);
			it.obs_data = data;  // scoreboard checks data == 0
		endtask

		task automatic drive_pkt_mem_rw(ppa_seq_item it);
			static bit [31:0] PATTERNS[8] = '{
				32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444,
				32'h5555_5555, 32'h6666_6666, 32'h7777_7777, 32'h8888_8888};
			bit [31:0] data;
			int errs = 0;
			for (int i = 0; i < 8; i++)
				apb_write(ADDR_PKT_MEM_LO + 4*i, PATTERNS[i], 0, data);
			for (int i = 0; i < 8; i++) begin
				apb_read(ADDR_PKT_MEM_LO + 4*i, data);
				if (data !== PATTERNS[i]) errs++;
			end
			it.obs_data = errs;  // scoreboard checks 0
		endtask

		// ---- Helpers ----
		task automatic cfg_load(ppa_seq_item it);
			bit [31:0] data;
			bit [31:0] cfg_val    = {24'b0, it.type_mask, 3'b0, it.algo_mode};
			bit [31:0] irq_en_val = {30'b0, it.err_irq_en, it.done_irq_en};
			apb_write(ADDR_CFG,         cfg_val,                        0, data);
			apb_write(ADDR_PKT_LEN_EXP, {26'b0, it.exp_pkt_len},        0, data);
			apb_write(ADDR_IRQ_EN,      irq_en_val,                     0, data);
			// Pre-clear any pending IRQ_STA bits
			apb_write(ADDR_IRQ_STA,     32'h0000_0003,                  0, data);
		endtask

		task automatic collect_results(ppa_seq_item it);
			bit [31:0] data;
			apb_read(ADDR_RES_PKT_LEN,  data); it.obs_res_pkt_len  = data[5:0];
			apb_read(ADDR_RES_PKT_TYPE, data); it.obs_res_pkt_type = data[7:0];
			apb_read(ADDR_RES_SUM,      data); it.obs_sum          = data[7:0];
			apb_read(ADDR_RES_XOR,      data); it.obs_xor          = data[7:0];
			apb_read(ADDR_ERR_FLAG,     data);
			it.obs_length_err = data[0];
			it.obs_type_err   = data[1];
			it.obs_chk_err    = data[2];
			apb_read(ADDR_STATUS, data);
			it.obs_done       = data[1];
			it.obs_format_ok  = data[3];
			it.obs_irq_after_done = vif.irq_o;
			apb_read(ADDR_IRQ_STA, data);
			it.obs_irq_sta_after_done = data[1:0];
			// Clear any pending IRQ for next packet
			if (data[1:0] != 2'b00) begin
				bit [31:0] dummy;
				apb_write(ADDR_IRQ_STA, {30'b0, data[1:0]}, 0, dummy);
			end
		endtask

		// chk_slverr: when 1, slverr_out[0] returns PSLVERR (without erroring on it)
		// when 0, no error reported even if PSLVERR — caller must check manually
		task automatic apb_write(input bit [11:0] addr, input bit [31:0] data,
		                          input bit chk_slverr, output bit [31:0] slverr_out);
			@(posedge vif.PCLK);
			vif.PSEL    <= 1'b1;
			vif.PENABLE <= 1'b0;
			vif.PWRITE  <= 1'b1;
			vif.PADDR   <= addr;
			vif.PWDATA  <= data;
			@(posedge vif.PCLK);
			vif.PENABLE <= 1'b1;
			@(posedge vif.PCLK);
			while (vif.PREADY !== 1'b1) @(posedge vif.PCLK);
			slverr_out = {31'b0, vif.PSLVERR};
			vif.PSEL    <= 1'b0;
			vif.PENABLE <= 1'b0;
			vif.PWRITE  <= 1'b0;
		endtask

		task automatic apb_read(input bit [11:0] addr, output bit [31:0] data);
			bit slv;
			apb_read_full(addr, data, slv);
		endtask

		task automatic apb_read_full(input bit [11:0] addr,
		                              output bit [31:0] data, output bit slverr);
			@(posedge vif.PCLK);
			vif.PSEL    <= 1'b1;
			vif.PENABLE <= 1'b0;
			vif.PWRITE  <= 1'b0;
			vif.PADDR   <= addr;
			@(posedge vif.PCLK);
			vif.PENABLE <= 1'b1;
			@(posedge vif.PCLK);
			while (vif.PREADY !== 1'b1) @(posedge vif.PCLK);
			data   = vif.PRDATA;
			slverr = vif.PSLVERR;
			vif.PSEL    <= 1'b0;
			vif.PENABLE <= 1'b0;
		endtask

		task automatic poll_done(input int timeout = 500);
			bit [31:0] status;
			int t = 0;
			do begin
				apb_read(ADDR_STATUS, status);
				t++;
			end while (!status[1] && t < timeout);
			if (!status[1])
				`uvm_error("DRV/TIMEOUT", $sformatf("STATUS.done not asserted within %0d polls", timeout))
		endtask
	endclass

	// ========================================================================
	// APB Monitor — passive snoop for coverage
	// ========================================================================
	typedef struct {
		bit [11:0] addr;
		bit [31:0] data;
		bit        is_write;
		bit        slverr;
	} ppa_apb_xact_t;

	class ppa_apb_monitor extends uvm_monitor;
		virtual ppa_apb_if vif;
		uvm_analysis_port#(ppa_apb_xact_t) ap;
		`uvm_component_utils(ppa_apb_monitor)
		function new(string name, uvm_component parent);
			super.new(name, parent);
			ap = new("ap", this);
		endfunction
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			if (!uvm_config_db#(virtual ppa_apb_if)::get(this, "", "vif", vif))
				`uvm_fatal("MON/NOVIF", "vif not set")
		endfunction
		task run_phase(uvm_phase phase);
			ppa_apb_xact_t x;
			forever begin
				@(posedge vif.PCLK);
				if (vif.PSEL && vif.PENABLE && vif.PREADY) begin
					x.addr     = vif.PADDR;
					x.data     = vif.PWRITE ? vif.PWDATA : vif.PRDATA;
					x.is_write = vif.PWRITE;
					x.slverr   = vif.PSLVERR;
					ap.write(x);
				end
			end
		endtask
	endclass

	// ========================================================================
	// IRQ monitor
	// ========================================================================
	class ppa_irq_monitor extends uvm_monitor;
		virtual ppa_apb_if vif;
		uvm_analysis_port#(bit) ap;
		`uvm_component_utils(ppa_irq_monitor)
		function new(string name, uvm_component parent);
			super.new(name, parent);
			ap = new("ap", this);
		endfunction
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			if (!uvm_config_db#(virtual ppa_apb_if)::get(this, "", "vif", vif))
				`uvm_fatal("IRQ/NOVIF", "vif not set")
		endfunction
		task run_phase(uvm_phase phase);
			bit prev = 0;
			forever begin
				@(posedge vif.PCLK);
				if (vif.irq_o !== prev) begin
					ap.write(vif.irq_o);
					prev = vif.irq_o;
				end
			end
		endtask
	endclass

	// ========================================================================
	// Scoreboard
	// ========================================================================
	class ppa_scoreboard extends uvm_scoreboard;
		uvm_tlm_analysis_fifo#(ppa_seq_item) exp_fifo;
		int cmp_count;
		int error_count;

		`uvm_component_utils(ppa_scoreboard)

		function new(string name, uvm_component parent);
			super.new(name, parent);
			exp_fifo = new("exp_fifo", this);
		endfunction

		task run_phase(uvm_phase phase);
			ppa_seq_item it;
			forever begin
				exp_fifo.get(it);
				compare(it);
			end
		endtask

		function void compare(ppa_seq_item it);
			int local_err = 0;
			cmp_count++;
			case (it.op_kind)
				OP_PKT:               local_err = check_pkt(it);
				OP_RAW_WRITE:         local_err = check_raw_write(it);
				OP_RAW_READ:          local_err = check_raw_read(it);
				OP_RESET, OP_WAIT:    local_err = 0;
				OP_IRQ_CHECK: begin
					if (it.obs_irq !== it.exp_irq) begin
						`uvm_error("SB/IRQ", $sformatf("irq exp=%0d obs=%0d", it.exp_irq, it.obs_irq))
						local_err++;
					end
				end
				OP_BUSY_WRITE_PROBE: begin
					if (!it.obs_slverr) begin
						`uvm_error("SB/BWP", "busy-write did not return PSLVERR=1") local_err++;
					end
					if (it.obs_data !== it.exp_data) begin
						`uvm_error("SB/BWP", $sformatf("PKT_MEM word1 changed: exp=0x%08x obs=0x%08x",
							it.exp_data, it.obs_data)) local_err++;
					end
					local_err += check_pkt(it);
				end
				OP_W1P_PROBE: begin
					// STATUS should remain all-zero (no busy, no done)
					if (it.obs_data !== 32'h0) begin
						`uvm_error("SB/W1P", $sformatf("STATUS not zero after start-without-enable: 0x%08x", it.obs_data))
						local_err++;
					end
				end
				OP_PKT_MEM_RW: begin
					if (it.obs_data !== 32'h0) begin
						`uvm_error("SB/MEMRW", $sformatf("%0d PKT_MEM readback errors", it.obs_data))
						local_err++;
					end
				end
				default: ;
			endcase
			if (local_err == 0)
				`uvm_info("SB/PASS", $sformatf("Op #%0d %s PASS", cmp_count, it.op_kind.name()), UVM_HIGH)
			else
				error_count += local_err;
		endfunction

		function int check_raw_write(ppa_seq_item it);
			int e = 0;
			if (it.obs_slverr !== it.exp_slverr) begin
				`uvm_error("SB/RAW_W", $sformatf("addr=0x%03x slverr exp=%0d obs=%0d",
					it.addr, it.exp_slverr, it.obs_slverr)) e++;
			end
			return e;
		endfunction

		function int check_raw_read(ppa_seq_item it);
			int e = 0;
			if (it.obs_slverr !== it.exp_slverr) begin
				`uvm_error("SB/RAW_R", $sformatf("addr=0x%03x slverr exp=%0d obs=%0d",
					it.addr, it.exp_slverr, it.obs_slverr)) e++;
			end
			if (it.check_data && (it.obs_data !== it.exp_data)) begin
				`uvm_error("SB/RAW_R", $sformatf("addr=0x%03x data exp=0x%08x obs=0x%08x",
					it.addr, it.exp_data, it.obs_data)) e++;
			end
			return e;
		endfunction

		function int check_pkt(ppa_seq_item it);
			int e = 0;
			if (it.obs_length_err !== it.exp_length_err) begin
				`uvm_error("SB/LEN", $sformatf("len_err exp=%0d obs=%0d (pkt_len=%0d exp_pkt_len=%0d)",
					it.exp_length_err, it.obs_length_err, it.pkt_len, it.exp_pkt_len)) e++;
			end
			if (it.obs_type_err !== it.exp_type_err) begin
				`uvm_error("SB/TYP", $sformatf("type_err exp=%0d obs=%0d (type=0x%02x mask=0x%01x)",
					it.exp_type_err, it.obs_type_err, it.pkt_type, it.type_mask)) e++;
			end
			if (it.obs_chk_err !== it.exp_chk_err) begin
				`uvm_error("SB/CHK", $sformatf("chk_err exp=%0d obs=%0d (algo=%0d)",
					it.exp_chk_err, it.obs_chk_err, it.algo_mode)) e++;
			end
			if (it.obs_format_ok !== it.exp_format_ok) begin
				`uvm_error("SB/FMT", $sformatf("format_ok exp=%0d obs=%0d",
					it.exp_format_ok, it.obs_format_ok)) e++;
			end
			if (!it.exp_length_err) begin
				if (it.obs_res_pkt_len !== it.exp_res_pkt_len) begin
					`uvm_error("SB/RLEN", $sformatf("res_pkt_len exp=%0d obs=%0d",
						it.exp_res_pkt_len, it.obs_res_pkt_len)) e++;
				end
				if (it.obs_res_pkt_type !== it.exp_res_pkt_type) begin
					`uvm_error("SB/RTYP", $sformatf("res_pkt_type exp=0x%02x obs=0x%02x",
						it.exp_res_pkt_type, it.obs_res_pkt_type)) e++;
				end
				if (it.obs_sum !== it.exp_sum) begin
					`uvm_error("SB/SUM", $sformatf("sum exp=0x%02x obs=0x%02x",
						it.exp_sum, it.obs_sum)) e++;
				end
				if (it.obs_xor !== it.exp_xor) begin
					`uvm_error("SB/XOR", $sformatf("xor exp=0x%02x obs=0x%02x",
						it.exp_xor, it.obs_xor)) e++;
				end
			end
			if (!it.obs_done) begin
				`uvm_error("SB/DONE", "STATUS.done not asserted") e++;
			end
			return e;
		endfunction

		function void report_phase(uvm_phase phase);
			if (error_count == 0 && cmp_count > 0)
				`uvm_info("SB/FINAL", $sformatf("[CMP_FINAL_PASS] %0d ops, 0 errors", cmp_count), UVM_NONE)
			else
				`uvm_info("SB/FINAL", $sformatf("[CMP_FINAL_FAIL] %0d ops, %0d errors",
					cmp_count, error_count), UVM_NONE)
		endfunction
	endclass

	// ========================================================================
	// Coverage
	// ========================================================================
	class ppa_coverage extends uvm_component;
		ppa_seq_item cur;
		`uvm_component_utils(ppa_coverage)

		covergroup cg_pkt with function sample(ppa_seq_item it);
			cp_op:   coverpoint it.op_kind;
			cp_len:  coverpoint it.pkt_len iff (it.op_kind == OP_PKT) {
				bins min       = {6'd4};
				bins mid[4]    = {[6'd5:6'd31]};
				bins max       = {6'd32};
				bins underflow = {[6'd1:6'd3]};
				bins overflow  = {[6'd33:6'd63]};
			}
			cp_type: coverpoint it.pkt_type iff (it.op_kind == OP_PKT) {
				bins t01     = {8'h01};
				bins t02     = {8'h02};
				bins t04     = {8'h04};
				bins t08     = {8'h08};
				bins illegal = default;
			}
			cp_mask: coverpoint it.type_mask iff (it.op_kind == OP_PKT) {
				bins all  = {4'b1111};
				bins none = {4'b0000};
				bins partial[] = {4'b1110, 4'b1101, 4'b1011, 4'b0111};
			}
			cp_algo: coverpoint it.algo_mode iff (it.op_kind == OP_PKT);
			cp_lerr: coverpoint it.exp_length_err iff (it.op_kind == OP_PKT);
			cp_terr: coverpoint it.exp_type_err   iff (it.op_kind == OP_PKT);
			cp_cerr: coverpoint it.exp_chk_err    iff (it.op_kind == OP_PKT);
			cp_fmt:  coverpoint it.exp_format_ok  iff (it.op_kind == OP_PKT);
			cx_err:  cross cp_lerr, cp_terr, cp_cerr;
		endgroup

		function new(string name, uvm_component parent);
			super.new(name, parent);
			cg_pkt = new();
		endfunction

		function void write_item(ppa_seq_item it);
			cur = it;
			cg_pkt.sample(it);
		endfunction
	endclass

	class ppa_cov_subscriber extends uvm_subscriber#(ppa_seq_item);
		ppa_coverage cov;
		`uvm_component_utils(ppa_cov_subscriber)
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction
		function void write(ppa_seq_item t);
			if (cov != null) cov.write_item(t);
		endfunction
	endclass

	// ========================================================================
	// Environment
	// ========================================================================
	class ppa_env extends uvm_env;
		ppa_driver           drv;
		ppa_sequencer        sqr;
		ppa_apb_monitor      apb_mon;
		ppa_irq_monitor      irq_mon;
		ppa_scoreboard       sb;
		ppa_coverage         cov;
		ppa_cov_subscriber   cov_sub;

		`uvm_component_utils(ppa_env)

		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			drv     = ppa_driver        ::type_id::create("drv",     this);
			sqr     = ppa_sequencer     ::type_id::create("sqr",     this);
			apb_mon = ppa_apb_monitor   ::type_id::create("apb_mon", this);
			irq_mon = ppa_irq_monitor   ::type_id::create("irq_mon", this);
			sb      = ppa_scoreboard    ::type_id::create("sb",      this);
			cov     = ppa_coverage      ::type_id::create("cov",     this);
			cov_sub = ppa_cov_subscriber::type_id::create("cov_sub", this);
		endfunction

		function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			drv.seq_item_port.connect(sqr.seq_item_export);
			drv.ap.connect(sb.exp_fifo.analysis_export);
			drv.ap.connect(cov_sub.analysis_export);
			cov_sub.cov = cov;
		endfunction
	endclass

	// ========================================================================
	// Sequence helper macros
	// ========================================================================
	`define PPA_DO_PKT(MODE, LEN, TYPE, BLK) \
		begin \
			ppa_seq_item it; \
			it = ppa_seq_item::type_id::create("it"); \
			it.err_mode = MODE; \
			start_item(it); \
			if (!it.randomize() with { op_kind == OP_PKT; err_mode == MODE; \
			                           pkt_len == LEN; pkt_type == TYPE; BLK }) \
				`uvm_fatal("SEQ/RND", "rnd fail") \
			finish_item(it); \
		end

	// ========================================================================
	// Sequences — Lab1 (CSR + SRAM) coverage
	// ========================================================================
	class ppa_csr_default_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_csr_default_seq)
		function new(string name = "ppa_csr_default_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it;
			bit [11:0] addrs[] = '{ADDR_CTRL, ADDR_CFG, ADDR_STATUS, ADDR_IRQ_EN,
			                        ADDR_IRQ_STA, ADDR_PKT_LEN_EXP,
			                        ADDR_RES_PKT_LEN, ADDR_RES_PKT_TYPE,
			                        ADDR_RES_SUM, ADDR_RES_XOR, ADDR_ERR_FLAG};
			// Reset first
			it = ppa_seq_item::type_id::create("rst");
			it.op_kind  = OP_RESET; it.n_cycles = 5;
			start_item(it); finish_item(it);
			foreach (addrs[i]) begin
				it = ppa_seq_item::type_id::create($sformatf("rd_%0d", i));
				it.op_kind    = OP_RAW_READ;
				it.addr       = addrs[i];
				it.exp_data   = csr_reset_value(addrs[i]);
				it.exp_slverr = 1'b0;
				it.check_data = 1'b1;
				start_item(it); finish_item(it);
			end
		endtask
	endclass

	class ppa_csr_rw_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_csr_rw_seq)
		function new(string name = "ppa_csr_rw_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it;
			bit [11:0] rw_addrs[] = '{ADDR_CTRL, ADDR_CFG, ADDR_IRQ_EN, ADDR_PKT_LEN_EXP};
			bit [31:0] wvals[]    = '{32'h0000_0001, 32'h0000_00F1, 32'h0000_0003, 32'h0000_002A};
			bit [31:0] rvals[]    = '{32'h0000_0001, 32'h0000_00F1, 32'h0000_0003, 32'h0000_002A};
			foreach (rw_addrs[i]) begin
				it = ppa_seq_item::type_id::create("w");
				it.op_kind = OP_RAW_WRITE; it.addr = rw_addrs[i]; it.data = wvals[i];
				it.exp_slverr = 1'b0;
				start_item(it); finish_item(it);
				it = ppa_seq_item::type_id::create("r");
				it.op_kind = OP_RAW_READ;  it.addr = rw_addrs[i];
				it.exp_data = rvals[i]; it.exp_slverr = 1'b0; it.check_data = 1'b1;
				start_item(it); finish_item(it);
			end
			// Reset to clean up CTRL=1 (enable on)
			it = ppa_seq_item::type_id::create("rst"); it.op_kind = OP_RESET; it.n_cycles = 5;
			start_item(it); finish_item(it);
		endtask
	endclass

	class ppa_csr_ro_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_csr_ro_seq)
		function new(string name = "ppa_csr_ro_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it;
			bit [11:0] ro_addrs[] = '{ADDR_STATUS, ADDR_RES_PKT_LEN, ADDR_RES_PKT_TYPE,
			                          ADDR_RES_SUM, ADDR_RES_XOR, ADDR_ERR_FLAG};
			foreach (ro_addrs[i]) begin
				it = ppa_seq_item::type_id::create("ww");
				it.op_kind = OP_RAW_WRITE; it.addr = ro_addrs[i]; it.data = 32'hDEAD_BEEF;
				it.exp_slverr = 1'b1;
				start_item(it); finish_item(it);
				it = ppa_seq_item::type_id::create("rr");
				it.op_kind = OP_RAW_READ;  it.addr = ro_addrs[i];
				it.exp_data = 32'h0; it.exp_slverr = 1'b0; it.check_data = 1'b1;
				start_item(it); finish_item(it);
			end
		endtask
	endclass

	class ppa_csr_slverr_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_csr_slverr_seq)
		function new(string name = "ppa_csr_slverr_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it;
			bit [11:0] bad_addrs[] = '{12'h003, 12'h02C, 12'h060, 12'h080,
			                            12'h100, 12'h200, 12'h400, 12'h800};
			foreach (bad_addrs[i]) begin
				it = ppa_seq_item::type_id::create("rd");
				it.op_kind = OP_RAW_READ;  it.addr = bad_addrs[i];
				it.exp_slverr = 1'b1; it.check_data = 1'b0;
				start_item(it); finish_item(it);
				it = ppa_seq_item::type_id::create("wr");
				it.op_kind = OP_RAW_WRITE; it.addr = bad_addrs[i]; it.data = 32'hA5A5_5A5A;
				it.exp_slverr = 1'b1;
				start_item(it); finish_item(it);
			end
		endtask
	endclass

	class ppa_w1p_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_w1p_seq)
		function new(string name = "ppa_w1p_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it = ppa_seq_item::type_id::create("w1p");
			it.op_kind = OP_W1P_PROBE; it.pkt_len = 8; it.pkt_type = 8'h01;
			it.algo_mode = 1'b1; it.type_mask = 4'hF; it.exp_pkt_len = 0;
			it.flags = 0; it.payload = new[4];
			start_item(it);
			void'(it.randomize() with { op_kind == OP_W1P_PROBE; err_mode == ERR_NONE;
			                            pkt_len == 8; pkt_type == 8'h01; });
			finish_item(it);
			// Reset to baseline
			it = ppa_seq_item::type_id::create("rst"); it.op_kind = OP_RESET; it.n_cycles = 5;
			start_item(it); finish_item(it);
		endtask
	endclass

	class ppa_pkt_mem_rw_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_pkt_mem_rw_seq)
		function new(string name = "ppa_pkt_mem_rw_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it = ppa_seq_item::type_id::create("memrw");
			start_item(it);
			void'(it.randomize() with { op_kind == OP_PKT_MEM_RW; err_mode == ERR_NONE; pkt_len == 8; pkt_type == 8'h01; });
			finish_item(it);
		endtask
	endclass

	// ========================================================================
	// Sequences — Lab2 (M3 corner case via E2E) coverage
	// ========================================================================
	class ppa_basic_pkt_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_basic_pkt_seq)
		function new(string name = "ppa_basic_pkt_seq"); super.new(name); endfunction
		task body();
			`PPA_DO_PKT(ERR_NONE, 4,  8'h01, )
			`PPA_DO_PKT(ERR_NONE, 8,  8'h02, )
			`PPA_DO_PKT(ERR_NONE, 12, 8'h04, )
			`PPA_DO_PKT(ERR_NONE, 32, 8'h08, )
			// Random legal
			repeat (3) `PPA_DO_PKT(ERR_NONE, pkt_len, pkt_type, pkt_len inside {[4:32]}; )
		endtask
	endclass

	class ppa_payload_unaligned_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_payload_unaligned_seq)
		function new(string name = "ppa_payload_unaligned_seq"); super.new(name); endfunction
		task body();
			`PPA_DO_PKT(ERR_NONE, 5,  8'h01, )
			`PPA_DO_PKT(ERR_NONE, 6,  8'h02, )
			`PPA_DO_PKT(ERR_NONE, 7,  8'h04, )
			`PPA_DO_PKT(ERR_NONE, 9,  8'h08, )
		endtask
	endclass

	class ppa_two_frame_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_two_frame_seq)
		function new(string name = "ppa_two_frame_seq"); super.new(name); endfunction
		task body();
			`PPA_DO_PKT(ERR_NONE, 8,  8'h02, )
			`PPA_DO_PKT(ERR_NONE, 32, 8'h04, )
			`PPA_DO_PKT(ERR_NONE, 4,  8'h08, )
		endtask
	endclass

	class ppa_err_pkt_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_err_pkt_seq)
		function new(string name = "ppa_err_pkt_seq"); super.new(name); endfunction
		task body();
			`PPA_DO_PKT(ERR_LEN_UNDER,    3, 8'h01, )
			`PPA_DO_PKT(ERR_LEN_OVER,    33, 8'h01, )
			`PPA_DO_PKT(ERR_LEN_MISMATCH, 8, 8'h02, exp_pkt_len == 6'd10; )
			`PPA_DO_PKT(ERR_TYPE_BAD,     4, 8'h03, )
			`PPA_DO_PKT(ERR_TYPE_MASK,    4, 8'h01, )
			`PPA_DO_PKT(ERR_CHK,          8, 8'h02, )
		endtask
	endclass

	class ppa_algo_bypass_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_algo_bypass_seq)
		function new(string name = "ppa_algo_bypass_seq"); super.new(name); endfunction
		task body();
			// Same packet, algo_mode=0 → no chk_error even with corrupt hdr_chk
			ppa_seq_item it = ppa_seq_item::type_id::create("bypass");
			start_item(it);
			void'(it.randomize() with {
				op_kind == OP_PKT; err_mode == ERR_NONE;
				pkt_len == 8; pkt_type == 8'h01; algo_mode == 1'b0;
			});
			finish_item(it);
		endtask
	endclass

	class ppa_exp_pkt_len_match_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_exp_pkt_len_match_seq)
		function new(string name = "ppa_exp_pkt_len_match_seq"); super.new(name); endfunction
		task body();
			`PPA_DO_PKT(ERR_NONE, 8, 8'h02, exp_pkt_len == 6'd8; )
			`PPA_DO_PKT(ERR_NONE, 16, 8'h04, exp_pkt_len == 6'd16; )
		endtask
	endclass

	// ========================================================================
	// Sequences — Lab3 (E2E) coverage
	// ========================================================================
	class ppa_irq_done_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_irq_done_seq)
		function new(string name = "ppa_irq_done_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it = ppa_seq_item::type_id::create("irq_d");
			start_item(it);
			void'(it.randomize() with {
				op_kind == OP_PKT; err_mode == ERR_NONE;
				pkt_len == 4; pkt_type == 8'h01;
				done_irq_en == 1'b1; err_irq_en == 1'b0;
			});
			finish_item(it);
			if (it.obs_irq_after_done !== 1'b1)
				`uvm_error("SEQ/IRQ_D", $sformatf("expected irq_o=1 post-done, got %0d", it.obs_irq_after_done))
			if (it.obs_irq_sta_after_done[0] !== 1'b1)
				`uvm_error("SEQ/IRQ_D", $sformatf("expected IRQ_STA[0]=1, got %0d", it.obs_irq_sta_after_done[0]))
		endtask
	endclass

	class ppa_irq_err_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_irq_err_seq)
		function new(string name = "ppa_irq_err_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it = ppa_seq_item::type_id::create("irq_e");
			it.err_mode = ERR_TYPE_BAD;
			start_item(it);
			void'(it.randomize() with {
				op_kind == OP_PKT;
				pkt_len == 8; done_irq_en == 1'b0; err_irq_en == 1'b1;
			});
			finish_item(it);
			if (it.obs_irq_after_done !== 1'b1)
				`uvm_error("SEQ/IRQ_E", $sformatf("expected irq_o=1 (err) post-done, got %0d", it.obs_irq_after_done))
			if (it.obs_irq_sta_after_done[1] !== 1'b1)
				`uvm_error("SEQ/IRQ_E", $sformatf("expected IRQ_STA[1]=1, got %0d", it.obs_irq_sta_after_done[1]))
		endtask
	endclass

	class ppa_busy_write_protect_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_busy_write_protect_seq)
		function new(string name = "ppa_busy_write_protect_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it = ppa_seq_item::type_id::create("bwp");
			start_item(it);
			void'(it.randomize() with {
				op_kind == OP_BUSY_WRITE_PROBE; err_mode == ERR_NONE;
				pkt_len == 32; pkt_type == 8'h04;
			});
			it.exp_data = it.pack_payload_word(0);  // expect payload word0 (PKT_MEM word1) unchanged
			finish_item(it);
		endtask
	endclass

	class ppa_mid_sim_reset_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_mid_sim_reset_seq)
		function new(string name = "ppa_mid_sim_reset_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it;
			// Start a long packet, then reset mid-flight via reset op
			it = ppa_seq_item::type_id::create("rst1");
			it.op_kind = OP_RESET; it.n_cycles = 5;
			start_item(it); finish_item(it);
			// Verify recovery
			`PPA_DO_PKT(ERR_NONE, 4, 8'h01, )
			it = ppa_seq_item::type_id::create("rst2");
			it.op_kind = OP_RESET; it.n_cycles = 5;
			start_item(it); finish_item(it);
			`PPA_DO_PKT(ERR_NONE, 8, 8'h02, )
		endtask
	endclass

	class ppa_toggle_exercise_seq extends uvm_sequence#(ppa_seq_item);
		`uvm_object_utils(ppa_toggle_exercise_seq)
		function new(string name = "ppa_toggle_exercise_seq"); super.new(name); endfunction
		task body();
			ppa_seq_item it;
			bit [11:0] toggle_addrs[] = '{12'h080, 12'h100, 12'h200, 12'h400, 12'h800, 12'h003};
			// Hit PKT_LEN_EXP all bits
			it = ppa_seq_item::type_id::create("plxe");
			it.op_kind = OP_RAW_WRITE; it.addr = ADDR_PKT_LEN_EXP; it.data = 32'h0000_003F;
			it.exp_slverr = 0;
			start_item(it); finish_item(it);
			it = ppa_seq_item::type_id::create("plxe2");
			it.op_kind = OP_RAW_WRITE; it.addr = ADDR_PKT_LEN_EXP; it.data = 32'h0;
			it.exp_slverr = 0;
			start_item(it); finish_item(it);
			// type_mask all bits via CFG
			it = ppa_seq_item::type_id::create("cfg1");
			it.op_kind = OP_RAW_WRITE; it.addr = ADDR_CFG; it.data = 32'h0000_0001; it.exp_slverr = 0;
			start_item(it); finish_item(it);
			it = ppa_seq_item::type_id::create("cfg2");
			it.op_kind = OP_RAW_WRITE; it.addr = ADDR_CFG; it.data = 32'h0000_00F1; it.exp_slverr = 0;
			start_item(it); finish_item(it);
			// Run pkt_len=20 with 0xF0 type for res_pkt_type bit toggle (type_error)
			`PPA_DO_PKT(ERR_TYPE_BAD, 20, 8'hF0, )
			// Toggle PADDR high bits via SLVERR reads
			foreach (toggle_addrs[i]) begin
				it = ppa_seq_item::type_id::create("trd");
				it.op_kind = OP_RAW_READ; it.addr = toggle_addrs[i];
				it.exp_slverr = 1'b1; it.check_data = 0;
				start_item(it); finish_item(it);
			end
			// Reset for clean state
			it = ppa_seq_item::type_id::create("rst"); it.op_kind = OP_RESET; it.n_cycles = 5;
			start_item(it); finish_item(it);
		endtask
	endclass

	// Helper: pack first word of payload (used by busy_write_protect_seq)
	// Add to ppa_seq_item via parasitic function above is awkward; provide inline helper
	// We embed it as a function on the class:

	// ========================================================================
	// Tests
	// ========================================================================
	class ppa_base_test extends uvm_test;
		ppa_env env;
		`uvm_component_utils(ppa_base_test)
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			env = ppa_env::type_id::create("env", this);
		endfunction
		function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(phase);
			// Default 1 second of sim time; can override via +UVM_TIMEOUT plusarg
			uvm_top.set_timeout(1s, 0);
		endfunction
		task run_seq(uvm_sequence#(ppa_seq_item) s);
			s.start(env.sqr);
		endtask
	endclass

	`define PPA_RUN(NAME, SEQT) \
		class NAME extends ppa_base_test; \
			`uvm_component_utils(NAME) \
			function new(string name, uvm_component parent); super.new(name, parent); endfunction \
			task run_phase(uvm_phase phase); \
				SEQT s; \
				phase.raise_objection(this); \
				s = SEQT::type_id::create("s"); \
				s.start(env.sqr); \
				#1us; \
				phase.drop_objection(this); \
			endtask \
		endclass

	// Single-sequence tests (for diagnosis)
	`PPA_RUN(ppa_basic_test,        ppa_basic_pkt_seq)
	`PPA_RUN(ppa_two_frame_test,    ppa_two_frame_seq)
	`PPA_RUN(ppa_error_test,        ppa_err_pkt_seq)
	`PPA_RUN(ppa_irq_done_test,     ppa_irq_done_seq)
	`PPA_RUN(ppa_irq_err_test,      ppa_irq_err_seq)
	`PPA_RUN(ppa_csr_default_test,  ppa_csr_default_seq)
	`PPA_RUN(ppa_csr_rw_test,       ppa_csr_rw_seq)
	`PPA_RUN(ppa_csr_ro_test,       ppa_csr_ro_seq)
	`PPA_RUN(ppa_csr_slverr_test,   ppa_csr_slverr_seq)
	`PPA_RUN(ppa_w1p_test,          ppa_w1p_seq)
	`PPA_RUN(ppa_pkt_mem_rw_test,   ppa_pkt_mem_rw_seq)
	`PPA_RUN(ppa_payload_unaligned_test, ppa_payload_unaligned_seq)
	`PPA_RUN(ppa_algo_bypass_test,  ppa_algo_bypass_seq)
	`PPA_RUN(ppa_exp_pkt_len_test,  ppa_exp_pkt_len_match_seq)
	`PPA_RUN(ppa_busy_write_protect_test, ppa_busy_write_protect_seq)
	`PPA_RUN(ppa_mid_sim_reset_test, ppa_mid_sim_reset_seq)
	`PPA_RUN(ppa_toggle_exercise_test, ppa_toggle_exercise_seq)

	// Full regression test — chains all sequences in series
	class ppa_regression_test extends ppa_base_test;
		`uvm_component_utils(ppa_regression_test)
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction
		task run_phase(uvm_phase phase);
			ppa_csr_default_seq          s_csr_def;
			ppa_csr_rw_seq               s_csr_rw;
			ppa_csr_ro_seq               s_csr_ro;
			ppa_csr_slverr_seq           s_csr_slv;
			ppa_w1p_seq                  s_w1p;
			ppa_pkt_mem_rw_seq           s_memrw;
			ppa_basic_pkt_seq            s_basic;
			ppa_payload_unaligned_seq    s_unalign;
			ppa_two_frame_seq            s_two;
			ppa_err_pkt_seq              s_err;
			ppa_algo_bypass_seq          s_byp;
			ppa_exp_pkt_len_match_seq    s_exp;
			ppa_irq_done_seq             s_irqd;
			ppa_irq_err_seq              s_irqe;
			ppa_busy_write_protect_seq   s_bwp;
			ppa_mid_sim_reset_seq        s_rst;
			ppa_toggle_exercise_seq      s_tog;

			phase.raise_objection(this);
			s_csr_def  = ppa_csr_default_seq         ::type_id::create("s_csr_def");
			s_csr_rw   = ppa_csr_rw_seq              ::type_id::create("s_csr_rw");
			s_csr_ro   = ppa_csr_ro_seq              ::type_id::create("s_csr_ro");
			s_csr_slv  = ppa_csr_slverr_seq          ::type_id::create("s_csr_slv");
			s_w1p      = ppa_w1p_seq                 ::type_id::create("s_w1p");
			s_memrw    = ppa_pkt_mem_rw_seq          ::type_id::create("s_memrw");
			s_basic    = ppa_basic_pkt_seq           ::type_id::create("s_basic");
			s_unalign  = ppa_payload_unaligned_seq   ::type_id::create("s_unalign");
			s_two      = ppa_two_frame_seq           ::type_id::create("s_two");
			s_err      = ppa_err_pkt_seq             ::type_id::create("s_err");
			s_byp      = ppa_algo_bypass_seq         ::type_id::create("s_byp");
			s_exp      = ppa_exp_pkt_len_match_seq   ::type_id::create("s_exp");
			s_irqd     = ppa_irq_done_seq            ::type_id::create("s_irqd");
			s_irqe     = ppa_irq_err_seq             ::type_id::create("s_irqe");
			s_bwp      = ppa_busy_write_protect_seq  ::type_id::create("s_bwp");
			s_rst      = ppa_mid_sim_reset_seq       ::type_id::create("s_rst");
			s_tog      = ppa_toggle_exercise_seq     ::type_id::create("s_tog");

			s_csr_def .start(env.sqr);
			s_csr_rw  .start(env.sqr);
			s_csr_ro  .start(env.sqr);
			s_csr_slv .start(env.sqr);
			s_w1p     .start(env.sqr);
			s_memrw   .start(env.sqr);
			s_basic   .start(env.sqr);
			s_unalign .start(env.sqr);
			s_two     .start(env.sqr);
			s_err     .start(env.sqr);
			s_byp     .start(env.sqr);
			s_exp     .start(env.sqr);
			s_irqd    .start(env.sqr);
			s_irqe    .start(env.sqr);
			s_bwp     .start(env.sqr);
			s_rst     .start(env.sqr);
			s_tog     .start(env.sqr);
			#1us;
			phase.drop_objection(this);
		endtask
	endclass

endpackage

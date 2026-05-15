// ============================================================================
// File: ppa_ref_model.sv
// Description: PPA-Lite reference model — pure spec-derived predictors.
//              Independent of RTL; cited sections: Spec §3 (packet format),
//              §5.2 (CSR map/attributes), §6 (PKT_MEM window), §7 (FSM/process),
//              §9 (errors), §4 (APB protocol).
// ============================================================================

package ppa_ref_model;

	// ------------------------------------------------------------------------
	// Spec §5.2 — CSR address map
	// ------------------------------------------------------------------------
	localparam logic [11:0] ADDR_CTRL         = 12'h000;
	localparam logic [11:0] ADDR_CFG          = 12'h004;
	localparam logic [11:0] ADDR_STATUS       = 12'h008;
	localparam logic [11:0] ADDR_IRQ_EN       = 12'h00C;
	localparam logic [11:0] ADDR_IRQ_STA      = 12'h010;
	localparam logic [11:0] ADDR_PKT_LEN_EXP  = 12'h014;
	localparam logic [11:0] ADDR_RES_PKT_LEN  = 12'h018;
	localparam logic [11:0] ADDR_RES_PKT_TYPE = 12'h01C;
	localparam logic [11:0] ADDR_RES_SUM      = 12'h020;
	localparam logic [11:0] ADDR_RES_XOR      = 12'h024;
	localparam logic [11:0] ADDR_ERR_FLAG     = 12'h028;
	localparam logic [11:0] ADDR_PKT_MEM_LO   = 12'h040;
	localparam logic [11:0] ADDR_PKT_MEM_HI   = 12'h05C;

	typedef enum {
		ATTR_RW,
		ATTR_RO,
		ATTR_W1P,
		ATTR_W1C,
		ATTR_RW_MEM,
		ATTR_RESERVED
	} csr_attr_e;

	// Spec §5.2 — reset values
	function automatic logic [31:0] csr_reset_value(input logic [11:0] addr);
		case (addr)
			ADDR_CTRL:         return 32'h0000_0000;
			ADDR_CFG:          return 32'h0000_00F1;  // algo_mode=1, type_mask=4'hF
			ADDR_STATUS:       return 32'h0000_0000;
			ADDR_IRQ_EN:       return 32'h0000_0000;
			ADDR_IRQ_STA:      return 32'h0000_0000;
			ADDR_PKT_LEN_EXP:  return 32'h0000_0000;
			ADDR_RES_PKT_LEN:  return 32'h0000_0000;
			ADDR_RES_PKT_TYPE: return 32'h0000_0000;
			ADDR_RES_SUM:      return 32'h0000_0000;
			ADDR_RES_XOR:      return 32'h0000_0000;
			ADDR_ERR_FLAG:     return 32'h0000_0000;
			default:           return 32'h0000_0000;
		endcase
	endfunction

	function automatic csr_attr_e csr_attr(input logic [11:0] addr);
		case (addr)
			ADDR_CTRL:         return ATTR_RW;       // W1P inside, but reg readable as RW
			ADDR_CFG:          return ATTR_RW;
			ADDR_STATUS:       return ATTR_RO;
			ADDR_IRQ_EN:       return ATTR_RW;
			ADDR_IRQ_STA:      return ATTR_W1C;
			ADDR_PKT_LEN_EXP:  return ATTR_RW;
			ADDR_RES_PKT_LEN:  return ATTR_RO;
			ADDR_RES_PKT_TYPE: return ATTR_RO;
			ADDR_RES_SUM:      return ATTR_RO;
			ADDR_RES_XOR:      return ATTR_RO;
			ADDR_ERR_FLAG:     return ATTR_RO;
			default: begin
				if (addr inside {[ADDR_PKT_MEM_LO:ADDR_PKT_MEM_HI]} && (addr[1:0] == 2'b00))
					return ATTR_RW_MEM;
				else
					return ATTR_RESERVED;
			end
		endcase
	endfunction

	// Spec §4.2 — invalid address triggers PSLVERR (reserved or unaligned)
	function automatic bit is_valid_csr_addr(input logic [11:0] addr);
		csr_attr_e a;
		if (addr[1:0] != 2'b00) return 1'b0;          // unaligned
		a = csr_attr(addr);
		return (a != ATTR_RESERVED);
	endfunction

	function automatic bit is_ro_csr_addr(input logic [11:0] addr);
		csr_attr_e a = csr_attr(addr);
		return (a == ATTR_RO);
	endfunction

	function automatic bit is_pkt_mem_addr(input logic [11:0] addr);
		return (addr inside {[ADDR_PKT_MEM_LO:ADDR_PKT_MEM_HI]} && (addr[1:0] == 2'b00));
	endfunction

	// ------------------------------------------------------------------------
	// Spec §3 — packet format predictors
	// ------------------------------------------------------------------------
	function automatic logic [7:0] compute_hdr_chk(input logic [7:0] len, type_, flags);
		return len ^ type_ ^ flags;
	endfunction

	function automatic logic [7:0] compute_sum(input byte payload[]);
		logic [7:0] s = 8'h0;
		foreach (payload[i]) s = s + payload[i];
		return s;
	endfunction

	function automatic logic [7:0] compute_xor(input byte payload[]);
		logic [7:0] x = 8'h0;
		foreach (payload[i]) x = x ^ payload[i];
		return x;
	endfunction

	// ------------------------------------------------------------------------
	// Spec §9 — error predictors
	// ------------------------------------------------------------------------
	function automatic bit predict_length_error(input logic [5:0] pkt_len, exp_pkt_len);
		bit underflow = (pkt_len < 6'd4);
		bit overflow  = (pkt_len > 6'd32);
		bit mismatch  = (exp_pkt_len != 6'd0) && (pkt_len != exp_pkt_len);
		return underflow | overflow | mismatch;
	endfunction

	function automatic bit predict_type_error(input logic [7:0] pkt_type, input logic [3:0] type_mask);
		bit one_hot_ok = (pkt_type inside {8'h01, 8'h02, 8'h04, 8'h08});
		bit mask_ok;
		case (pkt_type)
			8'h01: mask_ok = type_mask[0];
			8'h02: mask_ok = type_mask[1];
			8'h04: mask_ok = type_mask[2];
			8'h08: mask_ok = type_mask[3];
			default: mask_ok = 1'b0;
		endcase
		return !(one_hot_ok && mask_ok);
	endfunction

	function automatic bit predict_chk_error(input bit algo_mode,
	                                         input logic [7:0] hdr_chk_field, true_chk);
		return algo_mode && (hdr_chk_field !== true_chk);
	endfunction

	function automatic bit predict_format_ok(input bit length_err, type_err, chk_err);
		return !length_err && !type_err && !chk_err;
	endfunction

	// Spec §7 — DONE state STATUS encoding
	function automatic logic [3:0] predict_status_done(input bit format_ok, input bit any_error);
		// [3]=format_ok, [2]=error, [1]=done, [0]=busy
		return {format_ok, any_error, 1'b1, 1'b0};
	endfunction

endpackage

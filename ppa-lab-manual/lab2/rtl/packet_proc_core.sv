// ---------------------------------------------------------------------------
// packet_proc_core  (M3)
// ---------------------------------------------------------------------------
// Spec reference: doc/ppa-lite-spec.md §2.3 (M3 ports) + §6 (FSM)
// Design note:    doc/design-note.md §2, §5, §6
// 学生手写：FSM 三态 + 字计数器 + 包头提取 + 长度/类型/校验判断
// Copilot 补齐：case 分支模板、累加/异或逻辑、默认值
// ---------------------------------------------------------------------------

module packet_proc_core (
    input  logic        clk,
    input  logic        rst_n,

    // 控制
    input  logic        start_i,
    input  logic        algo_mode_i,
    input  logic [3:0]  type_mask_i,
    input  logic [5:0]  exp_pkt_len_i,

    // SRAM 读端口（送 M2）
    output logic        mem_rd_en_o,
    output logic [2:0]  mem_rd_addr_o,
    input  logic [31:0] mem_rd_data_i,

    // 状态
    output logic        busy_o,
    output logic        done_o,

    // 结果
    output logic [5:0]  res_pkt_len_o,
    output logic [7:0]  res_pkt_type_o,
    output logic [7:0]  res_payload_sum_o,
    output logic [7:0]  res_payload_xor_o,

    // 错误
    output logic        format_ok_o,
    output logic        length_error_o,
    output logic        type_error_o,
    output logic        chk_error_o
);

    // -----------------------------------------------------------------------
    // FSM (spec §6)
    // -----------------------------------------------------------------------
    typedef enum logic [1:0] {S_IDLE, S_PROCESS, S_DONE} state_t;
    state_t state, state_n;

    // TODO(student): 字计数器 / 包头寄存器 / sum / xor / error flag
    // TODO(student): 状态转移 + 输出逻辑
    // TODO(student): pkt_len 范围检查 [4, 32]
    // TODO(student): pkt_type one-hot + type_mask 过滤
    // TODO(student): algo_mode_i==1 时 hdr_chk 校验

    assign busy_o            = (state == S_PROCESS);
    assign done_o            = (state == S_DONE);
    assign mem_rd_en_o       = 1'b0;  // TODO(student)
    assign mem_rd_addr_o     = 3'b0;  // TODO(student)
    assign res_pkt_len_o     = 6'b0;  // TODO(student)
    assign res_pkt_type_o    = 8'b0;  // TODO(student)
    assign res_payload_sum_o = 8'b0;  // TODO(student)
    assign res_payload_xor_o = 8'b0;  // TODO(student)
    assign format_ok_o       = 1'b0;  // TODO(student)
    assign length_error_o    = 1'b0;  // TODO(student)
    assign type_error_o      = 1'b0;  // TODO(student)
    assign chk_error_o       = 1'b0;  // TODO(student)

endmodule

// ---------------------------------------------------------------------------
// packet_ref_model — packet 解析参考模型
// 警告：本文件必须独立实现，绝不引用 DUT 内部信号
// （否则触发 review-tb skill 的 P0：ref model 同源）
// ---------------------------------------------------------------------------
package packet_ref_model_pkg;
    import ppa_packet_pkg::*;

    typedef struct {
        logic [5:0] res_pkt_len;
        logic [7:0] res_pkt_type;
        logic [7:0] res_payload_sum;
        logic [7:0] res_payload_xor;
        logic       format_ok;
        logic       length_error;
        logic       type_error;
        logic       chk_error;
    } pkt_result_t;

    // TODO(student): function pkt_result_t predict(input byte unsigned pkt[$], input logic algo_mode, input logic [3:0] type_mask);

endpackage : packet_ref_model_pkg

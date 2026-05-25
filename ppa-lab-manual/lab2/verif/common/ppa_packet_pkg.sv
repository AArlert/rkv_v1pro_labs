// ---------------------------------------------------------------------------
// ppa_packet_pkg — packet 结构 typedef / 字段提取宏
// Spec reference: doc/ppa-lite-spec.md §3 (packet format)
// 跨 lab 复用
// ---------------------------------------------------------------------------
package ppa_packet_pkg;

    // 包头（spec §3.1）
    typedef struct packed {
        logic [7:0] hdr_chk;
        logic [7:0] flags;
        logic [7:0] pkt_type;
        logic [7:0] pkt_len;
    } pkt_hdr_t;

    // TODO(student): 可补 helper function：legal_pkt_type, legal_pkt_len, calc_hdr_chk

endpackage : ppa_packet_pkg

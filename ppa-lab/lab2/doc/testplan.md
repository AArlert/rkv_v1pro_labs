# Lab2 测试计划 (Test Plan)

> 由 Verification Plan Agent 在验证阶段填充。设计阶段仅提供最小可验证 TB（见 `svtb/tb/ppa_tb.sv`）覆盖必做项 1/2/3。

## 设计阶段最小 TB 覆盖

| TC ID | 名称 | 关联 Feature |
|-------|------|--------------|
| TC1 | tc_min_legal_pkt（pkt_len=4） | F2-01 / F2-04 / F2-05 |
| TC2 | tc_8byte_legal（含 4B payload） | F2-01 / F2-04 / F2-09 / F2-10 |
| TC3 | tc_length_underflow（pkt_len=3） | F2-05 / F2-13 |
| TC4 | tc_length_overflow（pkt_len=33） | F2-05 / F2-13 |
| TC5 | tc_busy_done_timing | F2-02 / F2-03 / F2-12 |
| TC6 | tc_two_frames | F2-12 |

## VPlan 阶段补充 TC

| TC ID | 名称 | 关联 Feature | 验证意图 |
|-------|------|--------------|----------|
| TC7 | tc_type_not_one_hot（pkt_type=0x03） | F2-06 | 非 one-hot 类型触发 type_error |
| TC8 | tc_type_mask_filter（type_mask 屏蔽合法类型） | F2-06 | type_mask bit=0 时合法 one-hot 类型仍报错 |
| TC9 | tc_hdr_chk_error（hdr_chk 错误，algo_mode=1） | F2-07 | 校验和不匹配触发 chk_error |
| TC10 | tc_algo_mode_bypass（algo_mode=0 旁路） | F2-08 | algo_mode=0 时即使 hdr_chk 错误也不报 chk_error |
| TC11 | tc_multi_error（三类错误并行成立） | F2-11 | length+type+chk 三路同时触发 |
| TC12 | tc_exp_pkt_len_mismatch（exp≠actual） | F2-14 | exp_pkt_len_i 非零且与 pkt_len 不匹配触发 length_error |
| TC13 | tc_exp_pkt_len_match（exp=actual，正向确认） | F2-14 | exp_pkt_len_i 非零且匹配时无 length_error |
| TC14 | tc_payload_unaligned（pkt_len=5 非对齐尾 word） | F2-09 / F2-10 | 仅有效字节参与 sum/XOR，尾部填充字节不累加 |

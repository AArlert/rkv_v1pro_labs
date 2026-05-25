# lab2 testplan

| TC ID | 文件 | 目的 | spec 引用 | 必做/选做 | 状态 |
|---|---|---|---|---|---|
| TC-L2-01 | `verif/tests/smoke_legal_test.sv` | 8B 合法包，验证 IDLE→PROCESS→DONE + res_* 正确 | §10.1 N-1/N-2 + §11.3 必做1 | 必做 | ⬜ |
| TC-L2-02 | `verif/tests/length_overflow_test.sv` | pkt_len=3 / pkt_len=33 → length_error=1，FSM 不卡死 | §10.2 E-1/E-2 + §11.3 必做2 | 必做 | ⬜ |
| TC-L2-03 | `verif/tests/busy_done_timing_test.sv` | start 后 1 拍 busy=1；DONE 保持；再 start 后 done=0 | §10.3 B-1 + §11.3 必做3 | 必做 | ⬜ |
| TC-L2-04 | `verif/tests/type_mask_test.sv`（选做） | 非法 pkt_type / type_mask 屏蔽 | §10.2 E-3/E-4 | 选做 | ⬜ |
| TC-L2-05 | `verif/tests/algo_mode_test.sv`（选做） | algo_mode=1 hdr_chk 校验；algo_mode=0 旁路 | §10.2 E-5/E-6 + §11.3 选做5 | 选做 | ⬜ |

## check-point

- CK-1: format_ok 仅在 length / type / chk 全通过时为 1
- CK-2: res_pkt_len/type 与输入包头一致
- CK-3: payload_sum = sum(payload bytes) (8-bit 截断)
- CK-4: payload_xor = XOR(payload bytes)
- CK-5: FSM 状态对应 busy/done 信号严格匹配

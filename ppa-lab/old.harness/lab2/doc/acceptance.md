# Lab2 验收标准 (Acceptance Criteria)

> 每条验收标准配有可执行判据，供 Sign-off 时逐项检查

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 1 | 合法包完整处理 | `make run` PASS 且 log 中 `tc_normal_min_pkt PASS`；res_pkt_len_o/res_pkt_type_o 与写入一致；FSM 经过 IDLE→PROCESS→DONE | PENDING |
| 2 | 长度越界检测 | `make run` PASS 且 log 中 `tc_len_underflow PASS` + `tc_len_overflow PASS`；length_error_o=1 且 done_o 正常拉高（M3 不卡死） | PENDING |
| 3 | busy/done 时序 | `make run` PASS 且 log 中 `tc_busy_done_timing PASS`；start_i 后第 1 拍 busy_o=1；DONE 态 done_o 持续保持；再次 start 后 done_o 清零 | PENDING |

## 选做验收项

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 4 | pkt_type 合法性 + type_mask 过滤 | `make run` PASS 且 log 中 `tc_type_error PASS` + `tc_type_mask PASS`；非 one-hot type_error_o=1；type_mask 屏蔽时 type_error_o=1 | PENDING |
| 5 | hdr_chk 校验 + algo_mode 旁路 + payload sum/XOR | `make run` PASS 且 log 中 `tc_chk_error PASS` + `tc_algo_bypass PASS` + `tc_payload_calc PASS`；algo_mode=1 时校验错误 chk_error_o=1；algo_mode=0 时 chk_error_o=0；payload sum/XOR 结果正确 | PENDING |

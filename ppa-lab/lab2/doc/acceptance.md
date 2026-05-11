# Lab2 验收标准 (Acceptance Criteria)

> 每条验收标准配有可执行判据，供 Sign-off 时逐项检查

## 必做项

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 1 | 合法包完整处理（FSM IDLE→PROCESS→DONE，res_pkt_len/type 正确） | `make run` 后 log 含 `TC1 ... PASS` 与 `TC2 ... PASS`；`res_pkt_len_o` 与 `res_pkt_type_o` 与写入一致 | **PASS** |
| 2 | 长度越界检测（pkt_len=3 下溢 / pkt_len=33 上溢，length_error=1 且不卡死） | `make run` 后 log 含 `TC3 ... PASS` 与 `TC4 ... PASS`；两种情形均见 `done_o=1` 且 `length_error_o=1` | **PASS** |
| 3 | busy/done 时序（start 后 busy=1；DONE 态 done 保持；新 start 后 done 清零） | `make run` 后 log 含 `TC5 busy=1 after start PASS`、`TC5 done held PASS`、`TC6 done cleared after new start PASS` | **PASS** |

## 选做项

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 4 | pkt_type 合法性 + type_mask 过滤 | TB 扩展用例（pkt_type=0x03 / type_mask 屏蔽）下 `type_error_o=1`，由 VPlan Agent 补充 | **PASS**（TC7 非 one-hot / TC8 mask 过滤） |
| 5 | algo_mode 旁路 + payload sum/XOR 正确性 | TB 扩展用例（algo_mode=0 旁路 chk；最大包 sum/XOR 全字节）由 VPlan Agent 补充 | **PASS**（TC10 旁路 / TC13-TC14 sum+XOR） |

## 设计阶段自检（DUT Agent 已完成）

| 项 | 结果 |
|----|------|
| `make comp` | 0 error, 0 warning（QuestaSim 2021.1） |
| `make run` 最小 TB | 33/33 checks PASS, 0 FAIL |
| FSM 三态识别 | vopt 报告 "Recognized 1 FSM in module ppa_packet_proc_core" |

## 验收环境

| 项目 | 值 |
|------|-----|
| 编译命令 | `make comp`（lab2/svtb/sim） |
| 运行命令 | `make run` |
| 工具版本 | QuestaSim-64 2021.1 |

# Lab2 测试计划

## 1 测试范围
M3 ppa_packet_proc_core 独立验证，使用 SV 数组行为模型替代 M2 SRAM

## 2 测试用例矩阵

### 2.1 必做测试

| 编号 | 测试名 | 输入摘要 | 预期输出 | 覆盖目标 | 优先级 |
|------|--------|---------|---------|---------|--------|
| TC1 | 合法包完整处理 | pkt_len=8, pkt_type=0x01, flags=0x00, hdr_chk=0x09, payload=4B | done_o=1, format_ok_o=1, res_pkt_len_o=8, res_pkt_type_o=0x01, length_error_o=0, type_error_o=0, chk_error_o=0 | 必做1：合法包处理 | P0 |
| TC2a | 长度下溢 | pkt_len=3 | done_o=1, length_error_o=1, format_ok_o=0 | 必做2：长度越界检测 | P0 |
| TC2b | 长度上溢 | pkt_len=33 | done_o=1, length_error_o=1, format_ok_o=0 | 必做2：长度越界检测 | P0 |
| TC3 | busy/done 时序 | 连续两帧处理 | 第1帧：start后busy_o=1→done_o=1；第2帧start后done_o清零→busy_o=1→done_o=1 | 必做3：busy/done时序 | P0 |

### 2.2 选做测试

| 编号 | 测试名 | 输入摘要 | 预期输出 | 覆盖目标 | 优先级 |
|------|--------|---------|---------|---------|--------|
| TC4a | 非法 pkt_type | pkt_type=0x03（非 one-hot） | type_error_o=1 | 选做4：type合法性 | P1 |
| TC4b | type_mask 屏蔽 | type_mask=4'b1110, pkt_type=0x01 | type_error_o=1 | 选做4：type_mask过滤 | P1 |
| TC5a | hdr_chk 错误 | hdr_chk 与 B0^B1^B2 不符, algo_mode=1 | chk_error_o=1 | 选做5：hdr_chk校验 | P1 |
| TC5b | algo_mode=0 旁路 | 同 TC5a 的包，algo_mode=0 | chk_error_o=0 | 选做5：algo_mode旁路 | P1 |
| TC5c | payload sum/XOR | pkt_len=8, payload=0x01,0x02,0x03,0x04 | res_payload_sum=0x0A, res_payload_xor=0x04 | 选做5：payload计算 | P1 |

## 3 检查点矩阵

| 检查点 | 关联用例 | 检查方法 |
|--------|---------|---------|
| FSM IDLE→PROCESS→DONE 转移 | TC1, TC3 | 波形观察 + 状态信号比对 |
| busy_o 在 start 后第1拍置1 | TC3 | 自动比对 |
| done_o 在 DONE 态持续保持 | TC1, TC3 | 自动比对 |
| done_o 在再次 start 后清零 | TC3 | 自动比对 |
| res_pkt_len_o 正确 | TC1 | 自动比对 |
| res_pkt_type_o 正确 | TC1 | 自动比对 |
| length_error_o 下溢检测 | TC2a | 自动比对 |
| length_error_o 上溢检测 | TC2b | 自动比对 |
| type_error_o 非法类型 | TC4a | 自动比对 |
| type_error_o mask屏蔽 | TC4b | 自动比对 |
| chk_error_o 校验失败 | TC5a | 自动比对 |
| chk_error_o algo旁路 | TC5b | 自动比对 |
| res_payload_sum 正确 | TC5c | 自动比对 |
| res_payload_xor 正确 | TC5c | 自动比对 |
| format_ok_o 合法包 | TC1 | 自动比对 |
| format_ok_o 非法包 | TC2a, TC2b | 自动比对 |

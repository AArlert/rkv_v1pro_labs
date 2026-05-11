# Lab2 验收标准 (Acceptance Criteria)

> 每条验收标准配有可执行判据，供 Sign-off 时逐项检查

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 1 | 合法包处理结果正确 | `make run` PASS 且 TC1 输出 done_o=1, format_ok_o=1, res_pkt_len_o/res_pkt_type_o 匹配 | ✅ PASS |
| 2 | 长度越界检测正常 | `make run` PASS 且 TC2a(下溢)/TC2b(上溢) length_error_o=1 | ✅ PASS |
| 3 | busy/done 时序正确 | `make run` PASS 且 TC3 连续两帧 busy/done 转换正确 | ✅ PASS |
| 4 | 类型合法性检查正常 | `make run` PASS 且 TC4a(非法type)/TC4b(mask屏蔽) type_error_o=1 | ✅ PASS |
| 5 | 头校验功能正常 | `make run` PASS 且 TC5a chk_error_o=1, TC5b algo旁路 chk_error_o=0 | ✅ PASS |

## Sign-off 记录

- **审查通过时间**：2026-04-28
- **审查项数**：78 项全 PASS
- **遗留项**：5 项 LOW-MEDIUM 限制（详见 risk-register.md）
- **结论**：Lab2 验收通过，可进入 Lab3 集成阶段

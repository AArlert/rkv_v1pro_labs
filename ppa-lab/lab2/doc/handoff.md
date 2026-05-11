# Lab2 交接笔记 (Handoff Notes)

---

## Handoff: DUT Agent → Review Agent (2026-05-11, Lab2)

### 我做了什么（≤5 条）
1. 实现 `ppa_packet_proc_core.sv`（M3）：3 态 FSM + 包头解析 + 长度/类型/头校验 + payload sum/XOR
2. 关键时序决策：`mem_rd_en_o / mem_rd_addr_o` 采用组合输出，配合 M2 同步 SRAM 实现单拍流水读
3. 搭建独立 SV TB（行为级 SRAM 模型，不依赖 Lab1），6 个 TC / 33 checks 全 PASS
4. `make comp` 0 error 0 warning；`make run` 全 PASS
5. 写齐 `design-prompt.md` / `acceptance.md` / `testplan.md` / `log.md` 设计阶段段落

### 我没做什么 / 留给下一步的（≤5 条）
1. F2-06 / F2-07 / F2-08 / F2-11 / F2-14 等场景的定向 TC 留待 VPlan 阶段补充
2. 选做项 4（type_mask 过滤）/ 5（algo_mode + 最大包 sum/XOR）未在最小 TB 覆盖
3. 未做波形级审查；`make rung` GUI 可现场查看 FSM 状态机
4. 组合 rd_en/addr 在集成时序下的余量须 Lab3 阶段确认（log L2-O-2）
5. PKT_LEN_EXP "已配置"语义按"非零"实现，已记入 risk-register 待 Review 复核

### 踩过的坑 / 要小心的（≤3 条）
1. **同步 SRAM 双拍延迟陷阱**：若 M3 输出寄存器化 rd_en/addr，DUT→SRAM→DUT 往返为 2 拍，不是 1 拍。本设计采用组合输出规避此问题
2. **issue_idx 与 consume_idx 相差 1 拍**：consume_idx 指向"本拍 mem_rd_data_i 对应的 word 索引"，与 issue_idx（下一拍要发起的索引）的差等于 SRAM 读延迟
3. **header 同拍直接 DONE 路径**（单 word 包 / 长度越界）：`format_ok` 在该路径下使用组合错误信号 `hdr_*_err`，多 word 路径下使用已锁存的 `*_error_o` —— 二者不能混用

### 验证成果的最小命令
```
cd ppa-lab/lab2/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** Review Agent 逐项审查 F2-01~F2-14 与 spec §3/§7/§9 的一致性，重点检查 D1（组合输出）与 D5（PKT_LEN_EXP 语义）
2. **[P0]** 通过后进入 VPlan 阶段，补全 F2-06~F2-11 和 F2-14 定向 TC
3. **[P1]** Lab3 集成阶段验证组合 rd_en/addr 的端到端时序

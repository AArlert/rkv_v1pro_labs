# Lab2 交接笔记 (Handoff Notes)

---

## Handoff: DUT Agent → Integration Agent (2026-04-28, Lab2)

### 我做了什么
1. 实现 `ppa_packet_proc_core.sv`（M3）：三态 FSM + 包处理算法核心
2. 搭建 M3 独立 TB：用 SV 数组行为模型替代 M2，覆盖 TC1~TC5c
3. 完成审查：78 项全 PASS，与 spec 完全一致
4. 编写 testplan.md：必做 4 条 + 选做 5 条测试用例
5. 编写 Makefile：comp/run/rung/clean 目标可用

### 我没做什么 / 留给下一步的
1. 端到端验证（M1→M2→M3 完整链路需 Lab3）
2. pkt_len=32 最大合法包的覆盖（L-2）
3. exp_pkt_len_i 非零时长度一致性覆盖（L-3）
4. 字节序假设的集成验证（R-1）
5. UVM 验证环境（Lab3 引入）

### 踩过的坑 / 要小心的
1. SRAM 同步读有 1 拍延迟，设计用流水线处理避免空等
2. 越界包（pkt_len<4 或 >32）设 eff_total_words=1，仅读 Word0 就进 DONE
3. 1-word 包（pkt_len=4）多一拍 hdr_valid 延迟，不影响功能但影响周期数

### 验证成果的最小命令
```
cd ppa-lab/lab2/svtb/sim
make comp
make run
```

### 推荐下一步动作
1. **[P0]** 创建 `ppa_top.sv`，薄层连线集成 M1+M2+M3
2. **[P0]** 在 Lab3 编写端到端测试序列（APB 写包→start→等 done→读结果）
3. **[P1]** 验证字节序假设（R-1）和连续两帧处理

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

---

## Handoff: Review Agent → VPlan Agent (2026-05-11, Lab2)

### 我做了什么（≤5 条）
1. 逐项审查 F2-01~F2-14 与 spec §2.3/§3/§7/§9 的一致性，全部 PASS
2. 复核 L2-O-3（组合 header 解码跨周期假设），确认安全
3. 验证 A-2 假设（PKT_LEN_EXP "非零即已配置"）合理性
4. 确认 type_mask 语义：bit[n]=1 允许 pkt_type=(1<<n)，与 spec §5.2 一致
5. 审查结果记入 `lab2/doc/log.md` §2

### 我没做什么 / 留给下一步的（≤5 条）
1. F2-06~F2-11、F2-14 的定向 TC 仍为 #TODO，需 VPlan Agent 补充
2. 选做项 4/5（type_mask 过滤 / algo_mode 旁路 + max payload）TB 待补
3. 未修改任何 RTL 或 TB 代码（审查无阻塞项，无需回退）
4. acceptance.md 验收判定留待 Sign-off Agent

### 踩过的坑 / 要小心的（≤3 条）
1. spec §7.2 IDLE 行"若曾完成过则 done_o=1"在当前 FSM 拓扑下不可达（无 DONE→IDLE 边）——编写 TC 时无需覆盖此路径
2. 单 word 包路径有投机性 word1 读——TC 中不应把此读当作功能行为校验
3. payload sum/xor 仅累加 byte_offset<pkt_len 范围内的字节——VPlan 可设计尾部非对齐包来验证边界

### 验证成果的最小命令
```
cd ppa-lab/lab2/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** VPlan Agent 编写 testplan，补全 F2-06(type one-hot)、F2-07(hdr_chk)、F2-08(algo_mode=0)、F2-09/10(payload 边界)、F2-11(多错误并行)、F2-14(exp_pkt_len) 的定向 TC
2. **[P0]** `make run` 全 PASS 后标记 feature-matrix TB 列 → #DONE
3. **[P1]** 考虑边界用例：pkt_len=5(非对齐尾 word)、pkt_len=32(满包)、同时触发多类错误

---

## Handoff: VPlan Agent → Sign-off Agent (2026-05-12, Lab2)

### 我做了什么（≤5 条）
1. 编写 testplan（TC7~TC14），覆盖 F2-06/F2-07/F2-08/F2-11/F2-14 及 F2-09/F2-10 边界
2. 在 `ppa_tb.sv` 实现 8 个定向 TC，`make comp` 0 error 0 warning
3. `make run` 全量 14 TC / 66 checks PASS，0 FAIL
4. feature-matrix F2-01~F2-14 TB 列全部 → #DONE
5. 更新 `testplan.md` / `ppa-status.md` / `ppa-feature-matrix.md`

### 我没做什么 / 留给下一步的（≤5 条）
1. acceptance.md 验收判定留待 Sign-off Agent
2. pkt_len=32（满包 8 word）的大包用例未单独覆盖（TC2 已覆盖多 word 路径）
3. 未做波形级时序审查
4. 选做项 4/5 已通过 TC7~TC10、TC13~TC14 覆盖，acceptance.md 中可标记

### 踩过的坑 / 要小心的（≤3 条）
1. TC11 三错误并行：pkt_len<4 时 words_total=1，header 单拍 DONE——此路径的 hdr_chk_err 使用组合逻辑而非锁存值
2. TC14 非对齐边界：pkt_len=5 只有 word1[7:0] 参与 sum/XOR，其余 3 字节的 byte_offset≥pkt_len 被跳过
3. exp_pkt_len_i 比较使用 hdr_b0[5:0]（6-bit 截断），RTL 与 spec 一致

### 验证成果的最小命令
```
cd ppa-lab/lab2/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** Sign-off Agent 执行 `acceptance.md` 逐项判定（必做 1~3 + 选做 4~5）
2. **[P0]** 验收通过后将 F2-01~F2-14 → #VERIFIED，关闭 Lab2
3. **[P1]** Lab3 顶层集成阶段启动

---

## Handoff: Sign-off Agent → DUT Agent (2026-05-12, Lab2 → Lab3)

### 我做了什么（≤5 条）
1. 执行 `make comp` (0 error 0 warning) + `make run` (14 TC / 66 checks / 0 FAIL)
2. 逐项判定 acceptance.md：3 项必做 + 2 项选做全部 PASS
3. feature-matrix F2-01~F2-14 备注列 → #VERIFIED
4. **第二轮审计**：对照 §10 验收测试场景矩阵，发现 N-3（最大合法包 32B）在 Lab2 TB 中无对应用例，F2-05 隐含但缺独立功能行
5. 将 N-3 缺口分析报告交付 VPlan Agent 进入迭代阶段修复

### 我没做什么 / 留给下一步的（≤5 条）
1. N-3 缺口修复由 VPlan Agent 在迭代阶段完成（TC15 + F2-15）
2. Lab3 顶层集成（ppa_top 连线）待 DUT Agent 启动
3. U-1（PKT_MEM APB 读返回 0）待 Lab3 解决
4. 组合 rd_en/addr 端到端时序余量待 Lab3 集成后评估

### 踩过的坑 / 要小心的（≤3 条）
1. §10 场景矩阵与 feature-matrix 之间的覆盖关系需交叉审计，F2-05 范围型功能行容易隐含边界值而漏测
2. A-2 假设（PKT_LEN_EXP "非零即已配置"）仍在 risk-register OPEN 状态，Lab3 应关注

### 验证成果的最小命令
```
cd ppa-lab/lab2/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** DUT Agent 启动 Lab3，实现 ppa_top 顶层连线（F3-01）
2. **[P0]** 解决 U-1（PKT_MEM APB 读返回 0 → 连接 M2 读端口）
3. **[P1]** Lab3 VPlan 设计端到端 TB 验证 F3-02~F3-06

---

## Handoff: VPlan Agent → DUT Agent (2026-05-12, Lab2 迭代 → Lab3)

### 我做了什么（≤5 条）
1. 响应 Sign-off Agent 第二轮审计的 N-3 缺口，在迭代阶段补充 TC15（pkt_len=32, 28B payload 满载）
2. 新增 feature-matrix F2-15（最大合法包满载处理），状态 → #VERIFIED
3. `make comp` 0 error 0 warning；`make run` 15 TC / 76 checks / 0 FAIL（TC1~TC14 无回归）
4. 更新 ppa-status.md / ppa-feature-matrix.md / ppa-risk-register.md（R-3 已关闭）/ log.md §5

### 我没做什么 / 留给下一步的（≤5 条）
1. Lab3 顶层集成由 DUT Agent 负责
2. §10 验收场景 N-3 已覆盖，Lab2 全部 §10 场景均已闭合

### 踩过的坑 / 要小心的（≤3 条）
1. 32B 包占满全部 8 word SRAM 空间（word0 header + word1~7 payload），字计数器 issue_idx 最大值为 7——恰好覆盖 3-bit addr 上限
2. payload sum 为 8-bit 截断累加，28 字节数据 sum=406 溢出为 0x96，设计预期值时需注意 mod 256

### 验证成果的最小命令
```
cd ppa-lab/lab2/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** DUT Agent 启动 Lab3 顶层集成（F3-01），解决 U-1
2. **[P1]** Lab3 端到端 TB 可复用 Lab2 TC15 的数据构造作为 32B 满载端到端用例

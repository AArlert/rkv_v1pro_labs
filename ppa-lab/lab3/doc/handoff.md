# Lab3 交接笔记 (Handoff Notes)

---

## Handoff: DUT Agent → Review Agent (2026-05-12, Lab3)

### 我做了什么（≤5 条）
1. 实现 `ppa_top.sv`：M1/M2/M3 纯连线 + M2 读端口优先级 MUX（2 行组合逻辑）
2. 解决 U-1：M1 新增 `pkt_mem_rdata_i` / `pkt_mem_re_o` 端口，APB 读 PKT_MEM 现返回真实 SRAM 数据
3. 搭建 Lab3 端到端 TB（TC1~TC3），覆盖 F3-01~F3-04
4. 更新 lab1 TB 端口连接（向后兼容）
5. 创建 lab3/doc/ 完整文档：design-prompt / acceptance / log / handoff

### 我没做什么 / 留给下一步的（≤5 条）
1. 选做 4（busy 写保护端到端验证）和选做 5（中断路径闭环）的 TC 未写
2. 未执行 `make comp` / `make run`（等待用户确认）
3. Lab1 回归测试未重跑（修改了 M1 端口，建议 Review Agent 确认）
4. `pkt_mem_re_o` 在 busy=1 时 APB 读 PKT_MEM 的 corner case 未覆盖（已记入 risk-register）
5. VPlan 阶段可补充更多端到端场景（异常包、PKT_MEM 读回验证）

### 踩过的坑 / 要小心的（≤3 条）
1. **SRAM 同步读延迟**：`pkt_mem_re_o` 必须在 SETUP 阶段（PENABLE=0）发起，ACCESS 阶段数据才可用。不能在 ACCESS 阶段才发起读
2. **MUX 优先级**：`m2_rd_addr` 使用 `m3_mem_rd_en` 做选择（非 busy_o），确保 M3 停止读后 M1 立即可用
3. **lab1 TB 兼容**：新增端口用 `.pkt_mem_rdata_i(sram_rd_data)` 连接（不改变行为），`.pkt_mem_re_o()` 留空

### 验证成果的最小命令
```
cd ppa-lab/lab3/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** 用户执行 `make comp` 确认 0 error，再 `make run` 确认 TC1~TC3 PASS
2. **[P0]** Review Agent 审查 ppa_top 连线与 spec §2.1 一致性
3. **[P1]** 确认 lab1 `make comp && make run` 回归通过

---

## Handoff: Review Agent → VPlan Agent (2026-05-12, Lab3)

### 我做了什么（≤5 条）
1. 逐项检查 ppa_top.sv 15 项连线与 spec §2.1/§2.3 一致性，全部通过
2. 验证 M2 读端口 MUX 仲裁逻辑正确（M3 优先、组合逻辑、无状态）
3. 验证 U-1 解决方案（M1 pkt_mem_rdata_i/re_o）实现合理
4. 核对 TB 三个 TC 的预期值计算（hdr_chk/sum/xor/STATUS），全部正确
5. 审查结果记入 lab3/doc/log.md §2

### 我没做什么 / 留给下一步的（≤5 条）
1. 未执行 `make comp` / `make run`（需用户在 Questasim 环境确认）
2. 选做 4（busy 写保护端到端）和选做 5（中断路径闭环）的 TC 未覆盖
3. Lab1 回归测试未重跑（M1 新增端口后的兼容性需确认）
4. 异常包场景（E-1~E-6）端到端 TC 未写
5. PKT_MEM APB 读回路径（M1→M2 读方向）无独立 TC

### 踩过的坑 / 要小心的（≤3 条）
1. **M1 enable_o/done_irq_en_o/err_irq_en_o 在 ppa_top 悬空**：这是正确行为（M1 内部消费），VPlan 不需要额外连线
2. **busy=1 时 APB 读 PKT_MEM 返回 M3 当前读数据**：R-4 已登记，不在必做验收范围，但 TB 应避免在 busy 期间做 PKT_MEM 读测试
3. **TC3 依赖处理时间足够捕获 busy**：12B 包（3 word）给了约 3 拍处理窗口，APB 读需 2 拍，时序刚好够用

### 验证成果的最小命令
```
cd ppa-lab/lab3/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** 用户执行 `make comp && make run` 确认 0 error + TC1~TC3 PASS
2. **[P0]** VPlan Agent 补充端到端 TC（异常包 E-1~E-6、选做 4/5）
3. **[P1]** 确认 lab1 `make comp && make run` 回归通过（M1 新增端口兼容性）

---

## Handoff: VDebug Agent → Sign-off Agent (2026-05-12, Lab3)

### 我做了什么（≤5 条）
1. 分析 TC10 (tc_irq_path_e2e) 失败：`irq_o asserted: got 0, expected 1`
2. 逐周期追踪 4B 包处理时序，定位 root cause 为 TB 采样时机与 `reg_done_irq` NBA 竞争
3. 修复 `ppa_tb.sv`：TC10 `poll_done()` 后新增 `@(posedge PCLK)` 等 1 拍再采样 `irq_o`
4. 更新 log.md §3 运行结果 + §4 调试阶段完整记录
5. 更新 testplan.md TC4~TC11 结果列

### 我没做什么 / 留给下一步的（≤5 条）
1. 未执行 `make comp` / `make run`（需用户在 Questasim 环境验证修复）
2. Lab1 回归测试未重跑
3. acceptance.md 未执行验收判定（Sign-off Agent 职责）

### 踩过的坑 / 要小心的（≤3 条）
1. **4B 最小包处理仅 2 拍**：M3 在 W5 即转 DONE（header-only），done_rising 和 poll_done PRDATA 捕获对齐在同一 posedge，导致 NBA/active-region 竞争
2. **后续如有新 TC 检查组合输出（如 irq_o），务必在 poll_done 后等 1 拍**：任何依赖 NBA 的寄存器组合输出都有此风险
3. **归因为 TB 缺陷**：RTL（irq_o = reg_done_irq | reg_err_irq）无问题，完全符合 spec §8.2

### 验证成果的最小命令
```
cd ppa-lab/lab3/svtb/sim
make comp
make run
```

### 推荐下一步动作（≤3 条，按优先级）
1. **[P0]** 用户执行 `make comp && make run` 确认 TC1~TC11 全 PASS（40/40 checks）
2. **[P0]** Sign-off Agent 按 acceptance.md 逐项判定（必做 1~3 + 选做 4/5）
3. **[P1]** 确认 lab1 `make comp && make run` 回归通过

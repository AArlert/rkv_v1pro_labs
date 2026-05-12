# Lab3 实验日志 (Log)

## Status 摘要

- **阶段**: 设计阶段
- **DUT Agent**: 完成 ppa_top 顶层连线 + 最小端到端 TB
- **关键决策**: M2 读端口 MUX 仲裁（M3 优先）；M1 新增读回端口解决 U-1
- **待验证**: `make comp` 0 error; `make run` TC1~TC3 PASS

---

## §1 设计阶段

### 挑战

1. **M2 读端口共享**: M2 为单读端口 SRAM，M3 处理时需要读，M1 APB 读 PKT_MEM 也需要读。需要仲裁
2. **U-1 解决**: Lab1 遗留 PKT_MEM APB 读返回 0 的问题，需要在 Lab3 集成时解决
3. **时序匹配**: M1 的 `pkt_mem_re_o` 在 SETUP 阶段发起，SRAM 同步读需 1 拍，数据在 ACCESS 阶段到达——恰好匹配 APB 两段式时序

### 设计决策

| ID | 决策 | 理由 |
|----|------|------|
| L3-D-1 | 读端口 MUX 放在 ppa_top，M3 `mem_rd_en_o` 做优先级选择 | 保持 M1/M2/M3 接口不互相感知；ppa_top 仅 2 行组合逻辑，不算"状态逻辑" |
| L3-D-2 | M1 新增 `pkt_mem_rdata_i` + `pkt_mem_re_o` | 最小侵入：M1 只加 1 个输入 + 1 个输出 + 2 行逻辑；lab1 TB 向后兼容 |
| L3-D-3 | busy=1 期间 APB 读 PKT_MEM 返回 M3 的当前读数据（非精确语义） | 单读端口物理限制；文档已记入 risk-register |

### 对规格的假设

- ppa_top "无额外状态逻辑"解释为无寄存器/无 FSM；组合 MUX 属于"纯连线"范畴
- busy=1 时 APB 读 PKT_MEM 为 corner case，不在 Lab3 必做验收范围内

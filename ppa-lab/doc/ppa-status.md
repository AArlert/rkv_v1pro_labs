# PPA-Lite 项目状态看板

> 任何 Agent 提交前必须更新本文件

## 当前阶段

**Lab2 设计阶段完成 → 待 Review Agent 审查**

## 已完成里程碑

| 里程碑 | 完成时间 | 备注 |
|--------|----------|------|
| Lab1 设计（M1+M2 RTL） | 2026-05-10 | APB 从接口 + SRAM，TB 含自动回读比对 |
| Lab1 审查通过 | 2026-05-11 | F1-01~F1-15 全部与 Spec 一致，无阻塞性问题 |
| Lab1 验证完成 | 2026-05-11 | 10 TC / 61 checks 全 PASS，F1-01~F1-15 TB 全部 #DONE |
| Lab1 验收通过 | 2026-05-11 | 4 项必做验收标准全 PASS，F1-01~F1-15 → #VERIFIED，Lab1 关闭 |
| Lab2 设计完成（M3 RTL） | 2026-05-11 | ppa_packet_proc_core.sv 实现；最小 TB 33/33 checks PASS；F2-01~F2-14 实现状态 → #DONE |

## 进行中

- Lab2 审查（待 Review Agent 进入）

## 阻塞项

- 无

## 未决问题

| ID | 描述 | 来源 | 严重性 |
|----|------|------|--------|
| U-1 | PKT_MEM APB 读返回 0 而非实际 SRAM 数据 | Lab1 设计 | LOW（Lab3 集成时连接 M2 读端口） |

## 下一步

1. Review Agent 审查 M3 RTL 与 spec §3/§7/§9 的一致性
2. VPlan Agent 补充 F2-06~F2-11、F2-14 定向 TC
3. Lab3 顶层集成阶段解决 U-1，并验证组合 rd_en/addr 端到端时序

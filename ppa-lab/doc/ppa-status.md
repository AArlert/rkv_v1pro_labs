# PPA-Lite 项目状态看板

> 任何 Agent 提交前必须更新本文件

## 当前阶段

**Lab4 Phase 4 完成 — UVM 覆盖率收集与对比，总覆盖率 97.84%（超 SV 基线 97.47%），各模块各项均 ≥90%**

## 已完成里程碑

| 里程碑                | 完成时间       | 备注                                                                                                     |
| ------------------ | ---------- | ------------------------------------------------------------------------------------------------------ |
| Lab1 设计（M1+M2 RTL） | 2026-05-10 | APB 从接口 + SRAM，TB 含自动回读比对                                                                              |
| Lab1 审查通过          | 2026-05-11 | F1-01~F1-15 全部与 Spec 一致，无阻塞性问题                                                                         |
| Lab1 验证完成          | 2026-05-11 | 10 TC / 61 checks 全 PASS，F1-01~F1-15 TB 全部 #DONE                                                       |
| Lab1 验收通过          | 2026-05-11 | 4 项必做验收标准全 PASS，F1-01~F1-15 → #VERIFIED ，Lab1 关闭                                                       |
| Lab2 设计完成（M3 RTL）  | 2026-05-11 | ppa_packet_proc_core.sv 实现；最小 TB 33/33 checks PASS；F2-01~F2-14 实现状态 → #DONE                            |
| Lab2 审查通过          | 2026-05-11 | F2-01~F2-14 逐项与 spec §3/§7/§9 一致，无阻塞性问题                                                                |
| Lab2 验证完成          | 2026-05-12 | 14 TC / 66 checks 全 PASS；F2-01~F2-14 TB 全部 #DONE                                                       |
| Lab2 验收通过          | 2026-05-12 | 3 项必做 + 2 项选做全 PASS；F2-01~F2-14 → #VERIFIED ，Lab2 关闭                                                   |
| Lab2 迭代补充 N-3      | 2026-05-12 | 补充 TC15（pkt_len=32 满载包）；新增 F2-15；15 TC / 76 checks 全 PASS                                              |
| Lab3 设计完成          | 2026-05-12 | ppa_top.sv 连线 + U-1 解决；3 TC / 12 checks 全 PASS；F3-01~F3-04 → #DONE                                     |
| Lab3 审查通过          | 2026-05-12 | 15 项连线 vs spec §2.1/§2.3 全部一致；无阻塞性问题                                                                   |
| Lab3 验证完成          | 2026-05-12 | 11 TC（TC1~TC11）；F3-01~F3-06 TB 全部 #DONE ；含选做 4/5 + 错误通路 + PKT_MEM 读回                                   |
| Lab3 验收通过          | 2026-05-12 | 3 必做 + 2 选做全 PASS；F3-01~F3-06 → #VERIFIED ，Lab3 关闭                                                     |
| Lab4 Phase 0 完成    | 2026-05-13 | 36 TC / 177 checks 结构化回归列表；Spec §10 全 14 场景覆盖；testplan.md 产出                                           |
| Lab4 Phase 1 完成    | 2026-05-13 | Makefile 统一入口 (smoke/regress/cov)；36 TC 全 PASS；Coverage 基线 82.93%                                      |
| Lab4 Phase 2 完成    | 2026-05-13 | Coverage Closure: 42 TC / 224 chk 全 PASS；五类覆盖率全 ≥90% (总 97.47%)；排除登记表                                  |
| Lab4 Phase 3 完成    | 2026-05-15 | UVM 升级：纯 SV TB 重构为 UVM 环境（apb_if + ref_model + pkg + uvm_tb）；18 个 test 全 PASS；原 SV regress 224/224 不退化 |
| Lab4 Phase 4 完成    | 2026-05-15 | UVM 覆盖率收集：消除 TB 污染、修复 FSM 转移、补充 IRQ error 路径；总覆盖率 97.84%（超 SV 基线 97.47%）                               |

## 进行中

- 无（Phase 4 已完成）

## 阻塞项

- 无

## 未决问题

| ID | 描述 | 来源 | 严重性 |
|----|------|------|--------|
| U-2 | busy=1 期间 APB 读 PKT_MEM 返回 M3 当前读数据（非精确语义） | Lab3 设计 | LOW（corner case，不在必做验收范围） |

## 下一步

1. **Lab4 Phase 5 (可选): 功能覆盖率扩展** — 在 `ppa_coverage` 中增补 covergroup（pkt_len/type/error 多维 cross），当前 87.22%，可推至 ≥90%
2. **Lab4 Phase 6 (可选): 覆盖率排除登记** — u_m3 的 `default` 分支（结构性不可达）可正式排除，使 Branch 和 Statements 达到 100%

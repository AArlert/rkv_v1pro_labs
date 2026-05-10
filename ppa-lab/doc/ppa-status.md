# PPA-Lite 项目状态看板

> 任何 Agent 提交前必须更新本文件

## 当前阶段

**Lab1 验证阶段完成 -> 待验收**

## 已完成里程碑

| 里程碑 | 完成时间 | 备注 |
|--------|----------|------|
| Lab1 设计（M1+M2 RTL） | 2026-05-10 | APB 从接口 + SRAM，TB 含自动回读比对 |
| Lab1 审查通过 | 2026-05-11 | F1-01~F1-15 全部与 Spec 一致，无阻塞性问题 |
| Lab1 验证完成 | 2026-05-11 | 10 TC / 61 checks 全 PASS，F1-01~F1-15 TB 全部 #DONE |

## 进行中

- Lab1 验收阶段（待 Sign-off Agent 按 acceptance.md 逐项判定）

## 阻塞项

- 无

## 未决问题

| ID | 描述 | 来源 | 严重性 |
|----|------|------|--------|
| U-1 | PKT_MEM APB 读返回 0 而非实际 SRAM 数据 | Lab1 设计 | LOW（Lab3 集成时连接 M2 读端口） |

## 下一步

1. 由 Sign-off Agent 按 acceptance.md 逐项判定
2. 全部必做项 PASS 后关闭 Lab1
3. 进入 Lab2（M3 包处理核心）

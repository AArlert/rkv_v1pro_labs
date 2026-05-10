# PPA-Lite 项目状态看板

> 任何 Agent 提交前必须更新本文件

## 当前阶段

**Lab1 设计阶段完成 -> 待编译验证**

## 已完成里程碑

| 里程碑 | 完成时间 | 备注 |
|--------|----------|------|
| Lab1 设计（M1+M2 RTL） | 2026-05-10 | APB 从接口 + SRAM，TB 含自动回读比对 |

## 进行中

- Lab1 编译验证（make comp / make run）

## 阻塞项

- 无

## 未决问题

| ID | 描述 | 来源 | 严重性 |
|----|------|------|--------|
| U-1 | PKT_MEM APB 读返回 0 而非实际 SRAM 数据 | Lab1 设计 | LOW（Lab3 集成时连接 M2 读端口） |

## 下一步

1. 运行 `make comp` / `make run` 确认编译仿真通过
2. 由 Verification Plan Agent 补充 testplan.md
3. 待 Lab1 验收通过后启动 Lab2（M3 包处理核心）

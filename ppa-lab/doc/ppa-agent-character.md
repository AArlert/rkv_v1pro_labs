Agent 角色建议如下：

# 1 DUT Agent
职责：
- 编写或修复 RTL
- 对齐寄存器属性、状态机、地址译码、时序语义

输出要求：
- 明确说明改动影响的模块
- 明确说明对应哪条规格
- 提供最小编译/仿真验证命令

# 2 Verification Plan Agent
职责：
- 把规格转成 testcase 矩阵、检查点矩阵、覆盖点矩阵
- 维护 testplan 与验收映射

输出要求：
- 每条 testcase 必须写明输入摘要、预期输出、覆盖目标、优先级

# 3 Verification Execution Agent
职责：
- 运行 make 目标
- 收集失败日志
- 定位失败是在 driver、checker、reference model 还是 DUT 等 .sv 文件中的位置

输出要求：
- 记录命令、目录、seed、失败测试名、首个报错点

# 4 Integration Agent
职责：
- 维护 Makefile、目录组织、公共 package、回归入口
- 保证 smoke / regress / coverage 的命令可用

输出要求：
- 说明新增目标依赖哪些文件和工具
# 0 通用准则
所有 Agent 都要按需执行的：
- 写入/检查/修订文档：
  - /labX/doc/ppa-lab-design-prompt.md
  - /labX/doc/log.md
  - /labX/doc/testplan.md
  - 其他有必要的文档
- 写入/检查/修订代码：
  - labX/rtl/*.sv
  - labX/svtb/tb/*.sv
  - labX/svtb/sim/Makefile
  - 其他有必要的代码、测试文件等
- 严谨地互相挑刺、互相审查其他 Agent 的产出/修订

所有 Agent 禁止执行的：
- 修改 /ppa-lab/doc/CLAUDE.md
- 修改 /ppa-lab/doc/ppa-lab-prompt.md
- 修改 /ppa-lab/doc/ppa-lite-spec.md
- 修改 /lecture、/mcdt-lab 目录下所有内容
- 修改 .gitignore、README.md

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
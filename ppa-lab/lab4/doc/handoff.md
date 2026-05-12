# Lab4 交接笔记 (Handoff)

## Handoff: VPlan Agent → Next Agent (2026-05-13, Lab4 Phase 0)

### 我做了什么
1. 创建 lab4/ 目录结构 (doc/, rtl/, svtb/tb/, svtb/sim/)
2. 通读 Lab1-3 全部 testplan.md、ppa_tb.sv、acceptance.md、feature-matrix
3. 与 Spec §10 验收测试场景矩阵逐项交叉比对
4. 输出 `lab4/doc/testplan.md` — 36 TC / 177 checks 结构化回归列表
5. 定义 Smoke (4 TC) / Regress (36 TC) 分级, 附下游工作备忘

### 我没做什么 / 留给下一步的
1. **Makefile 统一入口** (`make smoke / regress / cov`) — 需新建 lab4/svtb/sim/Makefile
2. **全量回归运行** — 需在 lab4 Makefile 就位后执行
3. **Coverage 收集** — 需在 Makefile 加 `+cover` 编译选项和 `coverage save/report`
4. **UVM 升级** — testplan.md §8.2 已列出升级路径要点, 但未动手
5. **E-2/E-4/B-4 E2E 补充** — 当前仅 module-level 覆盖, 非阻塞但可增强

### 踩过的坑 / 要小心的
1. Lab1 TC 编号 (TC1~TC10) 与 Lab2/Lab3 TC 编号有重叠, 回归列表使用 L1_TC01 等前缀消歧
2. Lab1 TB 的 M3 输入是 stub 驱动, 不可与 Lab3 E2E TC 混为一级
3. Lab2 TC15 是迭代阶段追加的 (N-3 验收场景), 在原始 testplan.md 的 VPlan 补充表中未列出但在 TB 源码中已实现

### 验证成果的最小命令
```bash
# 确认 testplan 文件已生成
cat ppa-lab/lab4/doc/testplan.md | head -5

# 确认现有回归仍全 PASS (各 lab 独立运行)
cd ppa-lab/lab1/svtb/sim && make comp && make run
cd ppa-lab/lab2/svtb/sim && make comp && make run
cd ppa-lab/lab3/svtb/sim && make comp && make run
```

### 推荐下一步动作
1. **建立 lab4/svtb/sim/Makefile** — 实现 `make smoke` (4 TC 快速冒烟) 和 `make regress` (3 lab 顺序全量)
2. **运行全量回归** — 确认 36 TC / 177 checks 全 PASS
3. **启用覆盖率收集** — `make cov` 生成 Questa HTML 覆盖率报告 (line/branch/condition/FSM/toggle)

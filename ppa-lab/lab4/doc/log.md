# Lab4 实验日志 (Log)

## Status: Phase 0 完成 — 回归列表整理

---

## Phase 0: 全量 Testcase 整理 (2026-05-13)

**执行者**: Verification Plan Agent

### 目标
整理 Lab1-3 全部必做 testcase 为结构化回归列表, 为后续 Makefile 统一入口和覆盖率收集奠定基础。

### 产出
- `lab4/doc/testplan.md` — 36 TC / 177 checks 回归列表
- `lab4/doc/handoff.md` — 交接笔记
- `lab4/doc/log.md` — 本文件

### 关键发现
1. Lab1-3 共 36 个 TC, 分布在 3 个独立 TB 中, 涵盖 module-level (M1+M2, M3) 和 integration-level (ppa_top) 两个验证层级
2. Spec §10 全部 14 个验收场景 (N-1~N-4, E-1~E-6, B-1~B-4) 均有 TC 覆盖, 无遗漏
3. 36 个 Feature (F1-01~F1-15 + F2-01~F2-15 + F3-01~F3-06) 全部 #VERIFIED
4. E-2/E-4/B-4 仅有 module-level 覆盖 (无 E2E TC), 但核心逻辑已验, 端到端链路由其他 TC 覆盖

### 决策
- 回归 ID 采用 `L<lab>_TC<nn>` 前缀消歧 (避免 3 个 TB 的 TC ID 冲突)
- Smoke 集选定 4 个 TC (L1_TC01/L1_TC02/L2_TC01/L3_TC01), 覆盖每个 DUT 层级的最基础功能
- 保持 3 个 TB 独立编译运行 (不合并), 保留 module-level 验证的独立性

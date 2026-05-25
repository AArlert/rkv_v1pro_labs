# review_report/ — REV 审查报告归档

> **永不覆盖既有文件**。目录本身按文件名时间序即是索引，不维护单独的 INDEX.md。

## 文件命名规则

```
<YYYYMMDD>-<HHMM>-lab<N>-<phase>-<target>.md
```

| 字段 | 取值 | 说明 |
|---|---|---|
| `YYYYMMDD` | 8 位日期 | UTC+8 当地日期 |
| `HHMM` | 4 位时分 | 24 小时制 |
| `lab<N>` | `lab1` / `lab2` / `lab3` / `lab4` | 对应 spec §11 的 4 个实验 |
| `<phase>` | `design` / `tb` / `integration` / `regression` | 与 `doc/workflow.md` §2 的 D/V/I/R 阶段对应 |
| `<target>` | `rtl-<module>` / `tb` / `env` / `full` | 审查对象；`full` 用于 lab 关单的全量审查 |

### 合法 phase × target 组合

| phase | 允许的 target |
|---|---|
| `design` | `rtl-apb_slave_if` / `rtl-packet_sram` / `rtl-packet_proc_core` / `rtl-ppa_top` |
| `tb` | `tb` / `env` |
| `integration` | `full` |
| `regression` | `full` |

### 示例文件名

```
20260415-1430-lab1-design-rtl-apb_slave_if.md
20260415-1612-lab1-tb-tb.md
20260418-0930-lab1-design-rtl-apb_slave_if.md     ← 同一对象第二次审查（修复后复审）
20260502-1100-lab2-design-rtl-packet_proc_core.md
20260520-1545-lab3-integration-full.md
20260610-0830-lab4-regression-full.md
```

## 报告内部结构（四段式）

每份报告必须包含以下四段（结构固定，便于学生复习时按模式扫读）：

1. **Where（bug 从哪里来）** — file:line + 触发场景 + 波形/log 时刻证据
2. **How-to-fix（怎么解决）** — 具体修法位置（一句话，不替学生写代码）
3. **Why（为什么）** — 违反了 spec §X.Y 的哪一条 + 根因
4. **How-it-was-done（学生当时怎么做的）** — 推断学生误解了什么、漏看了哪段 spec，帮 ta 下次避坑

完整模板见 [`../../agent/review.md`](../../agent/review.md) 末尾 "Output Format" 节。

## 索引检索小技巧

```bash
# 看 lab2 历史上所有的 design 阶段审查报告
ls doc/review_report/ | grep -E '^[0-9]{8}-[0-9]{4}-lab2-design-'

# 看某一天所有审查
ls doc/review_report/20260415-*.md

# 看某个 RTL 模块被审了几次
ls doc/review_report/*rtl-packet_proc_core.md | wc -l
```

## 禁止行为

- ❌ 不得修改、删除、覆盖任何既有报告（即使报告里的结论后来被推翻）
- ❌ 不得用同一文件名覆盖（时间戳到分钟，仍冲突的话往后挪 1 分钟）
- ❌ 不得在本目录创建非报告 .md（INDEX.md、SUMMARY.md 等均不允许；本 README 例外）

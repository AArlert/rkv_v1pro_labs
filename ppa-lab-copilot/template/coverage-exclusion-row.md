# template: `lab*/doc/coverage_exclusion.md` 单条豁免行

> 每豁免一个 bin / branch / line 写一行。**没有 spec/design-prompt 引用的豁免一律不批**。

表头：

```markdown
| 范围 | bin/branch | 原因 | spec § 或 design-prompt § | 谁批准 | 日期 |
|---|---|---|---|---|---|
```

示例：

```markdown
| ppa_packet_proc_core | unreachable: state IDLE→ERR @ algo_mode=0xF | 0xF 在 spec §5.2 标 reserved | spec §5.2 | ORCH | 2026-MM-DD |
| ppa_apb_slave_if | toggle: PSLVERR @ reset 期 | reset 期 PSLVERR 不被采样 | design-prompt §3.4 | ORCH | 2026-MM-DD |
```

## 字段说明

- `范围` = module 名（必要时加 hierarchical path）
- `bin/branch` 描述要能在 URG 报告里被搜到
- `谁批准` 必须是 ORCH（DV 不能自批）
- 加进本文件不会自动让覆盖率达标；URG 需在跑 `cov` 时带 `-cm_filter exclusion.cfg`

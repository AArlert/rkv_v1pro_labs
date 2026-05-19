# template: `lab*/doc/log.md` ROLE 块

> append-only。每次进入角色写一段，离开时回填 `<<<` 行的时间。

```markdown
>>> ROLE: <role-name> @ YYYY-MM-DD HH:MM — <这次进入要做的一件事>
- Did: <做了什么>（≤ 3 条 bullet）
- Decisions: <为什么>（关键 trade-off，1–2 条；引 spec § 或 design-prompt §）
- Result: PASS / FAIL / blocked + 一句话
- Next: <交给谁 / 等什么>
<<< ROLE: <role-name> @ YYYY-MM-DD HH:MM
```

## 字段说明

- `<role-name>` ∈ `orchestrator` / `architect` / `rtl-designer` / `dv-engineer` / `reviewer`
- `Did` 是动词开头的事实句，不写计划
- `Decisions` 是真正影响产物的选择，无则写 "—"
- `Result.blocked` 必须配套写 `Next: 升级 ORCH (RISK-xxxx)` 并去 `template/handoff.md` 写交接

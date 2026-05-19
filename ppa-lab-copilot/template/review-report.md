# template: `lab*/doc/review_report/<YYYYMMDD>-<HHMM>-<trigger>-<target>.md`

> 文件名规则（来自 `agents/reviewer.md`）：
> - `<trigger>` ∈ `ondemand` / `labclose`
> - `<target>` ∈ `design-prompt` / `rtl-<module-name>` / `tb` / `full`（labclose 用 `full`）
> 永不覆盖既有文件。

```markdown
## Review Report — <target> — YYYY-MM-DD (trigger: ondemand|labclose)

### Inputs reviewed
- <file:line ranges>

### Evidence used
- xwave: <fsdb 路径 / cursor / signal=value @time>
- xtrace: <driver/load query>
- logs: <path:line>
- spyglass: <svtb/spyglass_reports/.../*.rpt:line>
- make: <跑过哪些 make target，及其退出码>

### P0 (must fix → 升级 ORCH)
- [file:line] 描述 — 引 spec §X.Y / design-prompt §Z — 证据: <…>

### P1 (should fix)
- ...

### P2 (nice to have)
- ...

### Praise
- ...
```

## 字段说明

- 每条 note 必须**双重引用**：`(file:line) + (spec § 或 design-prompt §)`。缺一项降级 P2 或丢弃。
- `Evidence used → make` 是 v6 新增——REV 已可在本机经 make 触发 EDA，所有跑过的 target 都要登记
- 含 P0 时按 `template/risk-entry.md` 登记到 state.md，并写 handoff

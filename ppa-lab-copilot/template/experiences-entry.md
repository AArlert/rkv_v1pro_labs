# template: `memory/<domain>/experiences.md` 单条经验

> append-only。任何角色完成 stage / 学到一次教训 / ORCH 做出决策时追加。
> 蒸馏到 `<domain>/knowledge.md` 后**不删**本文件条目。

```markdown
- **场景**: lab<N>.<phase> — <目标>
- **时间**: YYYY-MM-DDTHH:MM
- **操作**: <做了什么>
- **结果**: PASS / FAIL / blocked — <一句话>
- **教训**: <可空，1–2 行>
- **artifacts**: <文件:行 / log / 波形 / review_report 路径>
```

## 字段说明

- `<domain>` ∈ `orchestrator` / `architecture` / `rtl` / `dv`（REV 高价值 pattern 蒸馏进各 domain 的 knowledge.md）
- 一次只记一件事；多件分多条
- `教训` 字段是这条记录的灵魂；写不出教训说明这次操作还不够"反思深"
- `artifacts` 给相对路径，让未来的自己 1 秒定位现场

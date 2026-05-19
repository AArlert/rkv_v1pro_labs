# template: `lab*/doc/handoff.md` 跨 Agent 交接段

> append-only。**只在**跨 Agent 回退 / lab 关单时写。日常进度写 log.md，不写本文件。

```markdown
## YYYY-MM-DD HH:MM  <from-role> → <to-role>  (RISK-xxxx | labclose)

**TL;DR**: <一句话；对方读这一行决定要不要继续读>

**Context**: <你在做什么；前序产出在哪>
**Evidence**: <文件:行 / log:line / 波形 cursor / spec §X.Y>
**Already tried**: <你已经试过的 1–3 条思路，省去对方重复劳动>
**Ask**: <动词开头：希望对方做什么>

---
```

## 字段说明

- 第一行括号里写关联 RISK id（来自 `memory/state.md`）或 `labclose`
- TL;DR 是给"决定要不要打开"的一行；超出 1 行表示拆得不够细
- Evidence 全部相对路径，不允许 "见之前那个 log"
- Ask 必须可执行（"重做 W1P start 单拍逻辑"，不是 "看看"）

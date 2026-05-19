# template: `lab*/doc/testplan.md` 单条 TC 行

> testplan.md 顶部用一次表头，下面每条 TC 一行。**self-check 优先**，禁止 "看波形判定" 作为 PASS 依据。

表头：

```markdown
| TC | feature | spec § | input | expected | check-points |
|---|---|---|---|---|---|
```

示例（两条）：

```markdown
| TC1 | CSR_DEFAULT | §2.2 | reset 后 APB 读全 11 个寄存器 | 复位值与表 §2.2 完全一致 | apb_read + `CHECK` 宏 |
| TC5 | RO_PROTECT  | §2.3.1 | APB 写 STATUS / RES_* / ERR_FLAG | PSLVERR=1 且寄存器不变 | tb 内 self-check + xwave 复核（可选） |
```

## 字段说明

- `TC` 全 lab 内唯一；编号别复用，被删的留空号
- `spec §` 必填，找不到 § → 这条 TC 不该存在
- `input` 写得能让别人无歧义复现
- `expected` 是 RTL 行为，不是 TB 行为
- `check-points` 列出 TB 里 self-check 的入口（task 名 / 宏 / assertion）

# template: 按需调 REV 一行（写在 `lab*/doc/log.md` ROLE 块内或紧邻位置）

```markdown
>>> CALL REV @ YYYY-MM-DD HH:MM on <target>
    reason: <一句话为什么需要外部 sanity check>
    artifacts: <文件:行 / log:line / fsdb 路径 / spyglass.rpt 路径>
```

## 字段说明

- `<target>` ∈ `design-prompt` / `rtl-<module>` / `tb` / `makefile` / `spyglass-report`
- `artifacts` 必须给 REV 可定位的相对路径；缺这一行 REV 会拒审
- REV 完成后在 `lab*/doc/review_report/<YYYYMMDD>-<HHMM>-ondemand-<target>.md` 落地报告

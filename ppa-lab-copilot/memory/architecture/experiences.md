# Architecture Experiences

## EXP-2026-05-18-001 — 项目初始化

- 场景：lab1 / orchestrator / project-init
- 时间：2026-05-18T00:00:00Z
- 角色：orchestrator
- 输入：`doc/ppa-plan.md`
- 操作：初始化 ppa-lab-copilot 的 agents、skill、memory 框架
- 结果：PASS
- 证据：`agents/`、`skill/`、`memory/` 已落地
- 教训：后续状态文件应以人可读 Markdown 为主，减少 JSON/JSONL 手写负担
- 后续：ARCH 完成 `lab1/doc/design-prompt.md`

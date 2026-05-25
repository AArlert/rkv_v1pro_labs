---
name: copilot-rtl-trace
description: 让 Copilot Agent 用 xtrace 在 VCS *.daidir 上追 RTL 信号的 driver/load，回答"X 信号被谁驱动/谁读取"
license: MIT
when_to_use: 当我说"start_o 到底被哪些条件驱动"、"PSLVERR 的所有 driver 在哪"、"X 信号流到哪些 module" 时
inputs:
  - VCS daidir 路径（默认 lab*/svtb/sim/simv.daidir）
  - 信号全路径（必须是精确 RTL 路径，不支持短名模糊匹配）
outputs:
  - driver 列表（含 file:line + 控制依赖 if/case）
  - load 列表
  - assignment AST / RHS 信号 / confidence 标签
tools:
  - xtrace (/home/open_tools/xtrace)
---

# Copilot: RTL Trace via xtrace

## Purpose

理解 RTL 信号驱动关系不需要肉眼读 600 行 SV。`xtrace` 用 Synopsys NPI 解析 daidir，给出**精确的**driver/load + 控制依赖。

## Tool Location

```
/home/open_tools/xtrace/tools/xtrace-env <command> ...
```

## When to Use

| 我的请求 | Agent 动作 |
|---|---|
| "PSLVERR 被哪些条件驱动" | `trace.driver` |
| "start_o 流到哪些模块" | `trace.load` |
| "为啥这个 always_comb 会触发" | `control.explain` |
| "FSM 里 PROCESS→DONE 的转移条件" | `fsm.explain` |
| "counter 什么时候 increment" | `counter.explain` |
| "信号赋值的完整条件分支" | `procedural.assignment` |

## How to Use — Agent SOP

### 1. 打开 Session（具名，支持复用）

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"session.ensure","target":{"dbdir":"/path/to/simv.daidir"},"args":{"name":"case_a"}}'
```

或一条命令完成 session ensure + trace（推荐 Agent 用法）：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"trace.driver","target":{"dbdir":"/path/to/simv.daidir","auto_ensure":true},"args":{"signal":"top.u_dut.ready"}}'
```

### 2. 追踪信号 Driver

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"trace.driver","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.PSLVERR"}}'
```

### 3. 追踪信号 Load

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"trace.load","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.start_o"}}'
```

### 4. 过滤结果

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"trace.driver","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.ready","limit":5,"role":"driver","no_statement_only":true}}'
```

### 5. 信号发现（信号路径不确定时）

`signal.resolve` 只接受精确 RTL 路径。找不到时返回 `status=not_found`。

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"signal.resolve","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.PSLVERR"}}'
```

短名或片段查找用外部 grep：

```bash
rg -n "PSLVERR" /path/to/rtl
```

### 6. 控制依赖分析

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"control.explain","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.PSLVERR"}}'
```

### 7. 高层因果分析 Actions

过程赋值分析（列出所有赋值分支、条件、默认值）：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"procedural.assignment","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.PSLVERR"}}'
```

时序更新规则（clock/reset/increment/decrement/hold）：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"sequential.update","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.state_q"}}'
```

FSM 状态转移：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"fsm.explain","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.state_q"}}'
```

Counter 规则：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"counter.explain","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.count_q"}}'
```

表达式规范化（获取赋值 RHS AST）：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"expr.normalize","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.PSLVERR"}}'
```

源码上下文：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"source.context","target":{"session_id":"case_a"},"args":{"file":"/path/to/rtl.sv","line":42}}'
```

端口/实例映射：

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"port.trace","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.apb_if.PSLVERR"}}'
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"instance.map","target":{"session_id":"case_a"},"args":{"instance":"ppa_tb.dut"}}'
```

### 8. 批量查询

```bash
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"batch","args":{"requests":[{"action":"trace.driver","args":{"signal":"ppa_tb.dut.PSLVERR"}},{"action":"trace.load","args":{"signal":"ppa_tb.dut.start_o"}}]},"target":{"session_id":"case_a"}}'
```

### 9. Session 管理

```bash
# 列出所有 session
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"session.list"}'

# 诊断 session
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"session.doctor","target":{"session_id":"case_a"}}'

# 关闭 session
/home/open_tools/xtrace/tools/xtrace-env ai query --json '{"api_version":"xtrace.ai.v1","action":"session.kill","args":{"id":"case_a"}}'
```

## 也可使用传统 CLI（面向人）

```bash
# 一条命令完成 ensure + trace（query 入口）
/home/open_tools/xtrace/tools/xtrace-env query -dbdir /path/to/simv.daidir --name case_a --driver ppa_tb.dut.PSLVERR -json --limit 10
/home/open_tools/xtrace/tools/xtrace-env query -dbdir /path/to/simv.daidir --name case_a --load ppa_tb.dut.start_o -json

# 分步操作
/home/open_tools/xtrace/tools/xtrace-env open -dbdir /path/to/simv.daidir --name case_a
/home/open_tools/xtrace/tools/xtrace-env driver ppa_tb.dut.PSLVERR -s case_a -json
/home/open_tools/xtrace/tools/xtrace-env load ppa_tb.dut.start_o -s case_a -json
/home/open_tools/xtrace/tools/xtrace-env signal resolve ppa_tb.dut.PSLVERR -s case_a -json
/home/open_tools/xtrace/tools/xtrace-env session kill case_a
```

## AI JSON Response 结构

`driver/load` 典型输出：

```json
{
  "ok": true,
  "query": "ppa_tb.dut.PSLVERR",
  "mode": "driver",
  "result_count": 2,
  "truncated": false,
  "results": [
    {
      "signal": "ppa_tb.dut.apb_if.pslverr_cond",
      "role": "driver",
      "file": "/path/to/ppa_apb_slave_if.sv",
      "line": 87,
      "source": "assign PSLVERR = pslverr_cond;",
      "resolution": "signal",
      "rhs_signals": ["ppa_tb.dut.apb_if.pslverr_cond"],
      "assignment": { "kind": "continuous_assignment", "lhs": {...}, "rhs": {...} },
      "confidence": "high"
    }
  ],
  "control_dependencies": [
    { "condition": "busy_i && hit_pkt_mem", "file": "...", "line": 92 }
  ]
}
```

关键字段说明：
- `ok` — 请求是否成功
- `results[].file` / `results[].line` — 源码定位
- `results[].source` — 对应源码行内容
- `results[].rhs_signals` — RHS 中引用的信号列表
- `results[].confidence` — `high`/`medium`/`low`
- `control_dependencies` — 控制该赋值的 if/case 条件

## Confidence 处理

| confidence | Agent 行为 |
|---|---|
| `high` | 直接使用作为证据 |
| `medium` | 可使用，但报告时标注置信度 |
| `low` | 必须用 Read 工具读 `file:line` 二次验证，不要直接作为结论 |

当 NPI 返回空结果时，xtrace 会通过 AST 遍历提取控制依赖作为 fallback，此时标记 `confidence=low`。

## Session Doctor 状态值

| status | 含义 |
|---|---|
| `healthy` | 一切正常 |
| `dbdir_missing` | daidir 路径不存在 |
| `dbdir_changed` | daidir 被重新编译（mtime/size 变化） |
| `process_exited` | server 进程已退出 |
| `socket_missing` | socket 文件缺失 |
| `connect_failed` | socket 存在但无法连接 |
| `ping_failed` | server 未响应 PING |

## Error Recovery

- `signal.resolve` 返回 `not_found`：用 `rg` 在 RTL 源码中搜索信号片段，确认完整路径
- Session 不健康：`session.kill` 后重新 `session.ensure`
- NPI 返回空 driver/load：属于已知限制（NPI 不支持某些过程赋值场景），使用 Read 读源码补充

## Notes / Gotchas

- daidir 必须用 `vcs -debug_access+all -kdb -lca` 编译产生
- Session 是本机资源，所有命令必须在同一台机器执行（LSF 环境注意固定机器）
- 大 design 首次 open 慢，后续 query 快
- `signal.resolve` 只接受精确 RTL 路径；短名/片段查找用外部 `rg`/grep
- 运行期状态在 `~/.xtrace/`：registry.json + sessions/<name>/
- 与 `copilot-wave-analyze` 配合：xtrace 看"代码连什么"，xwave 看"运行时取什么值"
- Interface 成员引用（`npiOperation`）和连续赋值（`npiContAssign`）均已正确处理

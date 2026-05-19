---
name: copilot-wave-analyze
description: 让 Copilot Agent 用 xwave 工具直接查询 FSDB 波形回答"信号在某时刻的值/某事务什么时候发生"类问题，避免我手开 Verdi
license: MIT
when_to_use: 当我说"帮我看 TC<N> 的波形为啥失败"或"PSLVERR 在哪一拍拉高"时
inputs:
  - FSDB 文件路径（默认 lab*/svtb/sim/novas.fsdb）
  - 信号名 / cursor / 时间点
  - 可选：spec 引用作为 expected
outputs:
  - 一段结构化总结：signal X @ time T = V，与 expected 对比
  - 建议下一步（看哪个信号、加哪个 TC）
tools:
  - xwave (/home/open_tools/xwave)
---

# Copilot: Wave Analyze via xwave

## Purpose

把"看波形"这件事从手开 Verdi GUI 变成 Agent 一条命令。Agent 用 `xwave ai query --json` 拿结构化结果，再用自然语言总结。

## Tool Location

```
/home/open_tools/xwave/tools/xwave-env <command> ...
```

## When to Use

| 我的请求 | Agent 动作 |
|---|---|
| "帮我看 TC5 PSLVERR 没拉高" | `session.open` → `value.at` → 解释 |
| "APB 第一次写 0x040 是几 ns" | `apb.query` direction=wr address=0x040 |
| "FSM 在 200ns 是什么状态" | `value.at` signal=<dut>.<fsm_reg> at=200ns |
| "找出所有 valid&&ready 的事件" | `event.export` expr="valid && ready" |
| "AXI 哪个事务延迟最大" | `axi.latency_outlier` |
| "信号在某范围内是否稳定" | `signal.stability` |

## How to Use — Agent SOP

### 1. 打开 Session

Session 必须显式命名。名字是后续所有操作的 session_id。

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"session.open","target":{"fsdb":"/path/to/novas.fsdb"},"args":{"name":"case_a"}}'
```

或用 `target.auto_open:true` 做一次性查询（自动创建临时 session）：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"value.at","target":{"fsdb":"/path/to/novas.fsdb","auto_open":true},"args":{"signal":"top.clk","time":"10ns"}}'
```

### 2. 查询信号值

单信号：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"value.at","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.PSLVERR","at":"120ns","format":"hex"}}'
```

批量信号（优先用这个代替多次 value.at）：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"value.batch_at","target":{"session_id":"case_a"},"args":{"at":"120ns","signals":["ppa_tb.dut.PSLVERR","ppa_tb.dut.busy_o","ppa_tb.dut.PENABLE"],"format":"hex"}}'
```

### 3. 使用 Cursor 标记关键时间

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"cursor.set","target":{"session_id":"case_a"},"args":{"name":"fail_point","time":"120340ns","note":"PSLVERR should be high here"}}'
```

后续查询可用 cursor 引用：`@fail_point`、`@fail_point-20ns`、`@fail_point+5cycle(top.clk)`

### 4. 信号发现（SIGNAL_NOT_FOUND 时用）

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"scope.list","target":{"session_id":"case_a"},"args":{"path":"ppa_tb.dut","recursive":true},"limits":{"max_rows":200}}'
```

### 5. APB 事务查询

先加载配置：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"apb.config.load","target":{"session_id":"case_a"},"args":{"name":"apb0","config_path":"apb.json"}}'
```

查写事务：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"apb.query","target":{"session_id":"case_a"},"args":{"name":"apb0","direction":"wr","address":"0x040","num":3}}'
```

### 6. AXI 事务查询

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"axi.config.load","target":{"session_id":"case_a"},"args":{"name":"axi0","config_path":"axi.json"}}'
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"axi.analysis","target":{"session_id":"case_a"},"args":{"name":"axi0","analysis":"latency","direction":"all"}}'
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"axi.channel_stall","target":{"session_id":"case_a"},"args":{"name":"axi0","channel":"r","time_range":{"begin":"40us","end":"45us"},"rules":{"max_wait_cycles":16}}}'
```

### 7. 通用事件查询

先加载 event config：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"event.config.load","target":{"session_id":"case_a"},"args":{"name":"if0","config_path":"if0.event.json"}}'
```

找第一个匹配事件：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"event.find","target":{"session_id":"case_a"},"args":{"name":"if0","expr":"valid && !ready","time_range":{"begin":"0ns","end":"100us"}}}'
```

导出/聚合事件：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"event.export","target":{"session_id":"case_a"},"args":{"name":"if0","expr":"valid && ready","time_range":{"begin":"0ns","end":"100us"},"aggregate":{"count":true,"group_by":["qid"],"events":false}}}'
```

### 8. 验证与分析

条件验证：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"verify.conditions","target":{"session_id":"case_a"},"args":{"time":"42us","conditions":[{"signal":"ppa_tb.dut.busy_o","op":"==","value":"1"}]}}'
```

窗口验证（always/never/eventually）：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"window.verify","target":{"session_id":"case_a"},"args":{"clock":"ppa_tb.clk","sampling":"posedge","time_range":{"begin":"42us","end":"44us"},"conditions":[{"expr":"valid && !ready","signals":{"valid":"ppa_tb.dut.valid","ready":"ppa_tb.dut.ready"},"mode":"always"}]}}'
```

信号统计：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"signal.statistics","target":{"session_id":"case_a"},"args":{"signal":"ppa_tb.dut.ready","clock":"ppa_tb.clk","sampling":"posedge","time_range":{"begin":"0ns","end":"100us"},"max_samples":1000000}}'
```

Handshake 检查：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"handshake.inspect","target":{"session_id":"case_a"},"args":{"clock":"ppa_tb.clk","valid":"ppa_tb.dut.valid","ready":"ppa_tb.dut.ready","data":["ppa_tb.dut.data"],"time_range":{"begin":"40us","end":"45us"},"rules":{"max_wait_cycles":100,"check_data_stable_when_stalled":true}}}'
```

异常检测：

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"detect_anomaly","target":{"session_id":"case_a"},"args":{"signals":["ppa_tb.dut.ready","ppa_tb.dut.valid"],"time_range":{"begin":"0ns","end":"100us"},"checks":[{"type":"glitch","min_pulse_width":"1ns"},{"type":"stuck","min_duration":"1us"},{"type":"unknown_xz"}],"max_findings":50}}'
```

### 9. 清理 Session

```bash
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"session.kill","args":{"id":"case_a"}}'
```

## TimeSpec 语法

所有时间字段接受以下格式：

| 格式 | 含义 |
|---|---|
| `100ns` / `42us` / `1ps` | 绝对时间（支持 us/ns/ps/fs，无单位默认 ns） |
| `@deadlock` | 已保存 cursor |
| `@deadlock-20ns` | cursor 减时间偏移 |
| `@deadlock+5cycle(top.clk)` | cursor 加时钟周期偏移 |
| `@-10ns` / `@+5ns` | active cursor 偏移 |
| `@deadlock-2negedge(top.clk)` | cursor 减 negedge 周期 |

时间转换在 daemon 侧完成，基于 FSDB 实际 time scale。

## AI JSON Response 解析规则

- 始终检查 `ok` 字段；`ok:false` 时不使用 `data` 作为证据
- compact 输出省略 `tool`、`session`、空 `warnings`、空 `suggested_next_actions`、`meta.elapsed_ms`
- value 对象格式：`{"value":"'h12","known":true}`；`known:false` 表示含 x/z
- 用 `format` 字段控制值格式：`hex`/`binary`/`decimal`/`auto`
- 遇到 `SIGNAL_NOT_FOUND` 时用 `scope.list` 发现正确路径

## Error Recovery

| error.code | 处理方式 |
|---|---|
| `SIGNAL_NOT_FOUND` | 用 `scope.list` 搜索正确路径 |
| `SESSION_NOT_FOUND` | 用 `session.list` 或重新 `session.open` |
| `INVALID_REQUEST` | 修正 JSON 请求 |
| `EXPR_PARSE_FAILED` | 简化或校验别名 |

## Performance Best Practices

- 优先 `value.batch_at` 代替多次 `value.at`
- 优先 `event.find` 再 `event.export`
- 优先 `signal.statistics` 代替导出事件后手动计数
- 优先 `event.export` + `aggregate.events:false` 做聚合
- 优先 `signal.stability` 再 `signal.changes`
- 用 `limits.max_rows/max_events/max_samples` 限制扫描范围

## Example Workflow

我："TC8 失败：busy=1 期间写 PKT_MEM 应该 PSLVERR=1 但 log 显示 0"

Agent：
```bash
# 1. 打开 session
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"session.open","target":{"fsdb":"lab1/svtb/sim/novas.fsdb"},"args":{"name":"tc8"}}'

# 2. 找 busy 拉高的时间
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"event.find","target":{"session_id":"tc8"},"args":{"name":"ctrl","expr":"busy","time_range":{"begin":"0ns","end":"500us"}}}'

# 3. 设置 cursor
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"cursor.set","target":{"session_id":"tc8"},"args":{"name":"busy_start","time":"<found_time>"}}'

# 4. 查 APB 写事务
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"apb.query","target":{"session_id":"tc8"},"args":{"name":"apb0","direction":"wr","address":"0x040","num":1}}'

# 5. 验证 PSLVERR
/home/open_tools/xwave/tools/xwave-env ai query --json '{"api_version":"xwave.ai.v1","action":"value.at","target":{"session_id":"tc8"},"args":{"signal":"ppa_tb.dut.PSLVERR","at":"@busy_start+1cycle(ppa_tb.clk)","format":"hex"}}'
```

返回："APB 写 0x044 @ 235ns，下一拍 PSLVERR=0。RTL 缺少 `busy_i & hit_pkt_mem & PWRITE → PSLVERR=1` 这条 case。建议查 ppa_apb_slave_if.sv 中 PSLVERR 组合逻辑。"

## Notes / Gotchas

- 必须先用 `$fsdbDumpvars(0, ppa_tb)` dump 全层级
- Session 名字最长 256 字符，可含字母/数字/`_`/`.`/`-`；重名会返回 `SESSION_ID_EXISTS`
- daemon idle timeout 默认 1800 秒；长交互用 `export XWAVE_IDLE_TIMEOUT_SEC=28800`
- 大 FSDB（>1GB）首次 open 慢（受 `XWAVE_SESSION_START_TIMEOUT_SEC` 限制，默认 60s），后续 query 快
- 不要让 Agent 直接读 FSDB 二进制 — 必须经 xwave
- 运行期状态在 `~/.xwave/`：registry.json + sessions/<hash>/
- 与 copilot-rtl-trace 配合：xwave 看"运行时取什么值"，xtrace 看"代码连什么"

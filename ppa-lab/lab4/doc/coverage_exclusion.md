# 覆盖率过滤登记表 (Coverage Exclusion Registry)

> Spec §11.5 选做 #4 — 逐条登记合法排除项，说明排除原因和 Spec 依据

## 排除项列表

| ID | 模块 | 信号/代码行 | 覆盖率类型 | 排除原因 | Spec 依据 |
|----|------|------------|-----------|---------|-----------|
| EX-01 | ppa_apb_slave_if | `PREADY` (line 65: `assign PREADY = 1'b1`) | Toggle | PREADY 硬连线 1，设计意图为无等待状态 APB 从机，永远不会翻转为 0 | Spec §4: "PREADY 固定为 1，无等待状态" |
| EX-02 | ppa_apb_slave_if | `PADDR[11:7]` | Toggle | 地址空间仅到 0x05C（PKT_MEM 最高地址），PADDR 高 5 位在合法访问中永远为 0 | Spec §2.3 M1 端口表: PADDR[11:0]，实际寄存器空间 0x000~0x05C |
| EX-03 | ppa_packet_proc_core | `default: state <= S_IDLE` (line 243) | Branch, Statement | FSM 仅有 3 个合法状态 (S_IDLE=0, S_PROCESS=1, S_DONE=2)，2-bit state_t 编码下 state=2'd3 结构性不可达 | Spec §7.1: 三态 FSM (IDLE/PROCESS/DONE) |

## 排除方法

### 方法 A: Questa exclude file (.do)

创建 `lab4/svtb/sim/cov_exclude.do` 后在 `vcover report` 时使用 `-excl cov_exclude.do`：

```tcl
# EX-01: PREADY hardwired to 1
coverage exclude -src /ppa_apb_slave_if/ -toggle PREADY

# EX-02: PADDR[11:7] unused address space
coverage exclude -src /ppa_apb_slave_if/ -toggle {PADDR[11]} {PADDR[10]} {PADDR[9]} {PADDR[8]} {PADDR[7]}

# EX-03: FSM default branch unreachable
coverage exclude -src /ppa_packet_proc_core/ -line 243 -code bs
```

### 方法 B: 注释标注（仅用于审查记录，不影响工具统计）

在 RTL 源码中用 `// coverage off` / `// coverage on` 标注（需重新编译生效）。

## 预估影响

| 排除项 | Toggle 影响 | Branch 影响 | Statement 影响 |
|--------|------------|------------|---------------|
| EX-01 | 减少 2 miss bins (PREADY 0→1, 1→0 各一) | — | — |
| EX-02 | 减少 10 miss bins (5 bit × 2 direction) | — | — |
| EX-03 | — | 减少 1 miss bin | 减少 1 miss bin |
| **合计** | ~+0.5% Toggle | ~+0.5% Branch | ~+0.2% Statement |

> 注: 排除项的实际影响取决于合并后总 bin 数。以上为保守估计。

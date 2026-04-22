# Lab1 设计日志

> 项目：PPA-Lite APB 包处理加速器精简版
> 阶段：Lab1 — APB 从接口 + SRAM
> 日期：2026-04-21
> 工具：QuestaSim 2021.1 win64
> 仿真结果：18 PASS / 0 FAIL

---

## 1 本次目标

| 编号 | 目标 | 完成情况 |
|------|------|---------|
| 1 | 实现 APB 3.0 从接口模块 `ppa_apb_slave_if`（M1） | Done |
| 2 | 实现 8x32-bit 双端口同步 SRAM 模块 `ppa_packet_sram`（M2） | Done |
| 3 | 搭建 SV TB 骨架，完成基础读写验证 | Done |

---

## 2 文件清单

| 文件路径 | 说明 | 行数 |
|----------|------|------|
| `rtl/ppa_apb_slave_if.sv` | APB 从接口 + CSR 寄存器组 | 273 |
| `rtl/ppa_packet_sram.sv` | 8x32-bit 双端口同步 SRAM | 52 |
| `svtb/tb/ppa_tb.sv` | TB 骨架（TC1~TC3） | 325 |
| `svtb/sim/Makefile` | 仿真编译/运行入口 | 31 |

---

## 3 设计要点记录

### 3.1 M1：ppa_apb_slave_if

**APB 协议实现**
- 两段式传输：SETUP（PSEL=1, PENABLE=0）→ ACCESS（PSEL=1, PENABLE=1）
- `PREADY` 固定为 1，无等待状态
- 写有效判定：`apb_write = PSEL & PENABLE & PWRITE`
- 读有效判定：`apb_read = PSEL & PENABLE & ~PWRITE`

**地址空间划分**

| 地址范围 | 用途 | 访问规则 |
|---------|------|---------|
| 0x000~0x028 | CSR 区（11 个寄存器） | 按属性读写 |
| 0x02C~0x03F | 保留 | PSLVERR=1 |
| 0x040~0x05C | PKT_MEM 窗口（8 word） | busy=0 可写，busy=1 写返回 PSLVERR=1 |
| 0x060+ | 未定义 | PSLVERR=1 |

**CSR 寄存器设计**
- 共 11 个寄存器，四种属性：RW / RO / W1P / RW1C
- `CTRL.start`（W1P）：写 1 产生单拍脉冲，需 `enable=1 && busy=0` 才接受，读回恒 0
- `IRQ_STA`（RW1C）：写 1 清零对应位，写 0 无效
- `STATUS / RES_* / ERR_FLAG`（RO）：组合逻辑直透，写入返回 PSLVERR=1
- `CFG` 复位值：`algo_mode=1, type_mask=4'b1111`（对应 PRDATA=0x000000F1）

**PSLVERR 统一错误响应**
- 三种触发场景：写 RO 寄存器 / 访问未定义地址 / busy 期间写 PKT_MEM
- 组合逻辑实现，无时序延迟

**PKT_MEM 写入路径**
- 地址映射：`pkt_mem_addr_o = PADDR[4:2]`（等价于 `(PADDR - 0x040) >> 2`）
- 写使能：`pkt_mem_we_o = apb_write && is_pkt_mem && !busy_i`
- 写数据透传：`pkt_mem_wdata_o = PWDATA`

**IRQ 实现**
- `done_rising = done_i & ~done_i_d`（上升沿检测）
- `done_irq`：done 上升沿 + done_irq_en 门控
- `err_irq`：done 上升沿 + 任意错误有效 + err_irq_en 门控
- `irq_o = reg_done_irq | reg_err_irq`（组合输出）
- RW1C 清除与中断置位采用 if-else 互斥结构，写入优先于置位

### 3.2 M2：ppa_packet_sram

- 8x32-bit 存储体：`logic [31:0] mem [0:7]`
- 同步写：`always_ff @(posedge clk)` + `wr_en` 门控
- 同步读：`always_ff @(posedge clk)` + `rd_en` 门控
- 异步复位清零所有存储单元
- 不含包语义逻辑，纯存储模块

### 3.3 设计决策备忘

| 决策 | 理由 |
|------|------|
| PRDATA 采用组合逻辑输出 | Spec 无 PREADY 等待需求，组合读简化时序，一拍完成读操作 |
| PKT_MEM APB 读返回固定 0 | Lab1 暂不连接 M2 读端口，Lab3 集成时补充 |
| 端口名增加 `_o`/`_i` 后缀 | 保持 RTL 命名一致性，Spec 端口名无后缀但语义一致 |
| IRQ 写清与置位互斥 | 避免同拍写清和置位竞争，写入优先保证软件清除的确定性 |

---

## 4 TB 设计与仿真结果

### 4.1 TB 架构

- 时钟：10ns 周期（`always #5 PCLK = ~PCLK`）
- 复位：5 个时钟周期低电平复位，2 个时钟周期稳定后开始测试
- APB Task：`apb_write` / `apb_read` 实现标准两段式传输
- 自动化检查：`check` task 比较实际值与期望值，累计 PASS/FAIL 计数
- M3 状态输入：使用 stub 信号模拟

### 4.2 Testcase 覆盖

| TC | 名称 | 对应验收项 | 检查点 | 结果 |
|----|------|-----------|--------|------|
| TC1 | CSR 默认值检查 | 必做 1 | 11 个 CSR 寄存器复位值 | **11/11 PASS** |
| TC2 | PKT_MEM 写入映射 | 必做 2 | 8 word 连续写入 + M2 回读 | **PASS（波形验证）** |
| TC3 | RES_* 读通路 | 必做 3 | 4 个 RES 寄存器 + STATUS + ERR_FLAG | **6/6 PASS** |

### 4.3 仿真运行

```
make comp    # vlog 编译通过，无 warning
make rung    # QuestaSim GUI 模式运行
```

仿真在 1015ns 完成，输出：

```
PASS: 18
FAIL: 0
ALL TESTS PASSED
```

### 4.4 波形截图

| 文件 | 时间范围 | 观察内容 |
|------|---------|---------|
| `wave/Wave_0-500ns_2026-04-21_23-25-03.png` | 0~500ns | 复位序列、TC1 CSR 默认值读操作 |
| `wave/Wave_500ns-1000ns_2026-04-21_23-25-03.png` | 500~1000ns | TC2 PKT_MEM 写入序列、TC3 RES_* 读通路 |

---

## 5 验收项完成情况

### 必做项

| 编号 | 描述 | 状态 |
|------|------|------|
| 1 | APB 基础读写时序正确（CSR 默认值正确） | PASS |
| 2 | PKT_MEM 写入地址映射正确（wr_en/wr_addr/wr_data 波形匹配） | PASS |
| 3 | RES_* 寄存器读通路正确（stub 赋值后 APB 读回一致） | PASS |

### 选做项

| 编号 | 描述 | RTL 状态 | TB 状态 |
|------|------|---------|---------|
| 4 | PSLVERR 统一错误响应 | 已实现 | 未覆盖 |
| 5 | IRQ 寄存器完整实现 | 已实现 | 未覆盖 |

---

## 6 已知限制

| 编号 | 描述 | 影响 | 后续计划 |
|------|------|------|---------|
| L-1 | PKT_MEM APB 读返回固定 0 | 无法通过 APB 读回 SRAM 内容 | Lab3 集成时连接 M2 读端口 |
| L-2 | M3 未实现，TB 使用 stub 替代 | 无法测试端到端处理流程 | Lab2 实现 M3，Lab3 集成 |
| L-3 | TC2 SRAM 回读未做自动化断言 | 依赖波形目视检查 | 验证阶段补充 check() |

---

## 7 下一步计划（验证阶段）

- [ ] TC2 补充自动化 SRAM 回读断言
- [ ] 新增 TC4：PSLVERR 场景测试（写 RO / 未定义地址 / busy 写 PKT_MEM）
- [ ] 新增 TC5：IRQ 完整路径测试（使能 → 触发 → irq_o=1 → 清除 → irq_o=0）
- [ ] 补充 CSR 写后读回测试
- [ ] 补充 start 脉冲行为测试（enable=0 不接受 / enable=1 && busy=0 产生单拍脉冲）

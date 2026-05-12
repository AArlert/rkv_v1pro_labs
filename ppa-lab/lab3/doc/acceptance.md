# Lab3 验收标准 (Acceptance Criteria)

## 必做验收项

| # | 验收内容 | 判定方法 | 状态 |
|---|----------|----------|------|
| 1 | 端到端链路完整 | APB 写合法 8B packet → start → 轮询 done=1 → APB 读 RES_PKT_LEN=8, RES_PKT_TYPE=0x02 | PENDING |
| 2 | 连续两帧顺序处理 | 第一帧 done 后写第二帧 → start → done=1 → 两帧 RES_PKT_LEN 各不相同且均正确 | PENDING |
| 3 | STATUS 总线通路 | busy=1 时 STATUS[1:0]=2'b01；done=1 时 STATUS[1:0]=2'b10 | PENDING |

## 选做验收项

| # | 验收内容 | 判定方法 | 依赖 | 状态 |
|---|----------|----------|------|------|
| 4 | busy 期间写 PKT_MEM 保护 | busy=1 写 PKT_MEM → PSLVERR=1 且 SRAM 内容不变 | Lab1 选做 4 | PENDING |
| 5 | 中断路径闭环 | done_irq_en=1 → done 触发 irq_o=1 → APB 清 IRQ_STA → irq_o=0 | Lab1 选做 5 | PENDING |

## 验证命令

```bash
cd ppa-lab/lab3/svtb/sim
make comp    # 编译 0 error
make run     # TC1~TC3 全 PASS
```

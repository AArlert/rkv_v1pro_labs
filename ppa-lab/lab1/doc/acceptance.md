# Lab1 Acceptance Matrix

| ID | 验收项 | spec 来源 | 可执行判据 | 当前证据 | 状态 |
| --- | --- | --- | --- | --- | --- |
| A-L1-01 | APB 基础读写时序正确 | §4.1 | `make run` PASS，log 中 TC1/TC3 无 FAIL，波形 SETUP→ACCESS 正确 | `log.md` 2.11 | DONE |
| A-L1-02 | CSR 默认值正确 | §5.2 | 复位后读 CTRL/CFG/STATUS/IRQ/RES/ERR_FLAG 等值匹配 spec | `log.md` 2.4/2.11 | DONE |
| A-L1-03 | PKT_MEM 写入地址映射正确 | §6.1/§6.2 | 写 8 word 后程序化比对 M2 对应地址数据 | `log.md` 2.9/2.11；自动比对待补 | WIP |
| A-L1-04 | RES_* 读通路正确 | §5.2 | stub 赋值后 APB 读回一致 | `log.md` 2.11 TC3 | DONE |
| A-L1-05 | PSLVERR/IRQ 选做路径 | §8.2/§8.3/§9.3 | 写 RO、越界地址、IRQ_EN/IRQ_STA/irq_o testcase PASS | 待补 testcase | TODO |

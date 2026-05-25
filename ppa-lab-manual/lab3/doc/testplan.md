# lab3 testplan

| TC ID | 文件 | 目的 | spec 引用 | 必做/选做 | 状态 |
|---|---|---|---|---|---|
| TC-L3-01 | `verif/tests/e2e_smoke_test.sv` | 写合法 packet → start → 轮询 done → 读 RES_* | §10.1 N-1/N-2 + §11.4 必做1 | 必做 | ⬜ |
| TC-L3-02 | `verif/tests/two_frames_test.sv` | 连续两帧顺序处理；done 间清零 | §10.1 N-4 + §11.4 必做2 | 必做 | ⬜ |
| TC-L3-03 | `verif/tests/status_path_test.sv` | busy=1→STATUS[1:0]=01；done=1→STATUS[1:0]=10 | §11.4 必做3 | 必做 | ⬜ |
| TC-L3-04 | `verif/tests/pslverr_busy_test.sv`（选做） | busy 期间写 PKT_MEM 返回 PSLVERR | §10.3 B-2 + §11.4 选做4 | 选做 | ⬜ |
| TC-L3-05 | `verif/tests/irq_loop_test.sv`（选做） | done_irq_en=1 → irq_o=1 → 清除 → irq_o=0 | §10.3 B-3 + §11.4 选做5 | 选做 | ⬜ |

## check-point

- CK-1: 端到端 RES_PKT_LEN/TYPE 读回 = 写入预期
- CK-2: 第二帧不受第一帧污染
- CK-3: STATUS 实时反映 busy/done

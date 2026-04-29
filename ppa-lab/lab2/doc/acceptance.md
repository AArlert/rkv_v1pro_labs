# Lab2 Acceptance Matrix

| ID | 验收项 | spec 来源 | 可执行判据 | 当前证据 | 状态 |
| --- | --- | --- | --- | --- | --- |
| A-L2-01 | 合法包完整处理 | §3/§7/§10.1 | TC1 PASS：done_o=1、format_ok_o=1、res_pkt_len/type/sum/xor 正确 | `testplan.md` TC1; `log.md` 2.13 | DONE |
| A-L2-02 | 长度越界检测 | §3.2/§9/§10.2 | pkt_len=3/33 PASS，M3 不死锁；exp_pkt_len_i 非零 testcase 待补 | `testplan.md` TC2a/TC2b; `log.md` 2.13 | WIP |
| A-L2-03 | busy/done 时序 | §7/§8.1 | 连续两帧：start 后 busy、DONE 保持、再次 start 清 done | `testplan.md` TC3; `log.md` 2.13 | DONE |
| A-L2-04 | 类型合法性检查 | §3.1/§9/§10.2 | 非 one-hot 与 type_mask 屏蔽均 type_error=1 | `testplan.md` TC4a/TC4b; `log.md` 2.13 | DONE |
| A-L2-05 | hdr_chk 与 algo_mode | §3.1/§9/§10.2 | algo_mode=1 检查 hdr_chk；algo_mode=0 旁路 | `testplan.md` TC5a/TC5b; `log.md` 2.13 | DONE |
| A-L2-06 | payload sum/xor | §3.4/§7.3 | payload={1,2,3,4} sum/xor 正确 | `testplan.md` TC5c; `log.md` 2.13 | DONE |

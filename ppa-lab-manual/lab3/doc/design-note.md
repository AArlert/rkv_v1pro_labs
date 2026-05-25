# lab3 design-note — ppa_top

> spec 明确要求 ppa_top 为 "薄层连线，无状态逻辑"（§2.1, §2.2）。
> 如果本设计在 ppa_top 内引入了任何 always_ff / 状态机 → REV 必然 P0。

## 1 设计原则

- 只连线，不存状态
- 统一 PCLK/PRESETn 分发到 M1/M2/M3
- M1 ↔ M2 写端口、M3 ↔ M2 读端口、M1 ↔ M3 控制/结果

## 2 端口清单（spec §2.3 Top 表）

- [ ] PCLK / PRESETn
- [ ] PSEL / PENABLE / PWRITE / PADDR[11:0] / PWDATA[31:0]
- [ ] PRDATA[31:0] / PREADY / PSLVERR
- [ ] irq_o

## 3 连线关系

```
M1.pkt_mem_we_o     →  M2.wr_en
M1.pkt_mem_addr_o   →  M2.wr_addr
M1.pkt_mem_wdata_o  →  M2.wr_data
M3.mem_rd_en_o      →  M2.rd_en
M3.mem_rd_addr_o    →  M2.rd_addr
M2.rd_data          →  M3.mem_rd_data_i
M1.start_o          →  M3.start_i
M1.enable_o         →  (gating，按 spec 决定是否屏蔽 start_o)
M1.algo_mode_o      →  M3.algo_mode_i
M1.type_mask_o      →  M3.type_mask_i
M1.exp_pkt_len_o    →  M3.exp_pkt_len_i
M3.busy_o           →  M1.busy_i
M3.done_o           →  M1.done_i
M3.res_*_o          →  M1.res_*_i
M3.format_ok_o ...  →  M1.*_i
M1.irq_o            →  top.irq_o
```

---
name: manual-wavedrom-usage
description: WaveDrom GUI 本地工具使用手册 — 交互式时序图编辑器
license: MIT
when_to_use: 需要绘制/编辑数字时序图、生成 WaveJSON、导出 SVG 波形图时
inputs: []
outputs: [WaveJSON, SVG]
tools: [wavedrom-gui, serve, node]
---

# WaveDrom GUI 使用手册

## 工具概述

WaveDrom GUI 是一个基于浏览器的交互式数字波形编辑器，部署在本机 `/home/open_tools/wavedrom-gui`。支持可视化编辑时序图，实时预览 SVG 输出，并可导出 WaveJSON 代码和 SVG 文件。

---

## 启动方式

### 快速启动（推荐）
```bash
cd /home/open_tools/wavedrom-gui
sudo npm run dev
# 浏览器访问 http://localhost:5173
```

### 生产模式
```bash
serve /home/open_tools/wavedrom-gui/dist -p 5173
# 浏览器访问 http://localhost:5173
```

### 后台运行
```bash
nohup serve /home/open_tools/wavedrom-gui/dist -p 5173 > /tmp/wavedrom-gui.log 2>&1 &
```

---

## 界面布局

三栏式布局，可拖拽调整宽度：

| 面板 | 位置 | 功能 |
|------|------|------|
| Signal Editor | 左 | 可视化信号编辑区，支持点击/拖拽/右键菜单 |
| Code Editor | 中 | Monaco 编辑器，直接编辑 WaveJSON |
| Preview | 右 | 实时 SVG 波形预览 |

---

## 核心操作

### 信号编辑
- **点击信号格子**: 循环切换状态 `0 → 1 → x → z → = → ·`
- **拖拽信号行**: 上下重新排序
- **右键信号名**: 复制、上移、下移、删除

### 单元格右键菜单
- 设置任意值
- Fill-all 快捷操作
- 插入/删除 cycle（带 shift）

### 导出
- **Export SVG**: 下载渲染后的 `.svg` 文件
- **Copy Code**: 将 WaveJSON 复制到剪贴板

### 主题
- Header 栏有 Dark/Light 模式切换

---

## WaveJSON 信号字符表

| 字符 | 含义 | 典型用途 |
|------|------|----------|
| `0` | 逻辑低 | 常规信号低电平 |
| `1` | 逻辑高 | 常规信号高电平 |
| `x` | 未定义/Don't-care | 复位前、无效数据 |
| `z` | 高阻态 | 三态总线 |
| `=` | 总线/向量（默认色） | 数据信号 |
| `2`–`9` | 总线（不同颜色） | 区分多个数据段 |
| `.` | 延续前一状态 | 保持当前值 |
| `p` / `P` | 上升沿时钟 (P=带箭头) | 时钟信号 |
| `n` / `N` | 下降沿时钟 (N=带箭头) | 反相时钟 |
| `h` / `l` | 保持高/保持低 | 持续电平 |

---

## 配置选项（Header 栏可调）

| 选项 | 值范围 | 效果 |
|------|--------|------|
| `hscale` | 1–10 | 水平缩放倍数 |
| `skin` | `default`, `narrow`, `light` | SVG 渲染皮肤 |

---

## 常用 WaveJSON 模板

### APB 读写时序
```json
{ "signal": [
  { "name": "PCLK",    "wave": "p........" },
  { "name": "PSEL",    "wave": "01..01..0" },
  { "name": "PENABLE", "wave": "0.1.0.1.0" },
  { "name": "PWRITE",  "wave": "0.1.0.0.0" },
  { "name": "PADDR",   "wave": "x.=.x.=.x", "data": ["0x00", "0x04"] },
  { "name": "PWDATA",  "wave": "x.=.x...x", "data": ["0xAB"] },
  { "name": "PRDATA",  "wave": "x...x.=.x", "data": ["0xCD"] },
  { "name": "PREADY",  "wave": "0..10..10" }
]}
```

### 简单握手协议
```json
{ "signal": [
  { "name": "clk",   "wave": "p........" },
  { "name": "valid", "wave": "0.1..0..." },
  { "name": "ready", "wave": "0...10..." },
  { "name": "data",  "wave": "x.===x...", "data": ["D0", "D1", "D2"] }
]}
```

### 时钟分频
```json
{ "signal": [
  { "name": "clk_in",  "wave": "p.........." },
  { "name": "clk_div2","wave": "0.1.0.1.0.1" },
  { "name": "clk_div4","wave": "0...1...0.." }
]}
```

---

## 典型工作流

### 1. 从零画图
1. 启动 `npm run dev`
2. 在左侧面板添加信号，命名
3. 点击格子设置状态序列
4. 调整 hscale 和 skin
5. Export SVG 或 Copy Code

### 2. 从已有 WaveJSON 编辑
1. 启动工具
2. 在中间 Monaco 编辑器粘贴 WaveJSON
3. 左侧和右侧自动同步更新
4. 可视化微调后导出

### 3. 配合文档使用
1. 在工具中完成波形编辑
2. Export SVG 保存到项目 `docs/` 目录
3. 在 Markdown 文档中引用：`![timing](docs/timing.svg)`

---

## 故障排除

### 启动失败
```bash
# 检查端口是否被占用
lsof -i :5173
# 杀掉占用进程
kill -9 <PID>
```

### Monaco 编辑器空白
- 可能是网络问题（Monaco 从 CDN 加载 worker）
- 开发模式下通常正常；生产模式若离线可能受影响
- 波形渲染面板不受影响

### 修改后不同步
- WaveJSON 有语法错误时，GUI 冻结在最后有效状态
- 检查中间面板是否有红色错误提示
- 修正 JSON 后自动恢复

---

## 与 xwave 的区别

| 维度 | wavedrom-gui | xwave |
|------|-------------|-------|
| 输入源 | 手动编辑 WaveJSON | 读取 FSDB 仿真波形 |
| 用途 | 设计文档、协议图示 | 调试仿真波形 |
| 输出 | SVG/WaveJSON | 交互式波形查看 |
| 依赖 | Node.js + 浏览器 | Verdi NPI 库 |
| 场景 | spec 撰写、Review 演示 | 仿真调试、信号追踪 |

---

## 部署信息

- **安装位置**: `/home/open_tools/wavedrom-gui`
- **部署日志**: `ppa-lab-copilot/tools/wavedrom-gui-deployment-log.md`
- **Node.js 要求**: >= 18.0
- **端口**: 默认 5173

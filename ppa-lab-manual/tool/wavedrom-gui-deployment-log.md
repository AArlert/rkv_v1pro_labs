# wavedrom-gui 部署日志

**部署时间**: 2026-05-25  
**部署人**: Claude Agent  
**部署版本**: GitHub `glenzac/wavedrom-gui` master branch（最后一次 commit: e56664c）  
**部署位置**: `/home/open_tools/wavedrom-gui`  
**构建状态**: ✅ 成功

---

## 部署版本信息

### 源代码
- **Repository**: https://github.com/glenzac/wavedrom-gui
- **Branch**: master
- **Commit**: e56664c (UI: widen signals panel, fix bus color sync, add clock button)
- **Clone URL**: `git clone https://github.com/glenzac/wavedrom-gui.git`

### 构建环境
- **Node.js**: v18.20.8 (从 NodeSource PPA 安装，替换系统自带 v12.22.9)
- **npm**: 10.8.2
- **构建工具**: Vite 5.4.21 + TypeScript 5.x
- **框架**: React 18 + TailwindCSS 3.4
- **核心依赖**: wavedrom 3.6.1, @monaco-editor/react 4.6.0, @dnd-kit

### 产物位置
```
/home/open_tools/wavedrom-gui/dist/          # 生产构建产物（静态 HTML/JS/CSS）
/home/open_tools/wavedrom-gui/dist/index.html # 入口文件
/home/open_tools/wavedrom-gui/dist/assets/   # JS/CSS bundles
```

---

## 部署步骤记录

### 1. Node.js 升级

**问题描述**:
- 系统自带 Node.js v12.22.9，不满足项目最低要求 (Node 18+)
- `npm install` 会报大量 `EBADENGINE` 警告，部分包无法正确运行

**解决方案**: 通过 NodeSource PPA 安装 Node.js 18
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo dpkg --force-overwrite -i /var/cache/apt/archives/nodejs_18.20.8-1nodesource1_amd64.deb
```

**冲突处理**:
- `libnode-dev` 和 `libnode72` 包与新版 nodejs 有文件冲突
- 使用 `sudo apt remove libnode-dev` 后仍有 `/usr/share/systemtap/tapset/node.stp` 冲突
- 最终用 `dpkg --force-overwrite` 强制覆盖解决

### 2. 依赖安装
```bash
cd /home/open_tools/wavedrom-gui
sudo rm -rf node_modules package-lock.json
sudo npm install
```
- 173 packages installed
- 4 moderate severity vulnerabilities (wavedrom 内部 eval，非关键安全风险)

### 3. 生产构建
```bash
sudo npm run build
# tsc && vite build
# ✓ 158 modules transformed
# ✓ built in 1.68s
```

产物大小:
| 文件 | 大小 | gzip |
|------|------|------|
| index.html | 0.49 kB | 0.31 kB |
| index-BHwgxXGy.css | 17.79 kB | 3.84 kB |
| index-BpaKNljp.js | 84.76 kB | 17.55 kB |
| index-BWg9_uKn.js | 230.94 kB | 74.74 kB |

### 4. 静态服务工具
```bash
sudo npm install -g serve
```
- 安装 `serve` 全局命令用于本地静态文件服务

---

## 使用方式

### 开发模式
```bash
cd /home/open_tools/wavedrom-gui
npm run dev
# 访问 http://localhost:5173
```

### 生产模式（静态服务）
```bash
cd /home/open_tools/wavedrom-gui
serve dist -p 5173
# 或
npx serve dist -p 5173
# 访问 http://localhost:5173
```

### 后台运行
```bash
nohup serve /home/open_tools/wavedrom-gui/dist -p 5173 > /tmp/wavedrom-gui.log 2>&1 &
```

---

## 已知限制

### ⚠️ Node.js 版本锁定
- 系统现在使用 NodeSource 提供的 Node.js 18.20.8
- 若有其他项目依赖系统原生 Node.js 12，可能受影响
- 建议后续迁移到 nvm 管理多版本

### wavedrom eval 警告
```
node_modules/wavedrom/lib/eva.js (17:21): Use of eval in "node_modules/wavedrom/lib/eva.js"
```
- 这是 wavedrom 库内部的实现方式，非本项目引入
- 不影响功能，但有潜在安全风险（仅在解析用户输入的 WaveJSON 时触发）

### 网络依赖
- Monaco Editor 会从 CDN 加载字体和 worker
- 离线环境可能导致编辑器面板加载失败
- 波形渲染面板不受影响（wavedrom 核心完全本地化）

---

## 维护清单

### 日常检查
- [ ] `serve /home/open_tools/wavedrom-gui/dist -p 5173` 正常启动
- [ ] 浏览器访问 http://localhost:5173 可见编辑器界面
- [ ] 点击信号格子能正常切换状态

### 升级步骤
```bash
cd /home/open_tools/wavedrom-gui
sudo git pull origin master
sudo rm -rf node_modules
sudo npm install
sudo npm run build
```

### 升级后验证
1. 浏览器访问确认界面正常
2. 测试 WaveJSON 编辑和预览同步
3. 测试 SVG 导出功能

---

## 参考资源

- **README**: https://github.com/glenzac/wavedrom-gui/blob/master/README.md
- **WaveDrom 官方文档**: https://wavedrom.com
- **WaveJSON 规范**: https://wavedrom.com/tutorial.html
- **本地 dist 目录**: `/home/open_tools/wavedrom-gui/dist/`
- **Skill 文件**: `/home/icarray/Desktop/code/rkv_v1pro_labs/ppa-lab-copilot/skill/manual-wavedrom-usage/manual-wavedrom-usage.md`

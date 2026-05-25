# xwave 部署日志

**部署时间**: 2026-05-24  
**部署人**: Claude Agent  
**部署版本**: GitHub `BLANK2077/xwave` master branch（最后一次 commit: a7271bb）  
**部署位置**: `/home/open_tools/xwave`  
**构建状态**: ✅ 成功

---

## 部署版本信息

### 源代码
- **Repository**: https://github.com/BLANK2077/xwave
- **Branch**: master
- **Commit**: a7271bb (md format update)
- **Clone URL**: `git clone https://github.com/BLANK2077/xwave.git`

### 构建环境
- **GCC**: 11.4.0 (C++11 支持)
- **VERDI_HOME**: `/home/synopsys/verdi/Verdi_O-2018.09-SP2`
- **NPI Headers**: 
  - `$VERDI_HOME/share/NPI/inc`
  - `$VERDI_HOME/share/NPI/L1/C/inc`
- **NPI Libraries**: `$VERDI_HOME/share/NPI/lib/LINUX64` (libNPI.so, libnpiL1.so)
- **依赖库**: zlib1g-dev (已安装)

### 二进制位置
```
/home/open_tools/xwave/xwave          # 主二进制
/home/open_tools/xwave/tools/xwave-env # wrapper 脚本（处理 LD_LIBRARY_PATH）
```

---

## 部署考虑与决策

### 1. Verdi 版本不匹配问题

**问题描述**:
- xwave README 推荐 Verdi V-2023.12-SP1-1 / V-2023.12-SP2
- 本机只有 Verdi O-2018.09-SP2（老版本）
- 两版本 NPI C++ ABI 不兼容：
  - 2023 版导出 new ABI 符号：`std::__cxx11::basic_string`
  - 2018 版导出 old ABI 符号：`std::string` (pre-C++11)

**决策**: 使用 `-D_GLIBCXX_USE_CXX11_ABI=0` 编译标志
- 强制 GCC 11.4.0 使用 old ABI，与 2018 版 NPI 库兼容
- 这是 workaround，非长期方案
- **局限**: 若 xwave 新版本依赖 C++17 或更新的 C++ 特性，此方案可能失效

**如何验证 ABI 匹配**:
```bash
nm -D /home/synopsys/verdi/Verdi_O-2018.09-SP2/share/NPI/lib/LINUX64/libnpiL1.so \
  | grep "npi_fsdb_sig_value_at"
# 结果中 RSs = old std::string
# 若看到 N3std5__cxx11 = new ABI（升级到 2023 版时）
```

### 2. 缺失依赖处理

**问题**: 链接时提示 `-lz` 找不到
```
/usr/bin/ld: 找不到 -lz: 没有那个文件或目录
```

**解决**: 
```bash
sudo apt-get install -y zlib1g-dev
```

**教训**: 若后续更新到更新版本 xwave，检查 Makefile LDFLAGS，预先安装所需开发库。

### 3. Wrapper 脚本配置

**用途**: `tools/xwave-env` 自动设置 `LD_LIBRARY_PATH`

```bash
# 脚本内容（简化）：
export LD_LIBRARY_PATH="$VERDI_HOME/share/NPI/lib/LINUX64:${LD_LIBRARY_PATH:-}"
exec "$xwave_root/xwave" "$@"
```

**使用方式**（总是通过 wrapper）:
```bash
/home/open_tools/xwave/tools/xwave-env <command> ...
```

**不要直接执行**:
```bash
/home/open_tools/xwave/xwave <command>  # ❌ 会报 libNPI.so 找不到
```

---

## 已知限制 & 下次升级风险

### ⚠️ 重要: Verdi 版本升级必读

#### 升级到 Verdi 2023.12 步骤

1. **验证新 Verdi 位置**:
   ```bash
   export VERDI_HOME=/path/to/Verdi_V-2023.12-SP2
   ls $VERDI_HOME/share/NPI/lib/LINUX64/libnpiL1.so
   ```

2. **尝试用新 ABI 编译**（删除 `-D_GLIBCXX_USE_CXX11_ABI=0`）:
   ```bash
   cd /home/open_tools/xwave
   make clean
   make  # 不带 ABI 标志
   ```

3. **若编译成功，验证 symbol 匹配**:
   ```bash
   nm -D $VERDI_HOME/share/NPI/lib/LINUX64/libnpiL1.so | grep "__cxx11" | wc -l
   # 应该有较多 __cxx11 符号
   ```

4. **若编译失败，恢复旧方式**:
   ```bash
   make CXXFLAGS="-Wall -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 ..."
   ```

### 其他已知限制

- **大 FSDB 首次 open 慢**: 受 `XWAVE_SESSION_START_TIMEOUT_SEC` (默认 60s) 限制
- **LSF 环境**: 所有 xwave 命令必须在同一台机器执行（daemon 基于 Unix socket）
- **Session idle timeout**: 默认 1800s；长交互需设置 `export XWAVE_IDLE_TIMEOUT_SEC=28800`

---

## 构建命令记录

```bash
# 1. 克隆
git clone https://github.com/BLANK2077/xwave.git /home/open_tools/xwave

# 2. 清理 + 构建（Verdi 2018 兼容）
cd /home/open_tools/xwave
make clean
make CXXFLAGS="-Wall -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 \
  -I/home/synopsys/verdi/Verdi_O-2018.09-SP2/share/NPI/inc \
  -I/home/synopsys/verdi/Verdi_O-2018.09-SP2/share/NPI/L1/C/inc \
  -Isrc"

# 3. 验证
/home/open_tools/xwave/tools/xwave-env --help
```

---

## Skill 同步状态

**更新文件**: `/home/icarray/Desktop/Code/rkv_v1pro_labs/ppa-lab-copilot/skill/copilot-wave-analyze/SKILL.md`

**同步内容**:
- ✅ AI JSON 接口完整示例（xwave.ai.v1）
- ✅ 所有 action 类别文档（session/value/cursor/scope/list/apb/axi/event/verify）
- ✅ TimeSpec 语法说明
- ✅ Error recovery 指南
- ✅ Performance best practices

**下次更新触发条件**:
- xwave README 新增 action
- Verdi 升级导致 API 变更
- skill 中的示例命令执行失败

---

## 维护清单

### 日常检查
- [ ] `tools/xwave-env help` 返回正常
- [ ] `~/.xwave/sessions/` 下没有僵死 session（用 `session gc` 清理）
- [ ] 若 FSDB 变化，检查 session 是否自动重启

### 升级前检查清单
- [ ] 新 xwave 源码是否有 API breaking change（查 README 和 CHANGELOG）
- [ ] 新 Verdi 版本是否可用（检查 `$VERDI_HOME`）
- [ ] 尝试在测试分支编译新版本
- [ ] 验证 skill 中的示例命令仍可执行
- [ ] 检查是否需要新依赖库

### 升级后验证
```bash
# 1. 二进制正常运行
/home/open_tools/xwave/tools/xwave-env --help

# 2. 用示例 FSDB 测试（若有）
/home/open_tools/xwave/tools/xwave-env open /path/to/test.fsdb --name test_upgrade --debug
/home/open_tools/xwave/tools/xwave-env value top.clk 10ns -s test_upgrade
/home/open_tools/xwave/tools/xwave-env session kill test_upgrade

# 3. 验证 skill 示例
# 在 copilot-wave-analyze 中运行一个简单的 ai query 示例
```

---

## 参考资源

- **README**: https://github.com/BLANK2077/xwave/blob/master/README.zh.md
- **Skill 文件**: `/home/icarray/Desktop/Code/rkv_v1pro_labs/ppa-lab-copilot/skill/copilot-wave-analyze/SKILL.md`
- **NPI 文档**: `$VERDI_HOME/share/NPI/doc/`（如果存在）
- **本地部署 Makefile**: `/home/open_tools/xwave/Makefile`

---

## 问题排查

### 问题: `libNPI.so: cannot open shared object file`
```bash
# ❌ 错误用法
/home/open_tools/xwave/xwave --help

# ✅ 正确用法
/home/open_tools/xwave/tools/xwave-env --help
```

### 问题: 链接失败，undefined reference to `npi_fsdb_sig_value_at`
- 原因: ABI 不匹配
- 检查: `nm -D $VERDI_HOME/share/NPI/lib/LINUX64/libnpiL1.so | grep "npi_fsdb_sig_value_at"`
- 若 2023 版，去掉 `-D_GLIBCXX_USE_CXX11_ABI=0`
- 若 2018 版，加上 `-D_GLIBCXX_USE_CXX11_ABI=0`

### 问题: `SESSION_ID_EXISTS` 当重复打开
```bash
# 用不同的 session 名，或先 kill 旧 session
/home/open_tools/xwave/tools/xwave-env session kill <old_name>
/home/open_tools/xwave/tools/xwave-env ai query ... --args "name": "new_name"
```

### 问题: FSDB 首次 open 超时 (> 60s)
```bash
# 增加超时时间
export XWAVE_SESSION_START_TIMEOUT_SEC=120
/home/open_tools/xwave/tools/xwave-env open /huge/waves.fsdb --name case_a
```

---

## 后续改进空间

1. **自动 Verdi 版本检测**: 在 `tools/xwave-env` 中检测 Verdi 版本，自动选择 ABI 标志
2. **CI/CD 集成**: 在 CI 中定期编译新版 xwave，验证兼容性
3. **缓存优化**: 将 xwave daemon 状态备份到更持久的位置，避免 session 丢失
4. **LSF 支持**: 为 LSF 环境提供专用 wrapper，自动固定到同一台机器

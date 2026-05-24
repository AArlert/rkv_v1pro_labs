# xtrace 部署日志

**部署时间**: 2026-05-24  
**部署人**: Claude Agent  
**部署版本**: GitHub `BLANK2077/xtrace` master branch  
**部署位置**: `/home/open_tools/xtrace`  
**构建状态**: ✅ 成功（需要 Verdi 2018 兼容性 patch）

---

## 部署版本信息

### 源代码
- **Repository**: https://github.com/BLANK2077/xtrace
- **Branch**: master
- **Clone URL**: `git clone https://github.com/BLANK2077/xtrace.git`

### 构建环境
- **GCC**: 11.4.0 (C++11 支持)
- **VERDI_HOME**: `/home/synopsys/verdi/Verdi_O-2018.09-SP2`
- **NPI Headers**: 
  - `$VERDI_HOME/share/NPI/inc`
  - `$VERDI_HOME/share/NPI/L1/C/inc`
- **NPI Libraries**: `$VERDI_HOME/share/NPI/lib/LINUX64`
- **依赖库**: zlib1g-dev (已安装)

### 二进制位置
```
/home/open_tools/xtrace/xtrace          # 主二进制
/home/open_tools/xtrace/tools/xtrace-env # wrapper 脚本（处理 LD_LIBRARY_PATH）
```

---

## 部署考虑与决策

### 1. Verdi 版本 API 差异处理

**问题描述**:
- xtrace README 推荐 Verdi V-2023.12-SP2+
- 本机为 Verdi O-2018.09-SP2（老版本）
- 源码中有两处 API 差异

#### 问题 A: `ast_extractor.cpp:17` - decompile() 函数签名

**错误信息**:
```
error: no matching function for call to 'npi_util_decompile_t::decompile(void*&, bool, bool, bool, bool)'
note: candidate: 'const char* npi_util_decompile_t::decompile(npiHandle hdl, bool constSize = false)'
```

**原因**:
- Verdi 2018: `decompile(npiHandle, bool)` — 2 参数
- Verdi 2023: `decompile(npiHandle, bool, bool, bool, bool)` — 5 参数

**修复**:
```cpp
// 改前（Verdi 2023 API）
const char* text = decomp.decompile(hdl, true, false, false, true);

// 改后（Verdi 2018 兼容）
const char* text = decomp.decompile(hdl, true);
```

**文件**: `src/ast/ast_extractor.cpp:17`

#### 问题 B: `port_analyzer.cpp:21` - npiNoDirection 常量缺失

**错误信息**:
```
error: 'npiNoDirection' was not declared in this scope
```

**原因**:
- Verdi 2018 NPI 中不存在 `npiNoDirection` 常量
- Verdi 2023+ 新增

**修复**:
```cpp
// 改前
case npiNoDirection: return "none";

// 改后（条件编译）
#ifdef npiNoDirection
case npiNoDirection: return "none";
#endif
```

**文件**: `src/port/port_analyzer.cpp:21`

### 2. ABI 兼容性处理

**问题**: 同 xwave，2018 版 NPI 导出 old ABI 符号

**决策**: 使用 `-D_GLIBCXX_USE_CXX11_ABI=0` 编译标志

**验证命令**:
```bash
# 查看 NPI 库导出的符号
nm -D /home/synopsys/verdi/Verdi_O-2018.09-SP2/share/NPI/lib/LINUX64/libnpiL1.so \
  | grep "npi_object_get"
# 若显示 RSs（old ABI）则需要用 old ABI 编译
```

### 3. 源码修改的保留性

**决策**: 保留本地修改，而非 fork

**理由**:
- 这是 workaround，非长期方案
- 后续 Verdi 升级到 2023 版后，这两处 patch 需要恢复

**后续行动**:
- 当升级到 Verdi 2023 时，需要：
  1. 恢复 `ast_extractor.cpp:17` 为 5 参数版本
  2. 删除 `port_analyzer.cpp:21` 的条件编译，恢复 `npiNoDirection` case

---

## 已知限制 & 下次升级风险

### ⚠️ 重要: Verdi 版本升级必读

#### 升级到 Verdi 2023.12 步骤

1. **恢复源码**:
   ```bash
   cd /home/open_tools/xtrace
   # 改回 src/ast/ast_extractor.cpp:17（5 参数）
   vim src/ast/ast_extractor.cpp
   # 改回 src/port/port_analyzer.cpp:21（删除条件编译）
   vim src/port/port_analyzer.cpp
   ```

2. **更新环境变量**:
   ```bash
   export VERDI_HOME=/path/to/Verdi_V-2023.12-SP2
   ```

3. **删除旧 ABI 标志，使用新 ABI 编译**:
   ```bash
   make clean
   make  # 不带 -D_GLIBCXX_USE_CXX11_ABI=0
   ```

4. **验证**:
   ```bash
   /home/open_tools/xtrace/tools/xtrace-env help
   ```

### 其他已知限制

- **大 design 首次 open 慢**: NPI 需要解析整个设计数据库，时间与设计复杂度成正比
- **控制依赖分析有时返回空**: 当 NPI 不支持某些过程赋值场景时，xtrace 会自动 fallback 到 AST 遍历，此时标记 `confidence=low`
- **LSF 环境**: 所有 xtrace 命令必须在同一台机器执行（daemon 基于 Unix socket）
- **Interface 处理**: 已支持 SystemVerilog interface 成员引用，但某些复杂 interface 连接可能需要二次验证

---

## 构建命令记录

```bash
# 1. 克隆
git clone https://github.com/BLANK2077/xtrace.git /home/open_tools/xtrace

# 2. 应用 Verdi 2018 兼容性 patch
cd /home/open_tools/xtrace

# Patch A: ast_extractor.cpp
sed -i 's/decomp\.decompile(hdl, true, false, false, true)/decomp.decompile(hdl, true)/' \
  src/ast/ast_extractor.cpp

# Patch B: port_analyzer.cpp
cat > /tmp/port_analyzer.patch << 'EOF'
        #ifdef npiNoDirection
        case npiNoDirection: return "none";
        #endif
EOF
# 手动编辑或用脚本替换

# 3. 清理 + 构建
make clean
make CXXFLAGS="-Wall -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 \
  -I/home/synopsys/verdi/Verdi_O-2018.09-SP2/share/NPI/inc \
  -I/home/synopsys/verdi/Verdi_O-2018.09-SP2/share/NPI/L1/C/inc \
  -Isrc -Ithird_party"

# 4. 验证
/home/open_tools/xtrace/tools/xtrace-env help
```

---

## Skill 同步状态

**更新文件**: `/home/icarray/Desktop/Code/rkv_v1pro_labs/ppa-lab-copilot/skill/copilot-rtl-trace/SKILL.md`

**同步内容**:
- ✅ AI JSON 接口完整示例（xtrace.ai.v1）
- ✅ 所有 action 类别文档（session/trace/control/procedural/sequential/fsm/counter）
- ✅ 传统 CLI 用法文档
- ✅ Confidence 处理规则
- ✅ Session doctor 状态说明
- ✅ Error recovery 指南

**下次更新触发条件**:
- xtrace README 新增 action
- Verdi 升级导致 API 变更
- 新增 control_dependencies 分析能力
- skill 中的示例命令执行失败

---

## Verdi 2018 Patch 文件内容

### Patch: src/ast/ast_extractor.cpp

```diff
--- a/src/ast/ast_extractor.cpp
+++ b/src/ast/ast_extractor.cpp
@@ -14,7 +14,7 @@ using json = nlohmann::json;
 std::string AstExtractor::decompile(npiHandle hdl) const {
     if (!hdl) return "";
     npi_util_decompile_t decomp;
-    const char* text = decomp.decompile(hdl, true, false, false, true);
+    const char* text = decomp.decompile(hdl, true);
     if (text && *text) return text;
     const char* fallback = npi_get_str(npiDecompile, hdl);
     if (fallback && *fallback) return fallback;
```

### Patch: src/port/port_analyzer.cpp

```diff
--- a/src/port/port_analyzer.cpp
+++ b/src/port/port_analyzer.cpp
@@ -18,7 +18,9 @@ namespace {
     switch (dir) {
         case npiInput: return "input";
         case npiOutput: return "output";
         case npiInout: return "inout";
         case npiRef: return "ref";
+        #ifdef npiNoDirection
         case npiNoDirection: return "none";
+        #endif
         default: return "direction_" + std::to_string(dir);
     }
```

---

## 维护清单

### 日常检查
- [ ] `tools/xtrace-env help` 返回正常
- [ ] `~/.xtrace/sessions/` 下没有僵死 session（用 `session kill all` 清理）
- [ ] 若编译新版本，检查 Verdi 2018 patch 是否仍需要

### 升级前检查清单
- [ ] 新 xtrace 源码是否有 API breaking change（查 README）
- [ ] 检查是否仍需 Verdi 2018 patch（查看 `src/ast/ast_extractor.cpp` 和 `src/port/port_analyzer.cpp`）
- [ ] 新 Verdi 版本是否可用（检查 `$VERDI_HOME`）
- [ ] 尝试在测试分支编译新版本
- [ ] 验证 skill 中的示例命令仍可执行

### 升级到 Verdi 2023 的清单
- [ ] 备份当前的 `src/ast/ast_extractor.cpp` 和 `src/port/port_analyzer.cpp`
- [ ] 从 GitHub master 拉取最新源码
- [ ] **移除** Verdi 2018 patch（恢复为 5 参数 decompile、恢复 npiNoDirection）
- [ ] **移除** `-D_GLIBCXX_USE_CXX11_ABI=0` 编译标志
- [ ] 清理 + 编译
- [ ] 运行所有 skill 示例验证

### 升级后验证
```bash
# 1. 二进制正常运行
/home/open_tools/xtrace/tools/xtrace-env help

# 2. 用示例 daidir 测试（若有）
/home/open_tools/xtrace/tools/xtrace-env session ensure \
  -dbdir /path/to/simv.daidir --name test_upgrade -json
/home/open_tools/xtrace/tools/xtrace-env query \
  -dbdir /path/to/simv.daidir --name test_upgrade \
  --driver top.some_signal -json | head -20
/home/open_tools/xtrace/tools/xtrace-env session kill test_upgrade

# 3. 验证 skill 示例
# 在 copilot-rtl-trace 中运行一个简单的 ai query 示例
```

---

## 参考资源

- **README**: https://github.com/BLANK2077/xtrace/blob/master/README.zh.md
- **Skill 文件**: `/home/icarray/Desktop/Code/rkv_v1pro_labs/ppa-lab-copilot/skill/copilot-rtl-trace/SKILL.md`
- **NPI 文档**: `$VERDI_HOME/share/NPI/doc/`（如果存在）
- **本地部署 Makefile**: `/home/open_tools/xtrace/Makefile`
- **本地修改文件**:
  - `src/ast/ast_extractor.cpp` (line 17)
  - `src/port/port_analyzer.cpp` (line 21)

---

## 问题排查

### 问题: 编译失败，decompile() 签名不匹配
```
error: no matching function for call to 
  'npi_util_decompile_t::decompile(void*&, bool, bool, bool, bool)'
```

**原因**: Verdi 版本太旧（2018），API 不同

**解决**:
```bash
# 检查 Verdi 版本
echo $VERDI_HOME

# 若是 2018 版：
#   1. 将 5 参数 decompile() 改为 2 参数
#   2. 加上 -D_GLIBCXX_USE_CXX11_ABI=0

# 若是 2023 版：
#   1. 保持 5 参数不变
#   2. 删除 -D_GLIBCXX_USE_CXX11_ABI=0
```

### 问题: 编译失败，npiNoDirection 未声明
```
error: 'npiNoDirection' was not declared in this scope
```

**原因**: Verdi 版本太旧（2018），常量不存在

**解决**:
```cpp
// 用条件编译包裹
#ifdef npiNoDirection
case npiNoDirection: return "none";
#endif
```

### 问题: `libNPI.so: cannot open shared object file`
```bash
# ❌ 错误用法
/home/open_tools/xtrace/xtrace --help

# ✅ 正确用法
/home/open_tools/xtrace/tools/xtrace-env help
```

### 问题: `SESSION_NOT_FOUND` 或连接失败
```bash
# 诊断
/home/open_tools/xtrace/tools/xtrace-env session doctor -s case_a -json

# 若不健康，清理并重新创建
/home/open_tools/xtrace/tools/xtrace-env session kill all
/home/open_tools/xtrace/tools/xtrace-env session ensure \
  -dbdir /path/to/simv.daidir --name case_a
```

### 问题: driver/load 返回空结果（confidence=low）
```
# 原因: NPI 无法提取某些过程赋值
# 解决: 用 Read 工具直接读源码 file:line 位置验证
```

---

## 后续改进空间

1. **自动 Verdi 版本检测**: 在编译时自动检测 Verdi 版本，自动应用必要 patch
2. **CI/CD 集成**: 在 CI 中对 Verdi 2018 和 2023 两版本分别编译验证
3. **Patch 管理**: 用 git patch 或脚本管理 Verdi 2018 兼容性 patch，便于升级
4. **LSF 支持**: 为 LSF 环境提供专用 wrapper，自动固定到同一台机器
5. **性能优化**: 大 design 首次 open 时，考虑后台进程 + 进度显示

---

## 版本历史

| 日期 | 版本 | Verdi | 构建状态 | 备注 |
|---|---|---|---|---|
| 2026-05-24 | master | O-2018.09-SP2 | ✅ | 初始部署，应用 2018 兼容性 patch |
| — | master | V-2023.12-SP2 | ⚠️ 待测 | 需要恢复源码，删除 ABI 标志 |

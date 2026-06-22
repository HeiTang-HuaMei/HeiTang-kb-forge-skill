# 工业级全量产品验收链路报告

生成日期：2026-06-22

## 1. 验收口径

本报告采用软件黑盒验收口径。`flutter analyze`、`flutter test`、`flutter build windows` 只作为工程基线；真正的产品验收以 Windows EXE、RC ZIP 解压产物、真实输入目录、截图、文件系统产物和 Windows 原生 Product Verifier 结果为准。

## 2. 主链路

主链路：

```text
启动 EXE
-> 进入文档库
-> 读取 D:\HeiTang-Codex-WorkSpace\input
-> 导入真实资料
-> 整理资料
-> 构建知识库
-> 测试知识库
-> 查看来源 / 证据
-> 生成 Markdown
-> 导出 Markdown
-> 生成 Skill
-> 创建 Agent
-> 执行单 Agent 对话
-> 成果中心查看真实产物
-> 使用记录页查看统计
-> 危险操作二次确认
```

主链路结果：

```text
passed
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/zip_exe_smoke/windows_exe_smoke_20260622_195300/main_chain_smoke_results.json
```

## 3. 页面链路

页面覆盖：

```text
首页
工作区
文档库
知识库
测试知识库
文档生成
技能生成
我的助手
成果中心
使用记录
设置
```

结果：

```text
passed
```

说明：所有页面均可打开，截图非白屏、非黑屏。Windows 原生自动化无法完整读取 Flutter 控件语义树，因此标题和关键模块以截图/OCR 抽查支撑。

## 4. 输入链路

真实输入目录：

```text
D:\HeiTang-Codex-WorkSpace\input
```

结果：

```text
core path passed
edge input coverage blocked
```

已通过：

```text
真实文件夹导入
中文 PDF 文件名
SHA256 记录
input 原文件保护
```

未完成：

```text
单文件导入
重复文件
空路径
不存在路径
不支持格式
空文件
损坏文件
无权限路径
超长文件名
```

## 5. 产物链路

已验证真实产物：

```text
导入清单 / 导入报告
解析报告
知识库
检索结果
Markdown 文档
Markdown 导出
Skill
Agent
Agent 对话
```

结果：

```text
passed
```

## 6. 使用记录链路

结果：

```text
blocked
```

说明：使用记录页可打开，页面显示执行记录、失败记录、产物记录统计。OCR 抽查可读到：

```text
执行记录 14/14
失败记录 0
产物记录 3
```

但 verifier 当前未完成每个真实动作到 UI 使用记录的逐条映射，`usage_record_smoke_results.json` 仍说明记录是从真实产物推断。因此不能把使用记录链路判为工业级全通过。

## 7. 危险操作链路

覆盖：

```text
清空对话
删除成果或清理最近任务
删除资料
```

结果：

```text
passed
```

要求满足：

```text
有二次确认
取消无副作用
确认后状态刷新
```

## 8. 配置 Gate 链路

结果：

```text
passed with gated optional capabilities
```

正确 gate：

```text
模型服务
外部来源核对
DOCX 导出
PDF 导出
PPTX 导出
Redis
向量库
外部 Skill 导入
多助手协作依赖项
外部链接读取
OCR
```

未发现：

```text
假成功
raw Provider error
Gateway / ModelRoute 泄漏
runtime_ready
desktop_runtime_required
stack trace
null / undefined
```

## 9. 热插拔配置链路

结果：

```text
blocked
```

已有配置资产和历史日志，但未完成 EXE UI 黑盒验证：

```text
项目配置 A/B 创建
配置切换
导入目录隔离
输出目录隔离
模型服务配置隔离
Skill 配置隔离
Agent 配置隔离
记忆配置隔离
禁用 / 启用能力
配置损坏 fallback
配置删除二次确认
```

## 10. 工作区与记忆隔离链路

结果：

```text
partially verified
```

已验证单工作区主链路、Agent 对话和清空确认。未完成 A/B 工作区互不可见、跨 Agent 记忆隔离、跨工作区记忆隔离的完整 EXE UI 自动化矩阵。

## 11. 软件健壮性链路

窗口健壮性：

```text
passed
```

已覆盖启动、关闭、最大化、最小化、还原、异常终止后重启。

输入健壮性：

```text
blocked
```

空输入、不存在路径、损坏文件、无权限路径、输出目录不可写等边界未完成 EXE UI 自动化。

## 12. 链路结论

核心产品链路已经能跑通，RC ZIP 本体也能通过 EXE 黑盒主链路。但本 gate 的目标是“工业级全量黑盒验收 + 健壮性测试 + 热插拔配置测试”，当前覆盖不满足完整要求。

最终结论：

```text
industrial_full_product_acceptance_blocked
allowed_next_gate: product_smoke_bugfix_gate
```

不得进入：

```text
final_owner_acceptance_gate
```


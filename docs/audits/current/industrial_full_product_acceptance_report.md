# 工业级全量产品验收报告

生成日期：2026-06-22

Gate：`industrial_full_product_acceptance_gate`

## 1. 测试目标

在最终 Owner Acceptance 前，对 `v4.2.0-rc.1` 做一次软件级黑盒验收。重点不是 core 单元测试，而是验证普通用户通过 Windows EXE 是否能完成真实输入、真实产出、页面导航、主链路、危险操作确认、配置 gate、产物与使用记录检查。

## 2. 测试依据

本轮依据：

```text
docs/product/PRD_V3_2026-06-19.md
docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md
docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md
docs/testing/PRODUCT_ACCEPTANCE_CHECKLIST.md
docs/dev/PRODUCT_VERIFIER_AGENT_SPEC.md
docs/dev/WRITER_REVIEWER_VERIFIER_WORKFLOW.md
docs/dev/HEITANG_LAZY_BUILDER_GATE.md
docs/product/USER_PATH_FIRST_UI_GOVERNANCE.md
docs/audits/current/release_upload_gate_report.md
docs/audits/current/windows_exe_smoke_acceptance_report.md
```

材料索引：

```text
docs/audits/current/industrial_full_product_acceptance_source_index.md
```

## 3. 测试环境

| 项 | 值 |
| --- | --- |
| OS | Windows |
| 自动化路径 | `windows_native_product_verifier` |
| RC tag | `v4.2.0-rc.1` |
| 当前 HEAD | `46fcf2a docs: record release upload gate` |
| RC tag 指向 | `5410b8d06363c33c80a3c5d65d7a4fff8c52caf6` |
| 真实输入目录 | `D:\HeiTang-Codex-WorkSpace\input` |
| 验收证据目录 | `web/workbench/flutter_app/output/industrial_acceptance/` |

## 4. RC ZIP

| 项 | 结果 |
| --- | --- |
| ZIP | `web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/HeiTang-Knowledge-Workbench-v4.2.0-rc.1-windows-x64.zip` |
| SHA256 | `150B1EC02428F27DC4A65F86A544350BF10E306699A3FB15821E312ABB8D041E` |
| ZIP 完整性 | passed |
| 解压 EXE | passed |
| `.git/output/logs/screenshots/input` 泄漏 | 未发现 |

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/zip_integrity_result.json
```

## 5. 工程基线

以下命令只作为工程基线，不作为工业级软件验收主证据：

| 命令 | 结果 | 日志 |
| --- | --- | --- |
| `flutter analyze` | passed | `web/workbench/flutter_app/output/industrial_acceptance/logs/flutter_analyze.log` |
| `flutter test --concurrency=1` | passed | `web/workbench/flutter_app/output/industrial_acceptance/logs/flutter_test.log` |
| `flutter build windows` | passed | `web/workbench/flutter_app/output/industrial_acceptance/logs/flutter_build_windows.log` |
| `git diff --check` | passed | `web/workbench/flutter_app/output/industrial_acceptance/logs/git_diff_check.log` |

说明：Owner 已明确“测试是软件测试不是 core 测试”，因此上述结果不能替代 EXE 黑盒验收。

## 6. EXE 黑盒验收结果

| 对象 | 结果 | 证据 |
| --- | --- | --- |
| 当前 build EXE | passed | `web/workbench/flutter_app/output/industrial_acceptance/current_build_smoke/windows_exe_smoke_20260622_194945/` |
| RC ZIP 解压 EXE | passed | `web/workbench/flutter_app/output/industrial_acceptance/zip_exe_smoke/windows_exe_smoke_20260622_195300/` |

RC ZIP 解压 EXE verifier 结果：

```text
final_status: windows_exe_smoke_passed
automation_path: windows_native_product_verifier
navigation_status: passed
main_chain_status: passed
product_bug_confirmed: false
```

## 7. 窗口健壮性

结果：passed

覆盖：

```text
EXE 启动
5 秒存活
MainWindowHandle 非 0
标题包含 HeiTang Workbench
首页非白屏 / 非黑屏
最大化 / 还原 / 最小化 / 还原
连续启动关闭 3 次
异常终止后再次启动
WM_CLOSE 后退出
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/exe_window_robustness_result.json
web/workbench/flutter_app/output/industrial_acceptance/screenshots/exe_window/
```

## 8. 页面测试结果

结果：passed

覆盖 11 页：

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

所有页面均可打开，截图非白屏、非黑屏。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/page_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/zip_exe_smoke/windows_exe_smoke_20260622_195300/screenshots/
```

限制：Windows 原生自动化无法完整读取 Flutter 控件文本，页面主标题和关键模块主要由截图/OCR 抽查支撑，不是完整 accessibility tree 断言。

## 9. 按钮测试结果

结果：blocked

已通过：

```text
主链路动作：导入、整理、构建知识库、检索、生成 Markdown、导出 Markdown、生成 Skill、创建 Agent、单 Agent 对话、成果中心查看、使用记录页查看
危险操作：清空对话、删除成果、删除资料均有二次确认，取消无副作用，确认后状态刷新
未配置能力：模型服务、DOCX/PDF/PPTX、Redis、向量库、外部 Skill、协作依赖项均未假成功
```

阻断点：

```text
未完成所有可见按钮 / 标签 / 主操作入口的逐按钮自动化枚举与逐项点击。
Windows 原生自动化当前不能可靠读取 Flutter 内部按钮语义树。
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/button_acceptance_matrix.json
web/workbench/flutter_app/output/industrial_acceptance/button_acceptance_matrix.md
```

## 10. 真实文件输入结果

结果：blocked

已通过：

```text
读取 D:\HeiTang-Codex-WorkSpace\input
记录 6 个真实 PDF 文件名、大小、扩展名、SHA256
真实文件夹导入进入主链路
中文文件名输入链路通过
未删除、未移动、未修改 input 原文件
```

阻断点：

```text
单文件导入、重复文件、空路径、不存在路径、不支持格式、空文件、损坏文件、无权限路径、超长文件名未完成 EXE UI 自动化逐项覆盖。
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/real_file_input_results.json
web/workbench/flutter_app/output/industrial_acceptance/input_hashes.json
```

## 11. 文档库结果

结果：passed core flow with edge gaps

说明：真实导入、整理、删除资料二次确认通过；异常导入边界仍未完成逐项 EXE UI 自动化。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/document_library_acceptance_results.json
```

## 12. 知识库与检索结果

结果：passed core flow

已验证：

```text
从真实资料生成知识库
测试知识库
来源 / 证据链进入检索产物
未配置外部核对不假成功
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/knowledge_base_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/retrieval_trace_results.json
```

## 13. 文档生成结果

结果：passed core flow with export gates

已验证：

```text
生成 Markdown
导出 Markdown
产物真实落盘
DOCX / PDF / PPTX 未配置时 gate
成果中心可见相关产物
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/document_generation_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/generated_document_artifacts.json
```

## 14. Skill 与外部 Skill

Skill 生成结果：passed core flow

外部 Skill 导入结果：gated / incomplete

说明：基于知识库生成 Skill 的主链路通过。外部 Skill 导入能力在未配置状态下未假成功，但合法、重复、非法、缺字段、不存在路径等导入分支未完成 EXE UI 自动化逐项覆盖。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/skill_generation_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/external_skill_import_acceptance_results.json
```

## 15. Agent 与 A2A

单 Agent：passed core flow with model gate

A2A / 多助手协作：gated

说明：创建 Agent、绑定主链路产物、单 Agent 对话通过。多助手协作依赖项未配置时 gate，未发现假成功或 raw internal error。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/agent_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/a2a_acceptance_results.json
```

## 16. 记忆存储

结果：partially verified

已验证：

```text
单 Agent 对话产生日志 / 对话产物
清空对话有二次确认
Redis / 向量库未配置时 gate
```

未完成：

```text
跨工作区记忆隔离
跨 Agent 记忆隔离
记忆清空后的逐条 UI 映射
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/memory_store_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/memory_isolation_results.json
```

## 17. 工作分区

结果：automation limited

说明：工作区 manifest 与历史文件存在，主链路工作区可运行；但未完成 A/B 工作区创建、切换、互不可见、删除确认的 EXE UI 全矩阵。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/workspace_partition_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/workspace_isolation_results.json
```

## 18. 热插拔项目配置

结果：blocked

已有证据：

```text
docs/audits/current/rc10_hot_swappable_project_config_industrialization_report.md
workspace config history / provider lifecycle logs
```

阻断点：

```text
未通过 EXE UI 完整执行配置 A/B 创建、切换、回滚、禁用/启用、损坏配置 fallback、配置删除二次确认。
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/hotplug_project_config_acceptance_results.json
web/workbench/flutter_app/output/industrial_acceptance/hotplug_config_isolation_matrix.md
```

## 19. 未配置能力 Gate

结果：passed with uncovered permission edge

已覆盖：

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

限制：本地路径权限的无权限场景未完成 EXE UI 自动化。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/config_gate_acceptance_results.json
```

## 20. 健壮性测试

结果：blocked

已通过：

```text
窗口健壮性
快速页面切换
启动关闭
中文文件名
未配置能力 gate
```

未完成：

```text
空输入
不存在路径
无权限路径
超长文件名
空文件
损坏文件
重复导入
导入中关闭窗口
生成中切换页面
输出目录不可写
配置文件缺失 / 损坏
```

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/robustness_acceptance_results.json
```

## 21. 成果中心 / 使用记录一致性

结果：blocked

成果中心产物：passed

使用记录：partially verified

说明：使用记录页截图显示执行记录、失败记录、产物记录统计；OCR 可识别页面统计信息。文件系统存在真实产物、历史、配置日志。但当前 verifier 的 `usage_record_smoke_results.json` 明确写明：使用记录来自真实产物推断，尚未完成每个用户动作到 UI 使用记录的逐条机器映射。

证据：

```text
web/workbench/flutter_app/output/industrial_acceptance/artifact_usage_consistency_results.json
web/workbench/flutter_app/output/industrial_acceptance/usage_records_ocr.txt
```

## 22. 阻断项

本 Gate 不允许进入 `final_owner_acceptance_gate`。阻断项：

```text
1. 全量按钮逐项点击矩阵未完成。
2. 异常输入 / 边界输入未完成 EXE UI 自动化。
3. 热插拔项目配置 A/B 切换、回滚、禁用启用、损坏 fallback、删除确认未完成 EXE UI 黑盒验证。
4. 使用记录未完成每个动作到 UI 使用记录的逐条机器映射，当前仍部分依赖真实产物推断。
5. 工作区 A/B 和 Agent 记忆隔离未完成完整 EXE UI 矩阵。
```

## 23. 非阻断风险

```text
1. Windows 原生自动化依赖相对坐标，能验证当前布局，但不是完整 UIAutomation 语义树。
2. OCR 可证明使用记录页面统计存在，但不等于逐条记录可导出。
3. 可选 Provider / Redis / 向量库 / OCR gate 正确，但未配置实服务时不能验证真实服务联通。
```

## 24. 修复建议

```text
1. 增强 Windows native Product Verifier：增加可读取按钮 inventory 的语义接口或测试专用无视觉标识。
2. 为使用记录增加机器可导出的 `usage_records.json` 或 UI 导出动作，并让 verifier 做动作到记录的逐条映射。
3. 增加 EXE 黑盒异常输入入口：空路径、不存在路径、不支持格式、损坏文件、无权限路径。
4. 增加热插拔项目配置的产品级自动化入口和 verifier 用例。
5. 增加工作区 A/B 与 Agent 记忆隔离的自动化验收脚本。
```

## 25. 结论

当前结论：

```text
industrial_full_product_acceptance_blocked
allowed_next_gate: product_smoke_bugfix_gate
```

不得进入：

```text
final_owner_acceptance_gate
stable
production_ready
official_release_created
GitHub Release created
```


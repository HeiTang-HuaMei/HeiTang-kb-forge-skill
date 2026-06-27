# 当前代码结构对照表

## 目的

本文件用于修复阶段快速定位代码。它描述当前真实代码结构，不描述理想结构。修复问题时先查本文件，再决定最小改动位置。

## 总入口

Flutter 应用目录：

```text
web/workbench/flutter_app
```

主要入口：

```text
web/workbench/flutter_app/lib/main.dart
```

当前现实：

- `main.dart` 仍是应用启动、状态持有、运行时注入和页面装配的中心。
- 多数 feature 页面仍是 `part of '../main.dart'` 风格。
- 不应在一次修复里顺手做大规模拆分。

## App Shell

| 职责 | 当前文件 |
| --- | --- |
| 页面注册与页面元信息 | `lib/app/workbench_pages.dart` |
| 桌面状态栏 | `lib/app/desktop_status_bar.dart` |
| 顶部栏 | `lib/app/product_top_bar.dart` |
| 侧边导航 | `lib/app/workbench_sidebar.dart` |
| 外壳布局 | `lib/app/workbench_shell.dart` |

一级导航不得随意变化。修改导航文案、顺序或入口前必须先对照 `PRODUCT_SCOPE.md`。

## 七个主导航对应文件

| 主导航 | 主要页面文件 | 常见修复范围 |
| --- | --- | --- |
| 导入资料 | `lib/features/import_parsing/import_product_workflow.dart` | 文件/文件夹/链接导入、解析进度、去重、下一步 |
| 知识库 | `lib/features/knowledge_base/knowledge_base_product_workflow.dart` | KB 生成、合并、来源、片段、导出、删除 |
| Skill | `lib/features/skill/skill_builder_product_workflow.dart` | 从 KB 生成 Skill、导入 Skill、命名、导出、删除 |
| Agent | `lib/features/agent/agent_product_workflow.dart` | 创建助手、绑定 KB/Skill、对话、知识边界、工作小组 |
| 文档生成 | `lib/features/document_generation/document_generation_product_workflow.dart` | 选 KB、命名、类型/模板/格式、生成、导出、删除 |
| 任务工作台 | `lib/features/workbook/workbook_product_workflow.dart` | 操作记录、任务进度、失败重试、诊断导出 |
| 配置 | `lib/features/settings/settings_product_workflow.dart` | 外部服务配置、连接测试、解析能力状态 |

辅助页面：

| 页面 | 文件 |
| --- | --- |
| 成果页 / Artifact Center | `lib/features/artifacts/artifact_center_product_workflow.dart` |
| 文档库 | `lib/features/document_library/document_library_product_workflow.dart` |
| 知识库验证 / 检索验证 | `lib/features/retrieval/retrieval_verification_product_workflow.dart` |
| 审计 / 高级诊断 | `lib/features/audit/audit_center_product_workflow.dart` |
| 首页 / Dashboard | `lib/features/dashboard/dashboard_product_workflow.dart` |

## Runtime 与数据真值

公开运行时入口：

```dart
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller.dart';
```

当前文件：

| 职责 | 文件 |
| --- | --- |
| 条件导出 facade | `lib/rc6_runtime/rc6_runtime_controller.dart` |
| Windows / IO runtime 主体 | `lib/rc6_runtime/rc6_runtime_controller_io.dart` |
| Stub runtime | `lib/rc6_runtime/rc6_runtime_controller_stub.dart` |
| 配置 profile 兼容导出 | `lib/rc6_runtime/project_config_profile.dart` |
| 配置 profile 领域模型 | `lib/domain/config_profile/project_config_profile.dart` |

当前现实：

- `rc6_runtime_controller_io.dart` 很大，承载大量历史 runtime 行为。
- 修复时优先改最小相关方法，不做顺手拆分。
- 改 runtime 必须验证对应后台真值、UI 显示和重启恢复。

## Shared / Contracts

| 职责 | 目录 |
| --- | --- |
| 共享 UI 组件 | `lib/shared/` |
| 合同模型 / fixture 加载 | `lib/contracts/` |
| Core bridge | `lib/core_bridge/` |
| Core actions | `lib/core_actions/` |
| Backend evidence | `lib/backend_evidence/` |
| 旧 Skill factory 独立 UI / fixture | `lib/skill_factory/` |

普通 UI 文案修复优先在 feature 或 shared 层完成。不要为了文案问题改 contracts fixture，除非问题来源确认就是 fixture。

## 主要测试入口

| 测试类型 | 文件 |
| --- | --- |
| 主 widget / UI smoke | `test/widget_test.dart` |
| Owner acceptance repair | `test/rc4_owner_acceptance_repair_test.dart` |
| Runtime truth / blocker repair | `test/rc6_runtime_truth_blocker_repair_test.dart` |
| Campaign 4 workbench | `test/campaign_4_workbench_test.dart` |
| Skill factory workflow | `test/skill_factory_workflow_test.dart` |
| Full interaction operability | `test/full_interaction_operability_runtime_test.dart` |

注意：

- widget/controller/runtime test 不能替代 latest running UI 验收。
- 大测试文件可以证明后台规则，但普通用户 UI 闭合仍必须在 running UI 里确认。

## Windows 验证脚本

常用脚本目录：

```text
web/workbench/flutter_app/tool/windows_native_product_verifier
```

常用脚本：

| 目标 | 脚本 |
| --- | --- |
| 单实例检查 | `run_single_instance_check.ps1` |
| UI 全矩阵 | `run_ui_full_campaign_matrix.ps1` |
| 文档库生命周期 | `run_document_library_lifecycle_matrix.ps1` |
| 知识库构建生命周期 | `run_knowledge_base_build_lifecycle_matrix.ps1` |
| 知识库验证生命周期 | `run_knowledge_validation_lifecycle_matrix.ps1` |
| 文档生成 | `run_document_generation_matrix.ps1` |
| 设置导出生命周期 | `run_settings_export_lifecycle_matrix.ps1` |
| Windows EXE smoke | `run_windows_exe_smoke.ps1` |
| Windows packaging baseline smoke | `run_windows_packaging_baseline_smoke.ps1` |

Package build 不属于普通 UI closure 修复的默认动作，除非当前任务明确要求。

## 修复定位顺序

1. 先确认问题在哪个主导航或辅助页。
2. 查本文件定位 feature 文件。
3. 如果只是显示、文案、禁用原因、下一步动作，优先改 UI / ViewModel 映射。
4. 如果数据不真实、重启不恢复、删除/合并不安全，定位 runtime 和后台真值。
5. 如果多个页面状态不一致，查共享状态来源和 runtime reload。
6. 最后补窄测试，并用 running UI 复验。

## 禁止借修复做大重构

修复任务中默认不做：

- 拆分 `rc6_runtime_controller_io.dart`。
- 把所有 feature 从 part 迁移成独立 library。
- 重排一级导航。
- 改状态机或 release gate。
- 清理无关历史 fixture。

这些可以作为独立重构任务，但不能混入 UI closure blocker 修复。

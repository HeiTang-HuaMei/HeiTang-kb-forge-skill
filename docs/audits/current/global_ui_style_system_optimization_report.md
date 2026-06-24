# HeiTang Knowledge Workbench UI Full Visual Rework Report

生成日期：2026-06-23

## 1. 状态

```text
ui_final_navigation_repair_completed_needs_owner_review
button_runtime_mapping_mapped_pending_full_exe_click_matrix
ui_core_operation_alignment_mapped_pending_full_exe_click_matrix
industrial_full_product_acceptance_blocked
ui_detail_copy_glyph_repair_completed_needs_owner_review
ui_full_visual_rework_completed_needs_owner_review
my_assistant_agent_workbench_rebuild_completed_needs_owner_review
test_harness_infrastructure_blocked
```

布局、命名、首页 Hero 图形与最终导航收口已完成复核，仍需 Owner review：一级导航只保留“首页 / 工作区 / 文档库 / 知识库 / 文档生成 / 技能生成 / 我的助手 / 设置”，成果、记录、验证均降级为二级入口。Button Runtime Matrix 已建立，按钮矩阵脚本结果为 `completed_with_gated_optional_capabilities_needs_owner_review`；由于仍不是完整 EXE 全按钮点击覆盖，`ui_core_operation_alignment_completed_needs_owner_review` 也暂不写入，保留 `industrial_full_product_acceptance_blocked`。`flutter test --concurrency=1` 仍阻塞在测试 harness WebSocket 502，未记录为测试通过。

## 2. 修改文件

UI Campaign 相关文件：

```text
web/workbench/flutter_app/lib/main.dart
web/workbench/flutter_app/lib/shared/product_components.dart
web/workbench/flutter_app/lib/app/workbench_shell.dart
web/workbench/flutter_app/lib/app/workbench_sidebar.dart
web/workbench/flutter_app/lib/app/product_top_bar.dart
web/workbench/flutter_app/lib/app/desktop_status_bar.dart
web/workbench/flutter_app/lib/app/workbench_pages.dart
web/workbench/flutter_app/lib/app/workbench_sidebar.dart
web/workbench/flutter_app/lib/features/dashboard/dashboard_product_workflow.dart
web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart
web/workbench/flutter_app/lib/features/artifacts/artifact_center_product_workflow.dart
web/workbench/flutter_app/lib/features/audit/audit_center_product_workflow.dart
web/workbench/flutter_app/lib/features/document_library/document_library_product_workflow.dart
web/workbench/flutter_app/lib/features/import_parsing/import_product_workflow.dart
web/workbench/flutter_app/lib/features/knowledge_base/knowledge_base_product_workflow.dart
web/workbench/flutter_app/lib/features/retrieval/retrieval_verification_product_workflow.dart
web/workbench/flutter_app/lib/features/settings/settings_product_workflow.dart
web/workbench/flutter_app/lib/features/workbook/workbook_product_workflow.dart
web/workbench/flutter_app/tool/windows_native_product_verifier/run_ui_full_campaign_matrix.ps1
web/workbench/flutter_app/tool/windows_native_product_verifier/run_button_matrix.ps1
web/workbench/flutter_app/output/ui_core_alignment/button_runtime_mapping_matrix.json
docs/audits/current/ui_button_runtime_mapping_matrix.md
docs/audits/current/global_ui_style_system_optimization_report.md
```

已知工作区中还存在其他历史/并行脏改动，本报告不声明它们属于本次 UI Campaign，也未回滚。

## 3. 视觉系统

全局 Token 已收敛到 macOS Vibrancy 主框架：

```text
白天：#f5f7fb 背景、半透明侧栏/顶栏、白色内容面板、低对比 1px 边框
暗夜：#1c1c1e / #242426 / #2c2c2e / #343436 / #3a3a3c 深灰层级
语义色：资料、知识库、知识库验证、文档生成、技能、助手、成果、操作记录、设置
```

修复点：

```text
1. 修正 outlineVariant 二次 alpha 导致的硬黑框。
2. 统一卡片、按钮、输入框、标签、表格、状态胶囊的轻边框。
3. 暗夜模式取消厚阴影和 glow，依靠深灰层级和 1px 细分隔。
4. 白天模式保留 Soft UI 轻柔面板、浅色图标底和低对比状态块。
5. Liquid Glass 仅用于 Hero 知识资产符号、搜索/状态胶囊和成果/上下文浮层感。
```

## 4. 首页重做

首页已从后台卡片堆叠改为“知识资产工作台首页”：

```text
Hero：把资料变成可用的知识资产；文档资料 -> 知识库 -> 成果输出
资产概览：当前工作区、配置状态、文档库、知识库、技能、助手
供应链进度：5 步纵向流程，显示 0/5 到 5/5
继续任务：任务卡、来源、文件数量、下一步建议、小进度条
最近动态：微时间线
最近成果：成果预览小卡和空状态引导
```

最终一级导航：

```text
首页
工作区
文档库
知识库
文档生成
技能生成
我的助手
设置
```

被移出一级导航但保留能力：

```text
全部成果：由首页最近成果、文档/技能生成结果、我的助手右侧成果入口进入。
操作记录：由首页最近动态、我的助手右侧查看记录、设置高级区进入。
知识库验证：作为知识库内部 Tab，和概览 / 来源 / 引用 / 缺口同级。
```

本轮细节修复：

```text
1. 首页顶部副标题收敛为“查看当前工作区、最近任务、成果与下一步。”
2. Hero 主按钮高度与行高修复，避免“整理资料”按钮裁切。
3. Hero 右侧新增三段式知识资产转化图形：文档资料 -> 知识库 -> 成果输出。
4. 工作区资产面板增加底部留白，避免摘要贴底。
5. 知识供应链步骤间距收敛，避免底部文字裁切。
6. 最近成果空状态强化为成果预览入口。
```

## 5. 主要页面统一

以下页面保留原结构和功能，只套用新组件语言：

```text
文档库 / 我的资料
知识库 / 我的知识库
知识库验证
文档生成
技能生成
全部成果
操作记录
设置
```

保留边界：

```text
未改 Core、runtime、Provider、知识库生成逻辑、文档生成逻辑、成果中心业务逻辑。
未删除功能。
未伪造调用状态或使用记录。
```

## 6. 我的助手工作台

“我的助手”已重构为工作台，而不是普通聊天页：

```text
左侧：助手 / 会话 / 引擎切换
中间：主工作区
右侧：上下文 / 知识库 / 技能 / 阶段摘要 / 成果入口
底部：任务输入 / 运行按钮
```

内部三模式：

```text
助手对话
工作小组
助手配置
```

本轮命名收敛：

```text
单助手对话 -> 助手对话
多个助手一起讨论 -> 工作小组
发起协作 -> 启动工作小组
参与助手 -> 小组成员
任务流程画布 -> 处理流程
```

## 6.1 UI-Core Operation Alignment

Button Runtime Matrix：

```text
docs/audits/current/ui_button_runtime_mapping_matrix.md
web/workbench/flutter_app/output/ui_core_alignment/button_runtime_mapping_matrix.json
```

当前结论：

```text
button_runtime_mapping_mapped_pending_full_exe_click_matrix
ui_core_operation_alignment_mapped_pending_full_exe_click_matrix
ordinary_user_path_validation_mapped_pending_full_exe_click_matrix
industrial_full_product_acceptance_blocked
```

说明：

```text
主要按钮已按 runtime 方法、真实路由、artifact 查看、设置动作或 gated 状态完成映射。
按钮矩阵脚本结果为 completed_with_gated_optional_capabilities_needs_owner_review，主链路真实产物和记录已生成，可选能力保持 gated。
完整 EXE 全按钮点击矩阵尚未覆盖所有控件，因此不写 ui_core_operation_alignment_completed_needs_owner_review。
```

工作小组已改为任务流：

```text
用户任务
主控拆解
检索助手
写作助手
验收助手
汇总结果
成果沉淀
```

真实调用映射：

```text
创建助手 -> completeAgentProductOperations
助手对话 / 发送 -> runAgentDialogue
工作小组 -> runMultiAgentDiscussion
查看 / 打开成果 -> _showWorkspaceArtifactPreview，受真实产物状态约束
导出对话 -> exportAgentDialogue
清空对话 -> clearAgentDialogueHistory
删除助手产物 -> clearAgentArtifacts
```

成果中心边界：

```text
我的助手只显示当前任务成果、最近成果、保存到成果中心、打开成果。
成果分类、成果画廊、成果预览、来源追溯、导出、删除、历史产物管理仍由成果中心负责。
```

## 7. 禁词扫描

扫描范围：

```text
lib/app
lib/shared/product_components.dart
lib/features/dashboard
lib/features/agent
lib/features/document_library
lib/features/knowledge_base
lib/features/artifacts
lib/features/settings
```

结果：

```text
普通用户页面截图未显示 A2A / Token / Gateway / ModelRoute / Runtime 等技术词。
lib/app、lib/features、lib/shared 用户界面层不再命中“测试知识库 / 知识验证 / 成果中心 / 使用记录 / 单助手对话 / 多个助手一起讨论 / 发起协作”等普通 UI 禁词。
剩余禁词命中主要在 rc6_runtime controller 内部运行层、历史 verifier 名和设置高级区配置字段；本轮按边界未改 Core/runtime。
```

## 8. 截图

截图结果 JSON：

```text
web/workbench/flutter_app/output/ui_full_visual_rework/ui_full_campaign_results.json
```

截图目录：

```text
web/workbench/flutter_app/output/ui_full_visual_rework/ui_full_campaign/ui_full_campaign_20260623_235548
```

完整页面截图：

```text
home_light_1440x900.png
home_dark_1440x900.png
document_library_light_1440x900.png
document_library_dark_1440x900.png
knowledge_base_light_1440x900.png
knowledge_base_dark_1440x900.png
knowledge_base_verification_tab_1440x900.png
all_outputs_light_1440x900.png
all_outputs_dark_1440x900.png
settings_advanced_light_1440x900.png
settings_advanced_dark_1440x900.png
my_assistant_single_dialogue_1440x900.png
my_assistant_multi_discussion_1440x900.png
my_assistant_config_1440x900.png
```

组件/局部截图：

```text
home_hero_detail.png
home_hero_asset_glyph_detail.png
workspace_assets_detail.png
knowledge_supply_chain_detail.png
knowledge_internal_verification_tab_detail.png
continue_activity_outputs_detail.png
sidebar_detail_light.png
sidebar_detail_dark.png
topbar_detail_light.png
topbar_detail_dark.png
statusbar_detail_light.png
statusbar_detail_dark.png
button_card_detail_light.png
button_card_detail_dark.png
input_card_detail_light.png
input_card_detail_dark.png
my_assistant_single_center_detail.png
my_assistant_multi_flow_detail.png
my_assistant_context_detail.png
my_assistant_config_detail.png
my_assistant_topbar_title_detail.png
my_assistant_segmented_control_detail.png
my_assistant_sidebar_active_detail.png
my_assistant_statusbar_detail.png
```

截图脚本结果：

```text
command: powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\windows_native_product_verifier\run_ui_full_campaign_matrix.ps1
result: passed
exit code: 0
log path: web/workbench/flutter_app/logs/ui_detail_copy_glyph_screenshots_latest.log
```

按钮矩阵脚本结果：

```text
command: powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\windows_native_product_verifier\run_button_matrix.ps1
result: completed_with_gated_optional_capabilities_needs_owner_review
exit code: 0
log path: web/workbench/flutter_app/logs/ui_final_nav_alignment_button_matrix.log
output: web/workbench/flutter_app/output/industrial_acceptance/button_matrix/button_matrix_20260623_235733
```

## 9. 验证命令

```text
command: dart format selected files
result: passed
exit code: 0
```

```text
command: flutter analyze
result: passed
exit code: 0
log path: web/workbench/flutter_app/logs/ui_final_nav_alignment_flutter_analyze.log
```

```text
command: flutter build windows
result: passed
exit code: 0
log path: web/workbench/flutter_app/logs/ui_final_nav_alignment_flutter_build_windows.log
output: build\windows\x64\runner\Release\heitang_workbench.exe
```

```text
command: git diff --check
result: passed
exit code: 0
log path: web/workbench/flutter_app/logs/ui_final_nav_alignment_git_diff_check.log
note: only LF/CRLF working-copy warnings from Git
```

```text
command: flutter test --concurrency=1
result: test_harness_infrastructure_blocked
exit code: 1
log path: web/workbench/flutter_app/logs/ui_final_nav_alignment_flutter_test.log
detail: WebSocketException, HTTP status code 502; connection closed before test suites loaded
```

## 10. 未完成项

```text
flutter test 无法完成，阻塞在 Flutter 测试 harness WebSocket 502；未伪造通过。
本轮未处理仓库中已有的无关脏改动。
```

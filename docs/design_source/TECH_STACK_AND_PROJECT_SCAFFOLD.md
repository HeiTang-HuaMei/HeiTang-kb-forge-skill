# 技术选型与工程骨架

## 目的

本文件定义从 0 开发黑糖 Knowledge Workbench 时的技术选型和工程骨架。当前项目已存在实现，本文件用于约束后续重建、重构或大修时的方向。

## 当前技术基线

| 层级 | 选型 |
| --- | --- |
| 客户端 | Flutter Desktop / Windows |
| 语言 | Dart SDK >= 3.4.0 < 4.0.0 |
| UI 框架 | Flutter Material |
| 本地文件选择 | `file_selector` |
| 国际化 | `flutter_localizations` |
| 测试 | `flutter_test` |
| 静态规则 | `flutter_lints` |
| 默认运行方式 | `flutter run -d windows` |

当前 `pubspec.yaml` 版本：

```text
heitang_workbench 4.2.0+1
```

## 产品技术原则

- 本地优先。
- 文件型 workspace 可检查、可备份、可恢复。
- 外部服务是增强项，不是基础链路前置条件。
- UI 只展示用户任务和用户结果。
- Runtime 可以保留工程细节，但必须通过产品状态映射给 UI。
- 测试必须能对账 UI、后台真值和重启恢复。

## 目录骨架

```text
web/workbench/flutter_app/
  lib/
    main.dart
    app/
    features/
    shared/
    domain/
    rc6_runtime/
    contracts/
    core_bridge/
    core_actions/
    backend_evidence/
  assets/
    brand/
    contracts/
    workflows/
    fixtures/
    external/
    parser_backends/
  test/
  tool/windows_native_product_verifier/
  windows/
```

## 新项目推荐骨架

如果从 0 开发，应以当前结构为起点，但避免把所有逻辑堆回 `main.dart`。

推荐：

```text
lib/
  main.dart
  app/
    app_shell.dart
    page_registry.dart
    navigation.dart
  features/
    import_sources/
    document_library/
    knowledge_base/
    knowledge_validation/
    document_generation/
    skill/
    agent/
    task_workbench/
    settings/
    artifacts/
  domain/
    workspace/
    source_doc/
    knowledge_base/
    artifact/
    operation_record/
    skill/
    agent/
  services/
    workspace_service.dart
    import_service.dart
    knowledge_base_service.dart
    document_generation_service.dart
    skill_service.dart
    agent_service.dart
    artifact_service.dart
  runtime/
    local_runtime.dart
    external_services/
  storage/
    workspace_store.dart
    json_store.dart
  shared/
    components/
    i18n/
    state_mapping/
```

## 当前项目约束

当前项目不是从 0 开发，因此修复阶段不得强行迁移到推荐骨架。推荐骨架只用于：

- 新模块设计。
- 大重构前的目标结构。
- 判断现有代码职责是否混乱。

当前修复仍以 `CURRENT_CODE_STRUCTURE_MAP.md` 为准。

## 状态管理原则

当前项目以 Flutter stateful UI 和 runtime controller 为主。新开发应遵循：

- 页面状态只保存 UI 所需状态。
- 业务真值由 service/runtime/storage 提供。
- 跨页面对象必须有统一来源。
- 删除、导出、重启恢复不能只改 UI 内存状态。

暂不引入复杂状态管理库，除非出现明确痛点：

- 多页面状态同步失控。
- 大量重复 reload 逻辑。
- 测试无法隔离业务状态。

## 外部服务策略

外部服务包括：

- AI 模型接口。
- Embedding 接口。
- Redis 记忆库。
- 向量数据库。
- 高级文档解析 / OCR。
- 外部连接。

规则：

- 只保存配置状态，不保存密钥明文。
- 不把服务本体打包进 EXE。
- 未配置时基础链路可用。
- 配置错误时失败可解释。
- 普通 UI 不展示底层项目名。

## 构建与运行

开发运行：

```powershell
flutter run -d windows
```

基础分析：

```powershell
flutter analyze
```

Package candidate build 只在明确进入 package candidate 阶段时执行，不作为普通修复默认动作。

## 选型变更规则

新增依赖前必须说明：

- 解决什么具体问题。
- 为什么现有 Flutter/Dart 能力不够。
- 是否影响 Windows packaging。
- 是否影响离线使用。
- 是否增加外部服务边界。
- 如何测试失败、降级和卸载。

没有明确收益，不新增依赖。

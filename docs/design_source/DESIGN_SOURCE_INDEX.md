# 设计源索引

## 目的

本文件是 `docs/design_source` 的入口。开发、修复、验收前先读本文件，再按任务读取对应设计源。

## 阅读顺序

通用顺序：

1. `PRODUCT_SCOPE.md`
2. `USER_TASK_CHAIN_DESIGN.md`
3. `ARCHITECTURE_BOUNDARY_DESIGN.md`
4. `WORKSPACE_AND_DATA_MODEL_DESIGN.md`
5. `TEST_STRATEGY_AND_ACCEPTANCE_MATRIX.md`
6. 当前任务相关专项文件

修复现有问题时：

1. `DEVELOPMENT_REPAIR_RULES.md`
2. `CURRENT_CODE_STRUCTURE_MAP.md`
3. `LOCAL_RUNNING_BASELINE.md`
4. `FIXED_TEST_SAMPLES.md`
5. `DEFINITION_OF_DONE.md`

从 0 开发或大修时：

1. `TECH_STACK_AND_PROJECT_SCAFFOLD.md`
2. `DATA_SCHEMA_AND_STORAGE_SPEC.md`
3. `SERVICE_CONTRACTS.md`
4. `UI_STATE_SPEC.md`
5. `ERROR_AND_RECOVERY_SPEC.md`
6. `IMPLEMENTATION_ROADMAP.md`

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `PRODUCT_SCOPE.md` | 产品边界、一级导航、成果范围 |
| `USER_TASK_CHAIN_DESIGN.md` | 七个主导航任务链 |
| `ARCHITECTURE_BOUNDARY_DESIGN.md` | UI、服务、runtime、storage 边界 |
| `WORKSPACE_AND_DATA_MODEL_DESIGN.md` | 产品数据对象语义 |
| `TEST_STRATEGY_AND_ACCEPTANCE_MATRIX.md` | 测试分层、验收红线 |
| `CURRENT_CODE_STRUCTURE_MAP.md` | 当前真实代码位置 |
| `DEVELOPMENT_REPAIR_RULES.md` | 修复阶段红线 |
| `FIXED_TEST_SAMPLES.md` | 固定样本定义 |
| `LOCAL_RUNNING_BASELINE.md` | latest running UI 证明方式 |
| `TECH_STACK_AND_PROJECT_SCAFFOLD.md` | 技术栈和工程骨架 |
| `DATA_SCHEMA_AND_STORAGE_SPEC.md` | 文件型存储规格 |
| `SERVICE_CONTRACTS.md` | 服务接口契约 |
| `UI_STATE_SPEC.md` | 页面状态规格 |
| `ERROR_AND_RECOVERY_SPEC.md` | 错误与恢复策略 |
| `IMPLEMENTATION_ROADMAP.md` | 实施路线 |
| `DEFINITION_OF_DONE.md` | 完成标准 |
| `GLOSSARY.md` | 统一术语 |
| `SECURITY_AND_PERMISSION_BOUNDARY.md` | 安全与权限边界 |
| `CONFIGURATION_SPEC.md` | 配置项规格 |
| `I18N_AND_COPYWRITING_SPEC.md` | 双语和文案规范 |
| `OBSERVABILITY_AND_DIAGNOSTICS_SPEC.md` | 日志、操作记录、诊断包 |
| `MIGRATION_AND_COMPATIBILITY_SPEC.md` | 数据迁移和兼容 |
| `ACCEPTANCE_RUN_TEMPLATE.md` | 验收执行模板 |
| `BUG_REPORT_TEMPLATE.md` | 缺陷记录模板 |
| `FIX_REPORT_TEMPLATE.md` | 修复报告模板 |
| `OWNER_RETEST_SCRIPT.md` | Owner 复验脚本 |
| `DEVELOPMENT_WORKFLOW.md` | 开发协作流程 |

## 冲突优先级

当文件冲突时，优先级如下：

1. 当前用户明确边界。
2. `PRODUCT_SCOPE.md`。
3. `DEVELOPMENT_REPAIR_RULES.md` 或 `TECH_STACK_AND_PROJECT_SCAFFOLD.md`。
4. `USER_TASK_CHAIN_DESIGN.md`。
5. `ARCHITECTURE_BOUNDARY_DESIGN.md`。
6. `DATA_SCHEMA_AND_STORAGE_SPEC.md` / `SERVICE_CONTRACTS.md`。
7. 历史 PRD、架构文档、审计报告。

历史审计报告是证据，不是新的产品设计源。

## 编码前检查

编码前必须确认：

- 当前任务属于哪个主导航或服务。
- 改动是否违反产品边界。
- 是否需要 running UI 验证。
- 是否涉及数据删除、迁移或外部服务。
- 是否需要固定样本。
- 完成标准是什么。

如果回答不清楚，先补设计或定位，不编码。

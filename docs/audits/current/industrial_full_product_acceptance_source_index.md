# 工业级全量产品验收材料索引

生成日期：2026-06-22

Gate：`industrial_full_product_acceptance_gate`

## 1. 读取范围

本轮只读取并索引 gate 指定材料，不修改产品代码、不修改 UI、不修改 runtime。

已检查路径：

```text
docs/product/
docs/architecture/
docs/dev/
docs/testing/
docs/audits/current/
web/workbench/flutter_app/tool/windows_native_product_verifier/
web/workbench/flutter_app/pubspec.yaml
```

## 2. 产品与验收依据

| 材料 | 状态 | 用途 |
| --- | --- | --- |
| `docs/product/PRD.md` | found | PRD 指针 |
| `docs/product/PRD_V3_2026-06-19.md` | found | 产品需求与完整用户流程 |
| `docs/product/PRODUCT_ARCHITECTURE.md` | found | 产品架构指针 |
| `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md` | found | 产品架构、主链路、页面架构 |
| `docs/product/FEATURE_ACCEPTANCE_MATRIX.md` | found | 功能验收矩阵指针 |
| `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md` | found | 工业级功能评审 / 验收矩阵 |
| `docs/testing/PRODUCT_ACCEPTANCE_CHECKLIST.md` | found | Product Verifier 黑盒验收标准 |
| `docs/dev/PRODUCT_VERIFIER_AGENT_SPEC.md` | found | Product Verifier 角色与证据要求 |
| `docs/dev/WRITER_REVIEWER_VERIFIER_WORKFLOW.md` | found | Writer / Reviewer / Verifier 工作流 |
| `docs/dev/WRITER_REVIEWER_VERIFIER_GATE.md` | missing | 指令中提到但仓库未找到；使用 workflow 文档替代索引 |
| `docs/dev/HEITANG_LAZY_BUILDER_GATE.md` | found | 后续修复前置工程纪律 |
| `docs/product/USER_PATH_FIRST_UI_GOVERNANCE.md` | found | 普通用户路径和 UI 治理 |

## 3. 架构与规划材料

| 材料 | 状态 | 用途 |
| --- | --- | --- |
| `docs/architecture/KNOWLEDGE_SEMANTIC_LAYER.md` | found | 知识语义层规划 |
| `docs/architecture/OPENCLI_SOURCE_CONNECTOR_AUDIT.md` | found | OpenCLI Source Connector 盘点 |
| `docs/architecture/SOURCE_ACQUISITION_LAYER_OPENCLI_ALIGNMENT.md` | found | Source Acquisition Layer 对齐 |
| `docs/architecture/系统架构.md` | found | 系统架构指针 |
| `docs/architecture/知识供应链架构.md` | found | 知识供应链架构 |
| `docs/architecture/路线图.md` | found | 路线图 |

## 4. 当前发布与 Smoke 证据报告

| 材料 | 状态 | 结论引用 |
| --- | --- | --- |
| `docs/audits/current/release_candidate_gate_report.md` | found | `release_candidate_verified` |
| `docs/audits/current/tag_candidate_gate_report.md` | found | `v4.2.0-rc.1` created |
| `docs/audits/current/release_upload_gate_report.md` | found | RC ZIP prepared, RC tag pushed |
| `docs/audits/current/windows_exe_smoke_acceptance_report.md` | found | Windows native smoke passed |
| `docs/audits/current/product_smoke_bugfix_report.md` | found | path import / verifier unblock |
| `docs/audits/current/windows_exe_smoke_automation_unblock_report.md` | found | Computer Use blocked, native verifier used |
| `docs/audits/current/windows_exe_smoke_blocker_fix_report.md` | found | native automation blocker analysis |
| `docs/audits/current/full_product_regression_before_packaging_report.md` | found | packaging 前回归通过 |
| `docs/audits/current/full_interaction_operability_and_industrial_readiness_report.md` | found | interaction / readiness 引用 |
| `docs/audits/current/full_crud_real_io_acceptance_matrix.md` | found | CRUD 验收矩阵 |
| `docs/audits/current/ui_acceptance_gate_report.md` | found | UI Owner Acceptance |

## 5. 自动化工具

| 工具 | 状态 | 用途 |
| --- | --- | --- |
| `web/workbench/flutter_app/tool/windows_native_product_verifier/run_windows_exe_smoke.ps1` | found | Windows 原生 EXE 黑盒 Smoke |

## 6. 版本来源

| 文件 | 状态 | 版本 |
| --- | --- | --- |
| `web/workbench/flutter_app/pubspec.yaml` | found | `4.2.0+1` |

## 7. 缺失或不完整材料

| 项 | 状态 | 影响 |
| --- | --- | --- |
| `docs/dev/WRITER_REVIEWER_VERIFIER_GATE.md` | missing | 不阻断读取；已有 `WRITER_REVIEWER_VERIFIER_WORKFLOW.md` 可作为治理依据 |
| 使用记录逐条导出证据 | incomplete | 本轮 EXE verifier 只能证明页面统计与历史文件，不能逐条映射每个动作 |
| 逐按钮可访问性清单 | incomplete | Flutter 桌面控件语义树未被 Windows 原生自动化完整读取 |


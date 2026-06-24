# 产品能力盘点与阻断确认报告

## Gate 结论

本次只执行 `product_capability_inventory_gate`，未进入 Redis / 向量库、外部 Skill、Agent runtime、A2A、热插拔配置的功能修补。

当前产品能力状态修正并保持为：

```text
industrial_acceptance_product_capability_blocked
allowed_next_gate: product_capability_completion_gate
```

Gate 0 完成状态：

```text
product_capability_inventory_completed
allowed_next_gate: connector_io_completion_gate
```

## 盘点依据

读取范围覆盖：

- `docs/product/`
- `docs/architecture/`
- `docs/testing/`
- `docs/audits/current/`
- `web/workbench/flutter_app/lib/`
- `web/workbench/flutter_app/tool/windows_native_product_verifier/`

关键依据：

- PRD 与功能验收矩阵已承诺 Redis / 向量库配置、外部 Skill 导入、单 Agent 工作区、A2A 多 Agent、配置 CRUD、使用记录和成果中心。
- `industrial_acceptance_product_capability_blocker_report.md` 已明确上一轮 optional gate 不能作为工业级全量验收依据。
- `agent_dialogue_console_and_home_layout_repair_report.md` 已明确 Agent 对话台仍处于布局修复失败状态。
- runtime 已存在部分真实 IO、外部 Skill、Agent 对话、A2A、热插拔配置、审计和产物中心代码路径，但多个能力仍需要后续 Gate 做黑盒自动化验收闭环。

## 能力盘点矩阵

| 能力 | 当前状态 | 是否产品承诺 | 是否必须补齐 | 是否可 gate | 验收方式 | 下一 Gate |
| --- | --- | --- | --- | --- | --- | --- |
| Redis | 部分实现。runtime 已有 `testRedisConnection`，覆盖 PING、临时 key 写入、读取、删除，并持久化测试结果；设置页和 verifier 已有连接矩阵。但尚未在本 Gate 对当前外部服务做真实黑盒读写确认。 | 是。PRD / 验收矩阵承诺 Redis 配置、Agent 短期记忆、A2A 状态和连接测试。 | 是。若服务已配置且可达，必须真实读写通过。 | 仅服务未启动、地址未配置、端口不可达或本地模式时可 gate。 | `run_redis_connection_matrix.ps1`，确认容器/端口、App 配置、UI 测试连接、runtime 写入读取删除、使用记录。 | connector_io_completion_gate |
| 向量库 | 部分实现。runtime 已有 `testQdrantConnection`，覆盖 healthz、临时 collection、向量写入、检索、删除；verifier 已有向量库连接矩阵。但尚未在本 Gate 对当前外部服务做真实黑盒检索确认。 | 是。PRD / 架构承诺外部向量库按配置启用，可绑定 KB / Agent。 | 是。若服务已配置且可达，必须创建 collection、写入、检索、清理。 | 仅服务未启动、地址未配置、端口不可达或本地模式时可 gate。 | `run_vector_db_connection_matrix.ps1`，确认容器/端口、App 配置、UI 测试连接、runtime 写入检索清理、使用记录。 | connector_io_completion_gate |
| 外部 Skill 导入 | 部分实现。runtime 已有 `importExternalSkillPath`、最小字段校验、危险内容拒绝、成功/失败记录；verifier 已有合法、重复、非法、缺字段、危险样本矩阵。仍需 Gate 2 复核导入后列表刷新、Agent 绑定和重复策略是否完整稳定。 | 是。PRD / 验收矩阵承诺外部 Skill 导入、本地化、绑定 Agent。 | 是。不能只保留按钮或 gated 展示。 | 不可整体 gate；仅前置 KB / Skill 运行条件缺失时可显示需要设置。 | `run_external_skill_import_matrix.ps1`，覆盖合法导入、重复策略、非法拒绝、缺字段拒绝、危险覆盖拒绝、使用记录。 | external_skill_import_completion_gate |
| 单 Agent 对话 | 部分实现且 UI 阻断。runtime 已有 `runAgentDialogue`，可写入 `chat_history.jsonl`、引用 trace、Skill rule trace、对话 Markdown 和运行记录；但 Agent 对话台当前报告为布局修复失败，Agent B 切换与 Agent A 上下文恢复未通过黑盒验证。 | 是。PRD / 架构承诺单 Agent 工作区、KB/Skill 绑定、可对话、来源引用和审计。 | 是。默认主路径必须是单 Agent 对话。 | 模型服务未配置时可显示需要设置 / 本地模式；线程隔离和工作区隔离不可假成功。 | `run_agent_console_matrix.ps1` 及后续 agent runtime 验收，覆盖 Agent A/B/C 线程、输入草稿、引用、执行状态、工作区隔离、使用记录、成果中心。 | agent_runtime_completion_gate |
| A2A / 多助手协作 | 部分实现。runtime 已有 `runMultiAgentDiscussion` 和 A2A 产物/记录路径；verifier 已有 `run_a2a_10_agents_matrix.ps1`，可检查参与 Agent 数、任务记录、失败隔离、产物和使用记录。但当前 Agent 对话台报告仍显示多助手协作任务流截图未通过，不能写成工业级完成。 | 是。PRD / 架构承诺 A2A 在总工作区运行，子 Agent 独立工作区，多轮协作和报告。 | 是。必须达到同一工作区 >=10 Agent 注册 / 选择 / 编排 / 协作。 | 模型服务不足时可显示需要设置 / 暂不可用 / 本地模式；不能把 2 Agent demo 写成通过。 | `run_a2a_10_agents_matrix.ps1` 和 Agent console UI 验收，覆盖 >=10 Agent、任务状态、失败隔离、输入输出引用、产物落盘、使用记录、工作区/记忆隔离。 | a2a_10_agents_completion_gate |
| 热插拔配置 | 部分实现。runtime 已有 ProjectConfigProfile 创建、复制、更新、激活、删除、回滚和持久化 smoke；verifier 已有 `run_hotplug_config_matrix.ps1`。但现有脚本仍将 Redis / 向量库、Skill、Agent、A2A、记忆等多项隔离记为 gated / not_implemented，不能作为完成。 | 是。功能验收矩阵承诺工作区配置 CRUD、Redis / 向量库配置 CRUD 和配置审计。 | 是。必须补齐 A/B 隔离、启用禁用、回滚、损坏 fallback 和删除确认。 | 外部服务不可达时可 gate；配置隔离、回滚、删除确认不可假成功。 | `run_hotplug_config_matrix.ps1`，后续需扩展覆盖 Redis / 向量库 / Skill / Agent / A2A / 记忆配置 A/B 隔离、禁用恢复、损坏 fallback、二次确认。 | hotplug_project_config_completion_gate |
| 使用记录 | 部分实现。runtime `generateAuditReport`、Agent/Skill/config 相关历史记录和 verifier 均存在；但 `run_usage_mapping_matrix.ps1` 仍把外部 Skill、A2A、删除、设置失败等多项作为 gated 或依赖后续矩阵，不能写成全量映射通过。 | 是。PRD / 验收矩阵承诺 Agent 运行审计、A2A 审计、配置审计和产物记录。 | 是。所有可用能力必须逐条真实映射。 | 未配置能力可 gate；已执行动作不能缺记录。 | 结合各 Gate 的专项 verifier 和 `run_usage_mapping_matrix.ps1`，核验成功、失败、完成、删除、连接测试、协作事件逐条记录。 | usage_record_mapping_completion_gate |
| 成果中心 | 部分实现。产物中心、审计中心和 runtime artifact records 已能收集多类真实本地产物；Agent 对话、A2A、Skill、文档等也有产物路径。但 A2A、外部 Skill、Agent runtime、热插拔补齐前，成果映射不能声明全量完成。 | 是。PRD / 架构承诺文档、Skill、Agent、A2A 报告统一进入产物层 / 产物中心。 | 是。所有可用产物必须能追踪、预览或导出。 | 无真实产物时只能 gate / not_run，不能伪造成果中心数据。 | 结合产物中心 UI、audit artifact rows、各专项 verifier 产物文件存在性与导出记录。 | artifact_mapping_completion_gate |

## 当前阻断分类

| 分类 | 能力 |
| --- | --- |
| 已有实现但需要真实外部服务验收 | Redis、向量库 |
| 已有实现但需要专项黑盒闭环 | 外部 Skill 导入、A2A >=10 Agent、使用记录、成果中心 |
| 已有本地最小能力但 UI / 线程隔离仍阻断 | 单 Agent 对话 |
| 已有 Profile 基础能力但隔离矩阵不足 | 热插拔配置 |

## 不能继续按 optional gate 处理的原因

1. A2A、外部 Skill、Redis、向量库、Agent 对话已出现在产品 PRD、架构和验收矩阵中，不是单纯展示项。
2. 现有 runtime 代码说明能力正在产品路径内，但 Gate 0 未执行真实端到端验收，不能把实现痕迹写成通过。
3. 当前 Agent 对话台仍有黑盒阻断，不能进入工业级全量验收。
4. 使用记录和成果中心依赖各专项能力真实执行，不能先于能力补齐宣布完成。

## 下一步

严格进入：

```text
connector_io_completion_gate
```

下一 Gate 只处理 Redis / 向量库真实连接补全与验收。若外部服务未配置或不可达，报告必须写成 `connector_io_completion_passed_with_external_service_gates`；若服务已配置但真实读写失败，必须写成 `connector_io_completion_blocked`。

不得进入：

```text
industrial_full_product_acceptance_gate
final_owner_acceptance_gate
GitHub Release
stable tag
official release
```

# Agent 对话台 UI reset rebuild 报告

## 当前状态

本轮执行 `agent_console_ui_reset_rebuild_gate`，不再继续局部修补旧 Agent 页面结构。

修复后的 UI Gate 状态：

```text
agent_console_ui_reset_rebuild_completed_needs_owner_review
allowed_next_gate: product_capability_completion_sequence
```

本状态只代表 Agent 对话台 UI reset rebuild 已完成复核并等待 Owner review。Redis / 向量库、外部 Skill 导入、Agent runtime、A2A >=10 Agent 真实编排、热插拔配置仍按 `product_capability_completion_sequence` 逐 Gate 补齐。

## 为什么不再局部修补

上一轮布局虽然拆出了 `助手管理 / Agent 对话台`，但旧实现仍残留多层入口、小对话卡、状态卡占位和浮层式左右面板。1280x720 下输入区固定、Agent B/C 线程切换、多助手任务流、左右抽屉差异都缺稳定证据。

因此本轮替换失败 UI 骨架，保留 Agent 数据、Skill 绑定、使用记录、成果中心和设置 gate 接口。

## AgentHub 参考边界

本轮把 `https://github.com/awesdfr/bitdance-agenthub` 仅作为产品形态参考，不接入代码、不新增技术栈、不写成已集成。

吸收的交互原则：

1. Agent 工作台应是 IM 式会话空间，而不是 Agent 管理面板。
2. 左侧是 Agent / 会话列表，中间是大对话流，右侧是工作区上下文 / 文件 / 成果 / 任务。
3. 消息可承载文本、执行步骤、工具过程、引用来源和产物引用。
4. 多助手协作使用 Orchestrator 任务流表达：任务输入、Agent 选择、执行流、状态、结果入口。
5. 会话、Agent、工作区、产物和使用记录必须隔离。

未吸收内容：AgentHub 技术栈、SDK 适配器、数据库结构、移动伴随端和完整 Orchestrator runtime。

## 重建结果

1. `我的助手` 只保留两个内部页：`助手管理` 与 `Agent 对话台`。
2. 默认进入 `Agent 对话台 -> 单 Agent 对话`。
3. Agent 对话台内部只保留两个模式：`单 Agent 对话` 与 `多助手协作`。
4. `助手列表` 不再作为 tab，小窗口下作为抽屉，大/中窗口下作为左侧栏。
5. 中间对话区采用标题栏、消息流、固定底部输入区结构。
6. 右侧上下文面板在 1366px 以下默认收起，通过抽屉打开。
7. 本地示例线程明确标记为本地示例，不伪装成外部模型运行完成。
8. Agent A/B/C 线程、草稿、引用来源和执行状态按本地 UI 状态隔离。
9. 多助手协作从静态表格改为任务流，UI 选择区展示 11 个 Agent。
10. 全局 UI 字号整体调小约一号，按钮、Chip、输入框标签同步压缩。

## 自动化验收结果

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| flutter analyze | passed | `web/workbench/flutter_app/analyze_agent_console_ui_reset.log` |
| flutter build windows | passed | `web/workbench/flutter_app/build_agent_console_ui_reset.log` |
| Agent console matrix | passed | `web/workbench/flutter_app/output/agent_console_second_repair/agent_console_results.json` |
| 默认进入 Agent 对话台 | passed | `agent_console_results.json` |
| 默认模式为单 Agent 对话 | passed | `agent_console_results.json` |
| 1280x720 输入区固定底部 | passed | `agent_console_results.json` |
| 1366x768 右侧上下文默认收起 | passed | `agent_console_results.json` |
| 1600x900 三栏稳定 | passed | `agent_console_results.json` |
| 左侧 Agent 列表抽屉差异 | passed | `agent_console_results.json` |
| 右侧上下文抽屉差异 | passed | `agent_console_results.json` |
| Agent B 线程切换 | passed | `agent_console_results.json` |
| Agent C 线程切换 | passed | `agent_console_results.json` |
| 切回 Agent A 上下文保留 | passed | `agent_console_results.json` |
| 长上下文消息列表 | passed | `agent_console_results.json` |
| 多助手协作任务流 | passed | `agent_console_results.json` |
| 10+ Agent 选择区或正确 gate | passed | `ui_participant_count=11; runtime_participant_count=0` |
| raw technical error | passed | 截图区域未出现 raw error |

最新矩阵输出目录：

```text
web/workbench/flutter_app/output/agent_console_second_repair/agent_console/agent_console_20260623_162804
```

## 验收边界

本轮黑盒验收验证的是 Agent 对话台 UI 承载能力：

```text
单 Agent 对话默认主路径
中间对话区优先
输入区固定底部
长上下文消息列表可读
左侧 Agent 列表可打开
右侧上下文可打开
Agent A/B/C 线程切换不串
多助手协作是任务流而不是静态表格
```

当前 runtime 产物状态仍需进入后续能力补全：

```text
runtime_participant_count=0
agent_dialogue artifact=false
a2a artifact=false
```

这不是 UI reset gate 的阻断，但必须在 `product_capability_completion_sequence` 中继续补齐，不能写成完整产品能力已完成。

## 底座级扩展点预留

当前版本只实现“知识生产 + Agent 工作台”。后续学习软件、项目说明书、企业知识库、内容工厂只作为 vNext 应用层方向。

本轮允许保留的只是底座级扩展边界：

```text
SourceType
ArtifactType
TemplateType
SkillCategory
AgentRole
WorkspaceType
UsageEventType
ConnectorType
```

预留口径：

1. 只预留接口、数据结构、类型枚举、目录边界、配置边界、成果类型、使用记录类型。
2. 不暴露学习软件、GitHub 项目说明书、企业知识库、内容工厂的 UI 入口。
3. 不实现学习路径、课程中心、企业权限、知识审批、内容选题、脚本生成、分镜、发布复盘等 runtime。
4. 不为未来功能写假数据，不把预留类型写成当前已完成能力。
5. 如果不留会导致后续底座大改，可以留 schema / enum / registry；如果会增加当前功能复杂度或让用户看到不可用入口，则不留。

## 后续允许进入

Agent 对话台 UI reset rebuild Gate 已完成复核，下一步仍按目标模式进入：

```text
product_capability_completion_sequence
```

后续顺序仍为：

```text
product_capability_inventory_gate
→ connector_io_completion_gate
→ external_skill_import_completion_gate
→ agent_runtime_completion_gate
→ a2a_10_agents_completion_gate
→ hotplug_project_config_completion_gate
→ product_capability_completion_summary_gate
→ industrial_full_product_acceptance_gate
```

本轮未创建任何发布或 tag，未进入全量工业级验收。

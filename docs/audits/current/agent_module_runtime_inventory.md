# Agent Module Runtime Inventory

Status before repair:

```text
agent_module_runtime_blocked
single_agent_crud_blocked
single_agent_chat_blocked
agent_group_a2a_blocked
```

This inventory is Gate 1.1 for `agent_module_p0_runtime_repair_gate`. It is a runtime reality inventory, not an acceptance pass.

## Summary

| Module | Entry | Source | UI exists | Button exists | Real action | Persistence | Runtime/service | Current error | Priority | Conclusion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 创建助手 | 我的助手 / 助手配置 | `lib/features/agent/agent_product_workflow.dart` | yes | yes | partial: creates generated Agent artifacts, not user Agent catalog records | fixed generated artifact paths only | `completeAgentProductOperations`, `generateAgent` | user-created assistant cannot be listed, edited, or deleted as a profile | P0 | blocked |
| 助手列表 | 我的助手左侧 | `agent_product_workflow.dart` | yes | n/a | no real user list | no user catalog | local hardcoded `_agents(runtime)` | built-in templates and local sample threads are shown as assistants | P0 | mock / demo |
| 助手详情 | 我的助手 | `agent_product_workflow.dart` | partial | partial | no dedicated user profile detail | no profile persistence | not found | selected item is a template row, not a user record | P0 | blocked |
| 助手配置 | 我的助手 / 助手配置 | `agent_product_workflow.dart` | yes | yes | partial artifact generation config | generated Agent artifact config only | `Rc6AgentGenerationConfig` | cannot edit saved user assistant config | P0 | blocked |
| 编辑助手 | 我的助手 / 助手配置 | `agent_product_workflow.dart` | partial | no dedicated edit/save existing profile | no | no user profile persistence | not found | no edit lifecycle | P0 | not_found |
| 删除助手 | 我的助手 / 助手配置 | `agent_product_workflow.dart` | yes | yes | deletes all Agent artifacts, not a selected user assistant | no selected profile delete | `clearAgentArtifacts` | destructive scope too broad for single assistant CRUD | P0 | blocked |
| 删除确认 | 我的助手 / 助手配置 | `agent_product_workflow.dart` | yes | yes | partial | n/a | `_confirmDestructiveAction` | confirmation exists, but target is artifact folder not user assistant | P0 | partial |
| 绑定知识库 | 我的助手 / 助手配置 | `agent_product_workflow.dart` | partial | no profile-level bind controls | no | no user profile binding persistence | runtime state reads existing KB artifacts | binding is displayed from global runtime, not saved to an assistant profile | P2 | blocked |
| 绑定技能 | 我的助手 / 助手配置 | `agent_product_workflow.dart` | partial | no profile-level bind controls | no | no user profile binding persistence | runtime state reads existing Skill artifacts | binding is displayed from global runtime, not saved to an assistant profile | P2 | blocked |
| 单助手对话 | 我的助手 / 助手对话 | `agent_product_workflow.dart`, `rc6_runtime_controller_io.dart` | yes | yes | partial fixed generated Agent dialogue | `agent/dialogue/chat_history.jsonl` | `runAgentDialogue` | requires generated Agent/Skill; not tied to user-created assistant profile | P1 | blocked |
| 消息发送 | 我的助手 / 助手对话 | `agent_product_workflow.dart` | yes | yes | partial | local UI thread plus fixed runtime dialogue | `_sendPrompt`, `runAgentDialogue` | UI appends local messages and generated response text; not profile conversation persistence | P1 | mock / demo |
| 消息历史保存 | 我的助手 / 助手对话 | `rc6_runtime_controller_io.dart` | n/a | n/a | partial | fixed `agent/dialogue/chat_history.jsonl` | `runAgentDialogue` | one global dialogue history, no per-assistant conversation history | P1 | blocked |
| 保存到成果 | 我的助手右侧 / 成果入口 | `agent_product_workflow.dart`, artifact center | partial | partial | partial export/open only | artifact exports available after dialogue export | `exportAgentDialogue`, `exportWorkspaceArtifact` | no save selected assistant reply as artifact | P4 | blocked |
| 工作小组入口 | 我的助手 / 工作小组 | `agent_product_workflow.dart` | yes | yes | can call multi-agent artifact generator | `multi_agent/...` | `runMultiAgentDiscussion` | must be gated until single Agent runtime is ready | P5 | blocked |
| A2A / 多助手协作入口 | 我的助手 / 工作小组 | `agent_product_workflow.dart` | yes | yes | partial artifact generation | `multi_agent/...`, A2A session manifests | `runMultiAgentDiscussion` | UI can appear available before single Agent CRUD works | P5 | blocked |
| Agent 数据模型 | Runtime state | `rc6_runtime_controller_stub.dart`, `rc6_runtime_controller_io.dart` | n/a | n/a | generated config only | no user catalog | `Rc6AgentGenerationConfig` | missing user Agent model with id/name/description/role/bindings/settings | P0 | not_found |
| Agent 持久化 | Runtime IO | `rc6_runtime_controller_io.dart` | n/a | n/a | fixed generated artifacts | no user catalog | not found | missing local profile CRUD repository | P0 | not_found |
| Agent service / repository | Runtime IO | `rc6_runtime_controller_io.dart` | n/a | n/a | generated artifact methods only | no user profile repository | not found | missing create/update/delete/list profile service | P0 | not_found |
| Conversation service | Runtime IO | `rc6_runtime_controller_io.dart` | n/a | n/a | fixed global chat history | no per-agent conversation | `runAgentDialogue` | missing per-agent conversation service | P1 | blocked |
| Message model | Runtime state | `rc6_runtime_controller_stub.dart`, `rc6_runtime_controller_io.dart` | n/a | n/a | no reusable user message model | fixed JSONL turn map only | not found | missing typed message model | P1 | not_found |
| 操作记录写入 | Runtime IO | `rc6_runtime_controller_io.dart` | n/a | n/a | partial | `agent/audit/run_history.json` and orchestration records | `_appendAgentRunHistoryRecord` | not wired to user Agent CRUD actions | P3 | partial |
| 最近动态联动 | 首页 / 最近动态 | `dashboard_product_workflow.dart` | yes | n/a | partial state-derived | audit/state artifacts | dashboard reads runtime state | user Agent CRUD events cannot appear because they are not written | P3 | blocked |
| 最近成果联动 | 首页 / 最近成果 | `dashboard_product_workflow.dart`, artifact center | yes | n/a | partial | runtime artifact paths | artifact center reads runtime paths | assistant reply save-as-artifact missing | P4 | blocked |
| 错误提示 | 我的助手 | `agent_product_workflow.dart` | yes | yes | partial | n/a | runtime `_fail` and UI gates | ordinary UI still tied to generate Agent/Skill wording | P1 | partial |
| 未配置状态 | 我的助手 | `agent_product_workflow.dart` | yes | yes | partial | n/a | runtime state | must distinguish user profile exists vs external model unconfigured | P1 | partial |

## Repair Direction

1. Add a local user Agent catalog in the runtime layer.
2. Add per-Agent conversation persistence.
3. Wire create/edit/delete/save config to the catalog, not to generated artifact folder deletion.
4. Keep generated Agent package support, but do not treat it as user Agent CRUD.
5. Gate work group execution until single-Agent runtime is usable.

## Post-Repair Inventory Update

Updated after the Agent P0 runtime repair slice:

| Capability | Evidence | Current conclusion |
| --- | --- | --- |
| Agent local model | `Rc6AgentProfile`, `Rc6AgentConversation`, `Rc6AgentMessage` added in runtime IO/stub | partial |
| Agent catalog persistence | `agent/catalog/agents.json` read/write via runtime IO | partial, needs owner black-box reopen verification |
| Create assistant | UI calls `createAgentProfile` and selects created profile | partial, needs EXE click verification |
| Edit/save assistant config | UI calls `updateAgentProfile`; KB/Skill ids persist on profile | partial, needs EXE click verification |
| Delete assistant | UI calls `deleteAgentProfile` after confirmation; conversation file removed | partial, needs EXE click verification |
| Single assistant chat | UI calls `sendAgentMessage`; per-agent `conversation.json` persists user and assistant messages | partial, uses clearly labeled local fallback until connection is configured |
| Save reply to artifact | UI calls `saveAgentReplyToArtifact`; writes markdown and `agent/artifacts/artifact_catalog.json` | partial, needs artifact open/recent-output verification |
| Agent activity | CRUD/chat/artifact actions append `agent/activity/agent_activity.jsonl` and Agent run history | partial, dashboard recent-dynamics linkage not fully black-box verified |
| Work group / A2A | Start button disabled with ordinary UI degradation text | agent_group_a2a_deferred_until_single_agent_ready |

The current repair does not prove full product acceptance. It only closes the local single-Agent runtime path enough for owner black-box lifecycle verification.

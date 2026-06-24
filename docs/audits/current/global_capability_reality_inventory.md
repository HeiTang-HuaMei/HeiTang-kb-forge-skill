# Global Capability Reality Inventory Gate

Status:

```text
global_capability_reality_inventory_completed_needs_owner_review
industrial_full_product_acceptance_blocked
```

This gate is a capability reality inventory, not a product acceptance pass. It does not use screenshots, `flutter analyze`, `flutter build windows`, UI presence, or button mapping as proof of runtime closure.

Conclusion rule:

```text
Only a complete blackbox lifecycle can be marked passed_by_blackbox_lifecycle.
UI-only, mock-only, partial, blocked, and not_verified do not count as passed.
```

## Inventory Summary

| Capability | Runtime evidence | Persistence / artifact evidence | Mock or demo risk | Current conclusion |
| --- | --- | --- | --- | --- |
| 文档库：添加 / 查看 / 删除 / 重新进入 | `pickAndImportFile`, `pickAndImportFolder`, `importLocalPath`, `deleteImportedSource` exist. | `source_manifest.json`, imported input files, state reload from manifest. | No static source rows found in primary library path. | partial |
| 资料整理：整理 / 输出 / 失败提示 | `parseAndChunkSources` exists. | `du/document_understanding_manifest.json`, `parse_report.json`, source records. | Needs blackbox reload and failure proof. | partial |
| 知识库：生成 / 打开 / 持久化 / 删除 | `buildKnowledgeBase`, `buildKnowledgeBaseFromStandardPackage`, `deleteKnowledgeBaseRecord` exist. | `kb/manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `knowledge_bases/kb_catalog.json`. | Needs lifecycle proof after delete/re-enter. | partial |
| 知识库验证：验证 / 报告 / 引用 / 缺口 | `searchKnowledgeBases`, `saveRetrievalValidationReport` exist. | `query/validation_report.json`, `validation_history.jsonl`, citation/conflict reports. | Verification tab may reflect retrieval artifacts, not a full blackbox validation run. | partial |
| 文档生成：生成 / 保存草稿 / 导出 / 打开成果 | `generateMarkdown`, `saveEditedDocument`, `exportDocumentFormat` exist. | `doc/generation_manifest.json`, `doc/edited_document.md`, export manifests. | Needs end-to-end artifact open/re-enter proof. | partial |
| 技能生成：生成 / 验证 / 导出 / 绑定助手 | `generateSkill`, `runSkillOperation`, `saveEditedSkill` exist. | `skill/skill_generation_manifest.json`, operation manifests/history, exports. | Needs generated Skill re-open, validation, export, binding lifecycle proof. | partial |
| 我的助手：创建 / 编辑 / 删除 / 对话 / 绑定 / 保存成果 | Single-agent catalog, conversation, configured LLM reply, binding visibility, and saved reply artifact were blackbox verified in EXE. | `agent/catalog/agents.json`, per-agent `conversation.json`, `agent/artifacts/artifact_catalog.json`, `agent/activity/agent_activity.jsonl`. | Delete confirmation and cleanup/orphan verification were not executed. | partial |
| 工作小组：启动 / 阶段摘要 / 最终成果 / 降级状态 | Work Group is intentionally gated while P0 single-agent delete path remains incomplete. | Historical work-group artifacts can exist, but current UI is downgraded. | Rebuilt EXE confirmed right-side action is disabled; full work-group lifecycle is not implemented in this pass. | partial |
| 成果：真实 artifact / 打开 / 删除 / 最近成果 | Artifact center exports selected workspace artifacts. | Reads runtime artifact paths and writes `artifact_exports/.../export_manifest.json`. | Result list is state-derived but lifecycle deletion/reload not fully blackbox proven. | partial |
| 操作记录：真实事件 / 最近动态 / 失败事件 | `exportAuditReport` exists and some module histories exist. | Audit report is generated from current state plus history files. | Some recent activity is state-derived snapshot rather than a strict append-only event ledger. | partial |
| 设置：保存配置 / 测试连接 / 高级设置 | `saveStorageProviderSettings`, project config profile actions, Redis/Qdrant tests exist. | Config JSON, profile logs, validation reports. | External environment not blackbox verified in this gate. | partial |
| 外部连接：LLM / Redis / 向量库 / 路径权限 | Redis/Qdrant probe methods and provider runtime settings exist. | Provider/storage settings and validation artifacts. | Requires real configured endpoints; not proven by code scan. | not_verified |
| 外部 Skill 导入：校验 / 导入 / 绑定 / 失败处理 | `pickAndImportExternalSkill`, `importExternalSkillPath` exist. | Localized external Skill manifests and validation output. | Needs valid/invalid Skill blackbox matrix. | partial |
| 热插拔项目配置：项目 A/B 隔离 | Project config profile CRUD/test/activate/rollback methods exist. | Profile JSON, activation logs, runtime status assets. | Workspace/Agent/Skill/output isolation must be blackbox verified. | partial |
| 导出：真实文件 / 路径 / 失败提示 | Document export and artifact export methods exist. | Export directories, generated file reports, artifact export manifests. | Requires file existence/open-path and failure-state blackbox proof. | partial |

## Critical Findings

1. Agent is not an isolated issue. It is the clearest example of a broader acceptance gap: UI presence and runtime method existence do not prove user lifecycle closure.
2. Agent P0 has moved from `blocked` to `partial`: create/edit/reload/chat/bind/save-output were verified, but delete confirmation and cleanup/orphan verification remain blocked.
3. Runtime methods exist for many core capabilities, but most are currently only `partial` because this gate did not execute destructive or full lifecycle blackbox paths.
4. Recent activity and audit evidence need extra care: snapshot-style records are useful, but they are not equivalent to a strict event ledger for every user action.
5. No global product capability is marked `passed_by_blackbox_lifecycle`; Agent P0 remains partial until delete lifecycle is verified.

## Required Next Gates

1. Agent P0 delete-path blackbox:
   `delete assistant -> confirm -> catalog removed -> conversation cleaned or marked orphan -> restart still removed`.
2. Core capability blackbox lifecycle matrix:
   document library, knowledge base, validation, document generation, skill generation, settings, export.
3. Event ledger repair:
   ensure recent activity and usage records come from real user operations and failure events.
4. Artifact lifecycle repair:
   generate, open, export, delete, re-enter checks for every artifact type.

## Files

JSON matrix:

```text
web/workbench/flutter_app/output/capability_reality/global_capability_reality_inventory.json
```

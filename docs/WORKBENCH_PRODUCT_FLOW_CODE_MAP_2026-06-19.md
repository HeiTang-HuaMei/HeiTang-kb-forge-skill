# Workbench Product Flow Code Map - 2026-06-19

This map freezes the current behavior before further structural cleanup. It is not a new feature plan. Use it to keep each later extraction tied to a page, runtime method, artifact, and test.

## Current Structure Debt

| Area | Current Location | Finding | Cleanup Rule |
| --- | --- | --- | --- |
| Main UI | `web/workbench/flutter_app/lib/main.dart` | About 2,900 lines after the top bar, status bar, sidebar, app shell, shared layout, and shared product component extractions. Routing, page-surface dispatch, state labels, and a few general helpers still live together. | Split one UI page, shell widget, or shared widget group at a time into `lib/features/<page>/...`, `lib/app/...`, or `lib/shared/...` without changing visible behavior. |
| Runtime | `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart` | 7,216 lines. It contains import, parsing, KB, retrieval, document, storage, Skill, Agent, and artifact cleanup logic. The `rc6` name is now historical debt. | Do not rename yet. After UI slices are stable, introduce product-named wrappers or files while keeping compatibility. |
| Runtime Stub/Models | `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_stub.dart` | State model and web stub still carry `Rc6RuntimeState` and many PRD-era fields. | Keep stable until runtime naming cleanup is isolated. |
| Widget Tests | `web/workbench/flutter_app/test/campaign_4_workbench_test.dart` | 754 lines. Modern product-flow widget tests still live under a Campaign 4 name. | Later move tests into `test/product_flow/` one group at a time. |
| Runtime Tests | `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart` | 2,372 lines. Most real runtime and artifact tests live under an rc6 repair name. | Later split into runtime/product-flow regression files after UI extraction is complete. |

## Page To Runtime Map

| User Page | Current Component | Runtime Entry Points | Primary Artifacts | Main Tests |
| --- | --- | --- | --- | --- |
| Dashboard / Workbench Home | `_ProductPageOverview`, `_DesktopDashboardSurface`, dashboard panels in `lib/features/dashboard/dashboard_product_workflow.dart` | Reads `Rc6RuntimeState`; routes through `onPageChanged` | Current source, KB, retrieval, document, Skill, Agent, and task state | `campaign_4_workbench_test.dart`: dashboard state, next actions, product navigation |
| Import And Parsing | `_ImportProductWorkflow` in `lib/features/import_parsing/import_product_workflow.dart` | `importFilePath`, `importFolderPath`, `importWebLink`, `parseAndChunkSources`, `clearImportedSources`, `deleteImportedSource` | `source_manifest.json`, `parse_report.json`, `du/document_understanding_manifest.json`, imported input files | `rc6_runtime_truth_blocker_repair_test.dart`: import append/delete/web link; full-chain precondition tests |
| Document Library | `_DocumentLibraryView`, `_DocumentLibraryProductWorkflow` in `lib/features/document_library/document_library_product_workflow.dart` | Reads source records from runtime; calls source deletion and downstream KB build handoff | `source_manifest.json`, copied input files, source records | `campaign_4_workbench_test.dart`: document library to KB handoff; `rc6_runtime_truth_blocker_repair_test.dart`: document library product state |
| Knowledge Base | `_KnowledgeProductWorkflow`, `_KnowledgePackageListView` in `lib/features/knowledge_base/knowledge_base_product_workflow.dart` | `buildKnowledgeBase`, `copyKnowledgeBase`, `mergeKnowledgeBases`, `splitKnowledgeBase`, `updateKnowledgeBaseIncremental`, `rebuildKnowledgeBaseFull`, `compareKnowledgeBaseVersions`, `rollbackKnowledgeBaseVersion`, `deleteKnowledgeBaseRecord` | `kb/chunks.jsonl`, `kb/cards.jsonl`, `kb/qa_pairs.jsonl`, `kb/manifest.json`, `kb/quality_report.json`, `knowledge_bases/kb_catalog.json` | `campaign_4_workbench_test.dart`: KB page surfaces; `rc6_runtime_truth_blocker_repair_test.dart`: multi-KB catalog operations |
| Retrieval And Verification | `_RetrievalVerificationView`, `_RetrievalVerificationProductWorkflow` in `lib/features/retrieval/retrieval_verification_product_workflow.dart` | `search`, `searchKnowledgeBases`, `saveRetrievalValidationReport` | `query/multi_kb_query_result.json`, per-KB `kb_query_result.json`, `query/validation_report.json` | `rc6_runtime_truth_blocker_repair_test.dart`: stale query clearing, multi-KB retrieval attribution |
| Document Generation | `_DocumentGenerationView`, `_DocumentExportPreviewView`, `_DocumentProductWorkflow` in `lib/features/document_generation/document_generation_product_workflow.dart` | `generateMarkdown`, `exportMarkdownDocument`, `exportDocumentFormat`, `saveEditedDocument`, `clearDocumentGenerationHistory` | `doc/generated.md`, `doc/reading_notes.md`, `doc/generation_manifest.json`, `doc/edited_document.md`, `export/reading_notes_export.md`, `export/export_manifest.json` | `rc6_runtime_truth_blocker_repair_test.dart`: document flow, generation config, export |
| Skill Factory | `_SkillBuilderProductWorkflow` in `lib/features/skill/skill_builder_product_workflow.dart` | `generateSkill`, `importExternalSkillPath`, `completeSkillProductOperations`, `runSkillOperation`, `saveEditedSkill` | `skill/knowledge_qa_skill/SKILL.md`, skill manifests, localization diff, operation manifest, export package | `campaign_4_workbench_test.dart`: Skill page ownership; `rc6_runtime_truth_blocker_repair_test.dart`: Skill generation/import/operations |
| Agent Workbench | `_AgentProductWorkflow`, `_AgentMinimalChatView`, `_AgentDiscussionProductView` in `lib/features/agent/agent_product_workflow.dart` | `generateAgent`, `runAgentDialogue`, `exportAgentDialogue`, `clearAgentDialogueHistory`, `runMultiAgentDiscussion` | `agent/knowledge_qa_agent/agent_manifest.json`, `agent/dialogue/agent_dialogue.md`, `agent/dialogue/chat_history.jsonl`, `agent/dialogue_export/agent_dialogue_export.md`, `agent/multi_agent_discussion.md` | `campaign_4_workbench_test.dart`: Agent page ownership; `rc6_runtime_truth_blocker_repair_test.dart`: Agent generation, dialogue, A2A dependencies |
| Artifact Center | `_ArtifactCenterProductWorkflow` in `lib/features/artifacts/artifact_center_product_workflow.dart` | Reads runtime artifact paths; calls `clearRecentTaskArtifacts`; previews bounded workspace artifacts | Cross-flow generated artifacts from import, KB, retrieval, document, Skill, Agent, governance | `rc6_runtime_truth_blocker_repair_test.dart`: artifact list, preview, scoped deletion |
| Audit Center | `_ValidateExportProductWorkflow`, `_ValidationChecklistView` | `exportAuditReport`; reads last runtime result and artifact status | `audit/audit_report.json`, product-flow evidence path | `campaign_4_workbench_test.dart`: audit center records and export |
| Settings | `_SettingsProductWorkflow`, `_SettingsProvidersStorageView` | `loadStorageProviderSettings`, `saveStorageProviderSettings`, `testRedisConnection`, `testQdrantConnection` | storage provider settings JSON, Redis/Qdrant test result state | `campaign_4_workbench_test.dart`: provider labels and masked secrets; `rc6_runtime_truth_blocker_repair_test.dart`: settings persistence |
| Workbook | `_WorkbookProductWorkflow` | Workbook runtime methods in the current controller/state | workbook manifest and asset index | `rc6_runtime_truth_blocker_repair_test.dart`: workbook creation/switching and asset refresh |

## Runtime Artifact Ownership

| Artifact | Owner Page | Runtime Field | Notes |
| --- | --- | --- | --- |
| `source_manifest.json` | Import And Parsing, Document Library | `sourceManifestPath` | Source of truth for imported file records. |
| `parse_report.json` | Import And Parsing, Document Library | `parseReportPath` | Alias over document-understanding output. |
| `kb/chunks.jsonl` | Knowledge Base, Retrieval | `chunksPath` | Local index input for retrieval and downstream generation. |
| `kb/cards.jsonl` | Knowledge Base | `cardsPath` | Derived KB artifact. |
| `kb/qa_pairs.jsonl` | Knowledge Base | `qaPairsPath` | Derived QA artifact. |
| `kb/quality_report.json` | Knowledge Base | `qualityReportPath` | Quality and build evidence. |
| `kb/manifest.json` | Knowledge Base | `kbManifestPath` | KB package manifest. |
| `query/multi_kb_query_result.json` | Retrieval And Verification | `queryResultPath` | Multi-KB selected result record. |
| `doc/generated.md`, `doc/reading_notes.md` | Document Generation | `generatedMarkdownPath`, `readingNotesPath` | Draft and reading-note outputs. |
| `export/reading_notes_export.md` | Document Generation | `exportedDocumentPath` | Markdown export output. |
| `export/export_manifest.json` | Document Generation | `exportManifestPath` | Export traceability record. |
| `skill/.../SKILL.md` | Skill Factory | `primarySkillPath` | Primary generated Skill artifact. |
| `agent/.../agent_manifest.json` | Agent Workbench | `primaryAgentManifestPath` | Primary generated Agent manifest. |
| `agent/dialogue/agent_dialogue.md` | Agent Workbench | `agentDialoguePath` | Minimal chat transcript. |
| `agent/multi_agent_discussion.md` | Agent Workbench | `multiAgentDiscussionPath` | A2A discussion minutes. |

## Recommended Cleanup Order

1. Continue UI extraction only. Next low-risk candidates: shared shell widgets, then test file naming cleanup.
2. Keep runtime method names and `Rc6RuntimeState` stable until UI extractions have landed and passed tests.
3. Move tests only after the relevant page module has been extracted and CI has stayed green.
4. For every extraction slice, validate with:
   - `flutter analyze`
   - focused widget/runtime tests for that page
   - `git diff --check`
   - diff-only no-secret and overclaim scans
5. Do not delete old gate/matrix/job-center logic during these slices. If it is not on the ordinary user path, leave it for a later diagnostics/legacy cleanup.

## OKF Architecture Boundary

OKF is now tracked as a future architecture layer in `docs/OKF_PRODUCT_ARCHITECTURE_PLAN_2026-06-19.md`.

Current rc10 structure-cleanup slices must not implement OKF runtime behavior, add OKF navigation, or alter the user-facing path. OKF belongs between Document Library and Knowledge Base as an internal standardization package layer for a later rc11+ plan.

## Latest Structural Slice

`d2f5f8b Extract Workbook workflow` moved Workbook UI into `web/workbench/flutter_app/lib/features/workbook/workbook_product_workflow.dart` with no product behavior change. Local focused tests and remote CI passed.

The current retrieval slice moves Retrieval And Verification UI into `web/workbench/flutter_app/lib/features/retrieval/retrieval_verification_product_workflow.dart` with no product behavior change. Local focused tests passed before commit.

The current document library slice moves Document Library UI into `web/workbench/flutter_app/lib/features/document_library/document_library_product_workflow.dart` with no product behavior change. Shared document helper functions stay in `main.dart` because Import and Knowledge Base still use them.

The current document generation slice moves Document Generation UI into `web/workbench/flutter_app/lib/features/document_generation/document_generation_product_workflow.dart` with no product behavior change. Document generation helper functions move with the page because they are page-local.

The current knowledge base slice moves Knowledge Base UI into `web/workbench/flutter_app/lib/features/knowledge_base/knowledge_base_product_workflow.dart` with no product behavior change. Shared document type helper functions stay in `main.dart` because Import and Document Library still use them.

The current Skill Factory slice moves Skill Factory UI into `web/workbench/flutter_app/lib/features/skill/skill_builder_product_workflow.dart` with no product behavior change.

The current Agent Workbench slice moves Agent Workbench UI into `web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart` with no product behavior change.

The current Dashboard slice moves Dashboard panels into `web/workbench/flutter_app/lib/features/dashboard/dashboard_product_workflow.dart` with no product behavior change.

The current Import And Parsing slice moves import workflow UI into `web/workbench/flutter_app/lib/features/import_parsing/import_product_workflow.dart` with no product behavior change. Shared document preview/type helper widgets stay in `main.dart` because Document Library and Skill still use them.

The Product Top Bar shell slice moves the desktop top bar shell into `web/workbench/flutter_app/lib/app/product_top_bar.dart` with no search, navigation, or theme behavior change.

The Product Top Bar helper slice moves top bar search, language toggle, chips, and icon button helpers into `web/workbench/flutter_app/lib/app/product_top_bar.dart` with no behavior change.

The Desktop Status Bar slice moves the desktop status bar shell into `web/workbench/flutter_app/lib/app/desktop_status_bar.dart` with no behavior change.

The Workbench Sidebar slice moves the desktop sidebar shell into `web/workbench/flutter_app/lib/app/workbench_sidebar.dart` with no navigation or route behavior change.

The Shared Workbench Layout slice moves reusable layout and scroll helper widgets into `web/workbench/flutter_app/lib/shared/workbench_layout.dart` with no behavior change.

The Workbench Shell slice moves the scaffold and desktop preview frame into `web/workbench/flutter_app/lib/app/workbench_shell.dart` with no behavior change.

The Shared Product Components slice moves reusable product headers, page tabs, panels, tables, field rows, section captions, and capability status markers into `web/workbench/flutter_app/lib/shared/product_components.dart` with no behavior change. `main.dart` is now about 2,865 lines.

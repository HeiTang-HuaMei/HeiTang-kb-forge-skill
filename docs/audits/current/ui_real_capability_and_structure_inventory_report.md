# UI Real Capability And Structure Inventory Report

Gate: `ui_real_capability_and_structure_inventory_gate`

Generated: 2026-06-21

Scope: read-only inventory before UI information architecture restructuring.

This report does not modify UI, runtime, code, tests, file layout, tags, or releases. The only output is this report.

## 0. Current State

UI repo:

- Path: `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui`
- Branch: `feature/workbench-ui-prototype`
- Latest head: `b26a024 Add GitHub repository governance controls`
- Latest observed CI: `27902974991`, success.
- Stable tag: not created in this gate.
- GitHub Release: not created in this gate.

Pre-existing local dirty items preserved:

- `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md`
- `web/workbench/flutter_app/lib/features/document_library/document_library_product_workflow.dart`
- `web/workbench/flutter_app/output/`

Core repo dirty items also remain untouched.

Inputs read:

- `docs/current/CURRENT_PRODUCT_BASELINE.md`
- `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- `docs/product/PRD_V3_2026-06-19.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`
- `docs/audits/current/rc11_project_inventory_before_code_cleanup_report.md`
- `docs/audits/current/rc11_product_code_systematic_cleanup_execution_report.md`
- `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`
- `docs/audits/current/rc12_github_repository_governance_restructure_report.md`
- `docs/WORKBENCH_PRODUCT_FLOW_CODE_MAP_2026-06-19.md`
- Flutter feature and runtime source files under `web/workbench/flutter_app/lib/`
- Flutter and Python test inventory.

## 1. Executive Answer

The current Workbench is functionally richer than its UI clarity. The runtime can execute a real local chain across import, parse/chunk, KB build, retrieval, Markdown generation, Skill generation, Agent creation, Agent dialogue, A2A discussion, artifacts, audit, and Stage3 Provider readiness/config evidence.

However, UI information architecture should not be restructured until these facts are accepted:

1. Main user pages are mostly extracted as feature part files, but they are still `part of main.dart`.
2. `Rc6RuntimeController` is still a large compatibility runtime facade/god-object.
3. Some pages still combine main actions, secondary actions, report viewing, audit, cleanup, and developer-era validation concepts.
4. Settings has too many primary-looking actions for Profile, Provider, exporter, Redis, Qdrant, network, and security.
5. Skill and Agent pages contain real runtime actions but also dense report/status surfaces that should be secondary.
6. Artifact Center and Audit Center are mostly view/export/report surfaces and should not compete with creation pages.
7. Operation Gate, Capability Matrix, and Task/Job Center are hidden legacy contract routes and should remain hidden from ordinary product navigation.

Recommendation: enter `ui_information_architecture_restructure_plan_gate` only after this report is reviewed. It is safe to plan UI IA restructuring next; no additional code evidence is required for planning. Execution should remain behavior-preserving and must not delete runtime actions before a Button Audit Matrix confirms replacement or demotion.

## 2. Real Capability Inventory

Status vocabulary:

- `real_callable`: UI or runtime method performs real local state change and writes real workspace artifacts.
- `config_required`: runtime exists but needs Profile/Provider/external service configuration.
- `local_artifact_only`: writes local evidence/artifacts but does not run external service/runtime.
- `report_only`: shows or exports reports; not a core creation action.
- `audit_only`: governance/audit visibility or log generation.
- `template_only`: template/method asset, not Provider runtime.
- `disabled_until_configured`: intentionally unavailable until config/evidence exists.
- `dev_only`: should not be ordinary user primary UI.
- `hidden_from_user_recommended`: useful for tests/governance but not primary ordinary workflow.

### 2.1 Capability Matrix

| Capability | UI entry / button | Runtime method | Real artifacts | Tests | Config dependency | Fallback / rollback / audit | Current status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Workbook create/switch/delete | Workbook page: create/switch/delete | `createOrSwitchWorkbook`, `deleteWorkbook` | `workbooks/workbook_manifest.json`, workbook asset index | `rc6_runtime_truth_blocker_repair_test.dart`: workbook persistence/deletion/asset refresh | local workspace | deletion guard through runtime state; artifact index refresh | `real_callable` |
| File/folder import | Document Library / Import tab: choose source | `pickAndImportFile`, `pickAndImportFolder`, `importFilePath`, `importFolderPath` | copied input files, `source_manifest.json` | rc6 import append/delete/full-chain tests | Windows EXE/local file access | source delete/clear methods | `real_callable` in desktop; web file picker boundary depends on platform |
| Web link import | Import page web link dialog | `importWebLink` | source record and local placeholder content with boundary text | rc6 web link import test | network authorization for real crawl; current path stores boundary/local record | network disabled boundary preserved | `local_artifact_only` / `disabled_until_configured` |
| Parse / OCR / Chunking | Import page: `解析 / OCR / Chunking`; Document Library parse action | `parseAndChunkSources` | `du/document_understanding_manifest.json`, `parse_report.json`, `kb/chunks.jsonl` seed artifacts | rc6 real input folder, parser/OCR adapter tests | local parser default; OCR/provider optional | runtime config `du_runtime_config.json`, fallback to builtin/local | `real_callable` with provider options `config_required` |
| Standard knowledge package / OKF candidate export | Document Library: standard package export | `exportStandardKnowledgePackage`, `importStandardKnowledgePackagePath` | `standard_packages/.../standard_package_manifest.json`, `content_package.jsonl`, `audit_history.jsonl`, OKF runtime manifest | rc6 standard package export/import/build KB test | none for local package | audit record; OKF remains package/candidate layer, not first-level page | `real_callable` / `local_artifact_only` |
| KB build/update | Knowledge Base: `构建/更新知识库` | `buildKnowledgeBase`, `buildKnowledgeBaseFromStandardPackage` | `kb/manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `quality_report.json`, catalog | rc6 multi-KB and P0 product smoke tests | source docs or standard package | build logs, local index artifacts | `real_callable` |
| KB copy/merge/split/update/rebuild/compare/rollback/delete | Knowledge Base more menus | `copyKnowledgeBase`, `mergeKnowledgeBases`, `splitKnowledgeBase`, `updateKnowledgeBaseIncremental`, `rebuildKnowledgeBaseFull`, `compareKnowledgeBaseVersions`, `rollbackKnowledgeBaseVersion`, `deleteKnowledgeBaseRecord` | `knowledge_bases/kb_catalog.json`, version snapshots, compare/rollback reports | rc6 multi-KB catalog test | existing KB catalog | rollback/version records | `real_callable`, but UI should keep as secondary |
| Index layer | Knowledge Base status/artifacts | `_writeIndustrialIndexArtifacts` through KB build | `index_profile.json`, `keyword_index.json`, `vector_index_reference.json`, `metadata_index.json`, `citation_index.json`, `index_build_report.json` | rc6 embedding/vector adapter readiness tests | external vector DB optional | Vector DB failure falls back local index | `real_callable` local; external vector `config_required` |
| Retrieval / RAG validation | Retrieval page query and save report | `search`, `searchKnowledgeBases`, `saveRetrievalValidationReport` | `query/multi_kb_query_result.json`, `retrieval_plan.json`, rerank/citation/conflict reports, validation report md/json/history | rc6 retrieval attribution/stale clear tests | local KB; external search optional | external validation boundary artifact | `real_callable`; external fact check `disabled_until_configured` |
| Markdown generation | Document Generation: `生成 Markdown` | `generateMarkdown` | `doc/generated.md`, `reading_notes.md`, `generation_manifest.json`, outline/citations/validation | rc6 document flow and generation config tests | KB required; LLM/provider optional depending mode | local template generation available | `real_callable` |
| Markdown export | Document Generation more menu | `exportMarkdownDocument` | `export/reading_notes_export.md`, `export_manifest.json` | rc6 document flow tests | markdown generated | manifest/audit path | `real_callable` secondary |
| DOCX/PDF/PPTX export | Document Generation format export / Settings exporter config | `exportDocumentFormat`, `saveExporterSettings`, `validateExporterSettings` | `export/generated_file_report.json` or structured manifests; exporter validation report | rc6 exporter config tests | exporter config required | Markdown remains fallback | `disabled_until_configured` / `config_required` |
| JSON/CSV structured export | Document Generation format export | `exportDocumentFormat`, `_exportStructuredDocumentFormat` | JSON/CSV export files and `structured_export_manifest.json` | rc6 exporter config test | generated doc/KB | local structured export | `real_callable` after source artifacts |
| Document edit/save/history/delete | Document Generation editor and more menu | `readLatestDocumentGenerationHistoryMarkdown`, `saveEditedDocument`, `deleteLatestDocumentGenerationHistory`, `clearDocumentGenerationHistory` | `edited_document.md`, `edit_manifest.json`, generation history | rc6 document generation tests | generated markdown required | history mutation | `real_callable` secondary |
| Skill generation from KB | Skill Factory: `生成 Skill` | `generateSkill`, `completeSkillProductOperations` | `skill/.../SKILL.md`, config, verification report, package manifest, validation report | rc6 skill generation config and P0 smoke tests | KB required; model/provider optional | validation/audit/version records | `real_callable` |
| External Skill localization | Skill Factory: import/localize Skill | `pickAndImportExternalSkill`, `importExternalSkillPath` | localized Skill manifest, diff, localized SKILL.md | rc6 external Skill localization test | local file source | localization manifest/diff | `real_callable` desktop; secondary |
| Skill operations: validate/export/copy/fuse/bind/view/delete | Skill Factory more actions | `runSkillOperation`, `saveEditedSkill`, `clearSkillArtifacts` | operation manifest/history, versions, diff, rollback/audit, export package, binding manifest | rc6 fusion/version/diff/rollback/audit tests | existing Skill and sometimes Agent/KB | operation history and audit | `real_callable`; should be secondary/more |
| Agent creation | Agent Workbench: create Agent | `generateAgent`, `completeAgentProductOperations` | `agent/.../agent_manifest.json`, profile YAML, generation manifest, advanced config, permission audit | rc6 agent generation config tests | KB/Skill recommended; provider/model optional | permission audit, validation report | `real_callable` |
| Single Agent dialogue | Agent Workbench chat | `runAgentDialogue`, `clearAgentDialogueHistory` | `agent/dialogue/agent_dialogue.md`, manifest, `chat_history.jsonl`, citation/skill traces, run history | rc6 Agent dialogue/run history tests | Agent and dependencies | Redis failure degrades to local file history | `real_callable` |
| Agent dialogue export | Agent Workbench export | `exportAgentDialogue` | `agent/dialogue_export/agent_dialogue_export.md`, export manifest | artifact center exported dialogue test | dialogue history | run history appended | `real_callable` secondary |
| A2A multi-agent discussion | Agent Workbench discussion | `runMultiAgentDiscussion` | `agent/multi_agent_discussion.md`, A2A session manifest, rounds, runtime audit, conflict/consensus/report | rc6 A2A 3-round/conflict/consensus tests | Agent/Skill/KB; provider optional | local A2A session audit; external n8n remains health/load boundary | `real_callable` under Agent, not first-level page |
| Artifact browse/preview/export/delete | Artifact Center | `readWorkspaceTextArtifact`, `exportWorkspaceArtifact`, `clearRecentTaskArtifacts` | bounded exported artifact copies, preview records | rc6 artifact preview/export/delete tests | artifact paths present | scoped deletion only | `real_callable` for artifact operations; mostly `report_only` UI |
| Audit export | Governance & Audit | `exportAuditReport`, `runParallelTaskCapacityValidation` | `audit/audit_report.json`, parallel capacity report, task isolation/recovery reports | campaign_4 audit tests and Stage2/3 tests | existing runtime state | audit-only evidence | `audit_only` / `report_only` |
| ProjectConfigProfile lifecycle | Settings Profile panel | `createProjectConfigProfile`, `copyProjectConfigProfile`, `updateProjectConfigProfile`, `activateProjectConfigProfile`, `rollbackProjectConfigProfile`, `deleteProjectConfigProfile`, `testProjectConfigProfile` | `config/project_config_profiles.json`, config assets, runtime status, config/profile logs | rc6 profile lifecycle/activation tests | workspace config | active/last profile protection, rollback, logs | `real_callable` but belongs in Settings |
| Provider readiness / capability catalog | Settings Provider panel | `syncRegisteredProviderCapabilities`, `testAllRegisteredProviderCapabilities`, `activateRegisteredProviderCapability`, `rollbackRegisteredProviderCapability`, `loadProviderCapabilityUserCatalog` | provider readiness report, integration matrix, user catalog, lifecycle audit summary | rc6 Stage3 provider adapter tests | stage3 evidence and config | fallback/rollback/audit | `config_required`; do not show as ordinary primary flow |
| N8N / RTK runtime health-load | Settings/Provider status, runtime methods | `loadN8nProviderRuntime`, `rollbackN8nProviderRuntime`, `loadRtkProviderRuntime`, rollback methods | provider runtime load manifest/log, lifecycle audit | rc6 n8n/rtk tests | endpoint/profile required | health-check only; rollback; no workflow execution claim | `config_required` / `dev_only` unless surfaced as capability status |
| Redis connection | Settings storage | `testRedisConnection` | Redis storage test result, config test log | rc6 degradation tests; stage2 live Redis test skipped unless env | Redis host/password ref/env | failure disables memory, local file fallback | `config_required` |
| Qdrant/vector connection | Settings storage | `testQdrantConnection` | Qdrant test result, config test log | rc6 vector failure tests; stage2 live Qdrant test skipped unless env | Qdrant endpoint/API key/dimension | local index fallback; dimension mismatch status | `config_required` |
| Model Gateway / ModelRoute | Settings provider/model config | `saveModelGatewayProviderConfig`, `testModelGatewayProvider` | model gateway config, route pool, binding matrix, audit/evidence | rc6 model gateway tests | endpoint/model/API key ref | masked secrets; downstream sync | `config_required` |
| Parallel task capacity | Audit/Settings governance | `runParallelTaskCapacityValidation` | parallel capacity report, task isolation/recovery reports | rc6 parallel task validation tests | none/local workspace | report only | `audit_only`; hide from ordinary primary UI |
| Stage2/3 industrial smoke and reports | Runtime methods/tests, not primary UI | `runPrdP0ProductE2E`, `runStage3ProfilePersistenceSmoke`, EXE/report writers | acceptance reports under output workspace | stage2 evidence refresh tests | test workspace/EXE | evidence only | `dev_only` / `audit_only` |

## 3. Project Structure Inventory

### 3.1 Workspace

Top-level workspace entries:

- `kb-forge-skill-ui/`: current UI/product Workbench repo.
- `kb-forge-skill/`: Core/Python repo.
- `archive/`: workspace archive.
- root Markdown/project control files.

### 3.2 UI Repo Structure

Tracked/source distribution observed:

| Path | Role | Observed scale |
| --- | --- | ---: |
| `heitang_kb_forge/` | Python package / CLI / schema / governance code | 761 files, about 15.5k counted lines |
| `tests/` | Python contract, package, docs, UI fixture tests | 546 files, about 9.6k counted lines |
| `docs/` | product, governance, audit, legacy docs | 308 files, about 12.4k counted lines |
| `web/` | web + Flutter Workbench | 1380 files, about 236k counted lines including generated/assets |
| `examples/` | fixtures and examples | 134 files |
| `scripts/` | smoke scripts | 3 files |
| `.github/` | workflows, templates, governance controls | 16 files after rc12 |

Key docs/governance surfaces:

- `docs/current/CURRENT_PRODUCT_BASELINE.md`
- `docs/current/CURRENT_PRODUCT_BASELINE_2026-06-19.md`
- `docs/product/PRODUCT_ARCHITECTURE*.md`, `PRD*.md`, `FEATURE_ACCEPTANCE_MATRIX*.md`
- `docs/governance/*.md`
- `docs/audits/current/`
- `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`

### 3.3 Core Repo Structure

Core repo observed scale:

| Path | Role | Observed scale |
| --- | --- | ---: |
| `heitang_kb_forge/` | Core package: schemas, parsers, providers, retrieval, workspace, agent modules | 1181 files, about 73k counted lines |
| `tests/` | Core package tests | 1851 files, about 32k counted lines |
| `docs/` | Core docs/history/governance | 1063 files, about 52k counted lines |
| `examples/` | examples | 105 files |
| `scripts/` | scripts | 4 files |

Core repo also has local generated/temp dirs such as `output/`, `tmp_*`, `dist/`, `.venv/`; these are not part of this UI inventory gate and were not changed.

### 3.4 rc11 Structural Changes

rc11 added:

- `web/workbench/flutter_app/lib/domain/config_profile/project_config_profile.dart`
- compatibility export at `lib/rc6_runtime/project_config_profile.dart`
- `web/workbench/flutter_app/lib/app/workbench_pages.dart`
- `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`

rc11 did not split `rc6_runtime_controller_io.dart`.

### 3.5 High Coupling / High Risk

High-risk files:

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`: 25056 lines, public facade plus orchestration, IO, schema creation, provider readiness, test evidence writers.
- `web/workbench/flutter_app/lib/main.dart`: 2016 lines, app bootstrap, runtime scope, page dispatch, shared fixture constants, artifact preview.
- `web/workbench/flutter_app/lib/features/settings/settings_product_workflow.dart`: 1935 lines, Profile, Provider, exporter, Redis/Qdrant, network/security all in one feature file.
- `web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart`: 1635 lines, Agent creation, dialogue, A2A, history, package/status all together.
- `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart`: very broad runtime regression suite; high signal but difficult to split casually.

Low-risk next split candidates:

- Further extract UI-only widgets from `settings_product_workflow.dart` into settings subpanels.
- Extract Agent creation/chat/A2A panels into separate part files while preserving `part of main.dart`.
- Extract `artifact_center` and `audit_center` panels if UI IA planning needs isolated page surfaces.
- Extract runtime services only after UI IA and tests remain stable; first candidate remains config/profile service.

## 4. UI Split Status

### 4.1 Page Registry

User-facing page registry is now in `lib/app/workbench_pages.dart`.

Current ordinary navigation:

1. Dashboard / 首页
2. Workbook / 工作本管理
3. Document Library / 文档库
4. Knowledge Base / 知识库
5. Retrieval & Verification / 检索与验证
6. Document Generation / 文档生成
7. Skill Factory / Skill 工厂
8. Agent Workbench / Agent 工作台
9. Artifact Center / 产物中心
10. Governance & Audit / 治理与审计
11. Settings / 设置

Hidden legacy contract routes:

- `operation-gate`
- `capability-matrix`
- `task-job-center`

These hidden routes should remain out of ordinary product navigation.

### 4.2 Feature Files

| Page | File | Lines | Status |
| --- | --- | ---: | --- |
| Agent Workbench | `features/agent/agent_product_workflow.dart` | 1635 | extracted as part file; still coupled |
| Artifact Center | `features/artifacts/artifact_center_product_workflow.dart` | 347 | extracted as part file |
| Governance & Audit | `features/audit/audit_center_product_workflow.dart` | 643 | extracted as part file |
| Dashboard | `features/dashboard/dashboard_product_workflow.dart` | 1061 | extracted as part file |
| Document Generation | `features/document_generation/document_generation_product_workflow.dart` | 1255 | extracted as part file |
| Document Library | `features/document_library/document_library_product_workflow.dart` | 515 | extracted as part file; currently dirty locally before this gate |
| Import/Parsing | `features/import_parsing/import_product_workflow.dart` | 522 | extracted as part file |
| Knowledge Base | `features/knowledge_base/knowledge_base_product_workflow.dart` | 931 | extracted as part file |
| Retrieval | `features/retrieval/retrieval_verification_product_workflow.dart` | 610 | extracted as part file |
| Settings | `features/settings/settings_product_workflow.dart` | 1935 | extracted as part file; too dense |
| Skill Factory | `features/skill/skill_builder_product_workflow.dart` | 1018 | extracted as part file |
| Workbook | `features/workbook/workbook_product_workflow.dart` | 368 | extracted as part file |

All feature files still start with `part of '../../main.dart';`. They are not independent imports/libraries yet.

### 4.3 Widgets / Panels / Cards / Dialogs

Extracted shared/app components:

- `app/product_top_bar.dart`
- `app/desktop_status_bar.dart`
- `app/workbench_sidebar.dart`
- `app/workbench_shell.dart`
- `app/workbench_pages.dart`
- `shared/workbench_layout.dart`
- `shared/product_components.dart`

Still in `main.dart`:

- `_Rc6RuntimeScope`
- `_PageSurface`
- `_ProductPageOverview`
- `_showWorkspaceArtifactPreview`
- destructive confirmation dialog helper
- some shared sample/runtime fixture constants.

### 4.4 Runtime Services

No UI-side runtime services have been split yet. Runtime remains:

- `rc6_runtime/rc6_runtime_controller.dart`: conditional facade.
- `rc6_runtime/rc6_runtime_controller_io.dart`: dominant IO implementation.
- `rc6_runtime/rc6_runtime_controller_stub.dart`: web/stub state surface.
- `domain/config_profile/project_config_profile.dart`: first real domain extraction.

### 4.5 UI With Real Operations vs Report Display

Real operation pages:

- Document Library / Import
- Knowledge Base
- Retrieval & Verification
- Document Generation
- Skill Factory
- Agent Workbench
- Settings for configuration lifecycle

Mostly view/report/audit pages:

- Dashboard: navigation/status/summary; only limited artifact deletion/navigation.
- Artifact Center: preview/export/delete generated artifacts.
- Governance & Audit: export audit report, run parallel capacity validation, view evidence.

UI buttons likely requiring demotion or grouping:

- Settings Profile actions: six primary-looking buttons should become one primary plus menus/row actions.
- Settings Provider actions: sync/test/activate/rollback should be status-driven and mostly row actions.
- Skill Factory more operations already grouped, but the page still displays many status/report fields.
- Agent Workbench creation/chat/A2A should remain one page, but create/chat/A2A should be visually separated into modes/tabs.
- Knowledge Base version operations are correctly in more menu, but should be row-level for selected KB rather than always first KB.
- Audit parallel task validation is developer/industrial validation; not ordinary primary user path.

## 5. Functional Chain Understanding

### 5.1 Materials Import

- Current implementation: yes.
- Entry: Document Library page via Import tab / `ImportProductWorkflow`.
- Runtime: `pickAndImportFile`, `pickAndImportFolder`, `importFilePath`, `importFolderPath`, `importWebLink`.
- Artifacts: `source_manifest.json`, copied input files, web placeholder/boundary records.
- Missing config: real web crawl needs network authorization/provider; local file import needs desktop/runtime access.
- Ordinary user exposure: yes, primary.
- UI clarity: acceptable, but import and parse are split between Document Library and Import/Parsing member route; IA should make this feel like one Document Library flow.

### 5.2 Document Library

- Current implementation: yes.
- Entry: Document Library.
- Runtime: read source records; `deleteImportedSource`, `parseAndChunkSources`, `exportStandardKnowledgePackage`.
- Artifacts: source manifest, parse report alias, standard package.
- Missing config: OCR/parser providers optional.
- Ordinary user exposure: yes, primary.
- UI clarity: should emphasize import/manage documents and demote standard package export to secondary.

### 5.3 Knowledge Base

- Current implementation: yes.
- Entry: Knowledge Base.
- Runtime: `buildKnowledgeBase`, package build, KB CRUD/version methods.
- Artifacts: KB manifest, chunks/cards/QA/glossary/quality, catalog, index artifacts.
- Missing config: external vector DB optional; local index works.
- Ordinary user exposure: yes, primary.
- UI clarity: mostly aligned; row-level KB actions should be clearer.

### 5.4 Index Layer

- Current implementation: local index yes; external vector readiness/config exists.
- Entry: Knowledge Base status; Settings for vector/Qdrant.
- Runtime: KB build writes local index; `testQdrantConnection` validates external vector.
- Artifacts: index metadata/profile/keyword/vector refs/build report.
- Missing config: Qdrant/other vector DB requires endpoint/API key/dimension.
- Ordinary user exposure: yes as status/config, not as standalone primary page.
- UI clarity: should appear as KB index backend status and Settings Provider config, not a separate user task.

### 5.5 RAG / Retrieval Verification

- Current implementation: yes for local retrieval and validation evidence.
- Entry: Retrieval & Verification.
- Runtime: `searchKnowledgeBases`, `saveRetrievalValidationReport`.
- Artifacts: query results, retrieval plan, rerank, citation, conflict, validation reports.
- Missing config: external fact verification/search provider disabled until authorized.
- Ordinary user exposure: yes, primary after KB.
- UI clarity: good as a page; external validation status should remain status/config link.

### 5.6 OKF / Standard Knowledge Package

- Current implementation: standard package export/import/build KB runtime exists.
- Entry: Document Library export and Knowledge Base build-from-package.
- Runtime: `exportStandardKnowledgePackage`, `importStandardKnowledgePackagePath`, `buildKnowledgeBaseFromStandardPackage`, OKF manifest writer.
- Artifacts: standard package manifest/content/audit; OKF runtime manifest as package evidence.
- Missing config: none for local package.
- Ordinary user exposure: do not expose as first-level page. Show as advanced package/export/import capability.
- UI clarity: should be framed as standard package under Document Library/KB, not OKF product module.

### 5.7 Document Generation

- Current implementation: Markdown yes; structured export yes; Office formats config-gated.
- Entry: Document Generation.
- Runtime: `generateMarkdown`, `exportMarkdownDocument`, `exportDocumentFormat`, edit/history methods.
- Artifacts: Markdown, reading notes, generation/edit/export manifests, JSON/CSV exports.
- Missing config: LLM provider for advanced generation; exporter provider for DOCX/PDF/PPTX.
- Ordinary user exposure: yes, primary.
- UI clarity: aligned: primary button is Markdown; nonconfigured formats are disabled/config-gated.

### 5.8 Skill Generation / External Skill Localization

- Current implementation: yes.
- Entry: Skill Factory.
- Runtime: `generateSkill`, `importExternalSkillPath`, `runSkillOperation`, `saveEditedSkill`.
- Artifacts: SKILL.md, config, validation, package, operation history, versions, diff, audit, export package.
- Missing config: model/provider optional; external Skill requires local file.
- Ordinary user exposure: yes after KB/document flow, but should not precede document main chain.
- UI clarity: functionally rich but dense; keep one primary create action, demote validation/export/copy/fuse/bind/view/delete.

### 5.9 Agent / Tool / A2A

- Current implementation: yes for local Agent packages, single dialogue, A2A discussion, permission/audit evidence.
- Entry: Agent Workbench.
- Runtime: `generateAgent`, `completeAgentProductOperations`, `runAgentDialogue`, `exportAgentDialogue`, `runMultiAgentDiscussion`.
- Artifacts: Agent manifests/profiles/config, dialogue md/jsonl/traces, A2A session manifest/round logs/audit/conflict/consensus/report.
- Missing config: LLM/model provider optional; Redis/vector memory optional; Tool policy/provider optional.
- Ordinary user exposure: yes as Agent Workbench, not separate A2A page.
- UI clarity: A2A correctly belongs here, but page should separate create, chat, and collaboration modes.

### 5.10 Artifact Center

- Current implementation: yes for browsing/preview/export/scoped deletion.
- Entry: Artifact Center.
- Runtime: reads runtime artifact paths; `readWorkspaceTextArtifact`, `exportWorkspaceArtifact`, `clearRecentTaskArtifacts`.
- Artifacts: existing generated artifacts, exported copies.
- Missing config: none.
- Ordinary user exposure: yes, but as output center, not creation flow.
- UI clarity: should remain report/output browsing.

### 5.11 Audit / Configuration / Release

- Current implementation: audit/config yes; release governance docs yes; no release action performed.
- Entry: Governance & Audit, Settings, GitHub governance docs.
- Runtime: audit export, parallel validation, config profile, provider validation, model gateway, exporter, Redis/Qdrant.
- Artifacts: audit report, config logs/json/jsonl, provider lifecycle audit, governance reports.
- Missing config: external provider endpoints/secrets/services.
- Ordinary user exposure: Settings yes; audit yes; release/gate concepts should not be primary ordinary UI.
- UI clarity: Settings and Audit are overloaded with developer/industrial terms and need careful demotion/hiding.

## 6. UI Restructure Pre-Judgment

### 6.1 Recommended Main Navigation

Keep ordinary main nav:

1. 首页
2. 工作本
3. 文档库
4. 知识库
5. 检索验证
6. 文档生成
7. Skill 工厂
8. Agent 工作台
9. 产物中心
10. 审计中心
11. 设置

Do not add:

- A2A as first-level page.
- OKF as first-level page.
- Provider project loading as first-level page.
- Gate/Campaign/Capability Matrix as ordinary page.

### 6.2 Should Move To Settings

- Provider/Gateway/ModelRoute config.
- Redis/Qdrant/vector settings and health.
- Exporter provider config.
- Network authorization.
- Profile lifecycle.
- Tool/Agent memory policy config.

Business pages should show only concise status and a Settings link.

### 6.3 Should Move To Audit Center

- parallel task capacity validation,
- provider lifecycle audit summaries,
- config/profile activation logs,
- failure/degradation records,
- run history,
- release/CI/governance evidence,
- Stage2/Stage3 industrial reports.

### 6.4 Should Hide Or Developer-Mode

- `operation-gate`
- `capability-matrix`
- `task-job-center`
- Core action matrices
- raw Gate/Campaign labels
- disabled boundary internals
- external runtime load debug details
- provider readiness internal matrices unless in audit/developer mode.

### 6.5 Should Merge Or Demote

- Import/Parsing member route should be presented as Document Library import/parse workflow, not competing page.
- Vector Hub / Provider / Storage should be Settings plus KB index status.
- Memory Center should be Agent/Settings/Audit status, not independent ordinary path.
- Error Repair Center should be Audit/issue detail, not main navigation.
- Skill validation/export/copy/fuse/bind should be more/row actions.
- Agent package/history/export should be secondary in Agent Workbench or Artifact Center.

### 6.6 Must Keep Yellow / Incomplete / Config Labels

- DOCX/PDF/PPTX export until exporter configured.
- External fact verification/search until network/provider authorized.
- Redis memory until Redis test passes.
- External vector DB until endpoint/dimension/collection test passes.
- Model provider until masked config and test pass.
- N8N/RTK runtime health-load until endpoint/health evidence exists; never claim workflow execution from health check.
- Template assets that are not runtime providers.

### 6.7 Must Not Show Fake Available State

- Web import as real crawl without network authorization.
- Office export without exporter config.
- External Provider runtime without health/readiness evidence.
- Test-only zero-token model route as release provider.
- Template assets as Provider runtime.
- Standard package / OKF as independent runtime module.

## 7. Main Findings

1. The real local user chain exists and is test-covered: import -> parse/chunk -> KB -> retrieval -> Markdown -> Skill -> Agent -> A2A -> artifacts/audit.
2. UI page extraction exists, but coupling remains because feature files are `part of main.dart`.
3. The biggest UI IA issue is not missing pages; it is mixed action hierarchy inside dense pages, especially Settings, Skill, Agent, Audit.
4. The biggest runtime structure issue is still `rc6_runtime_controller_io.dart`.
5. A2A is correctly in Agent Workbench and should remain there.
6. OKF/standard package has runtime package evidence but should remain an internal/advanced package layer.
7. Provider external loading should be exposed as capability status/config, not external project names/modules.
8. Artifact Center and Audit Center should be output/evidence centers, not primary creation surfaces.

## 8. Readiness For Next Gate

Next gate can be:

```text
ui_information_architecture_restructure_plan_gate
```

Condition: the plan must be based on this report and must not begin by visual restyling.

Plan gate should require:

1. Button Audit Matrix using current feature files.
2. Main/secondary/more/destructive action model per page.
3. Mapping from every retained button to runtime method or artifact/view action.
4. Explicit list of buttons to hide, demote, or move to Settings/Audit.
5. No runtime changes unless a UI action currently points to a false state.
6. No deletion of capability without test and artifact mapping.

UI visual polish should remain later than information architecture restructuring.

## 9. Validation For This Report

This was a read-only inventory plus report creation. No code validation was required because no code changed.

Basic checks to run after report creation:

- confirm report path exists,
- `git diff --check -- docs/audits/current/ui_real_capability_and_structure_inventory_report.md`,
- scan report for prohibited overclaims.

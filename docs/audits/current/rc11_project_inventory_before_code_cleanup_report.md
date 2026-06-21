# rc11 Project Inventory Before Code Cleanup Report

Gate: `rc11_project_inventory_before_code_cleanup_gate`

Generated: 2026-06-21

Scope: read-only project inventory before systematic code cleanup. This report does not claim all external runtimes are integrated. Stage3 is treated as provider/gateway/model-route/profile/readiness/binding/rollback/audit mechanism closure, while external projects remain governed by readiness/reference/verification status unless runtime evidence proves otherwise.

## 1. Current Repository Structure

Workspace root: `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge`

Top-level entries:

| Path | Role |
| --- | --- |
| `kb-forge-skill-ui/` | Main UI/product workbench repo on `feature/workbench-ui-prototype`; current HEAD `5bc0332 Add stage3 final provider acceptance report`. |
| `kb-forge-skill/` | Core/Python repo on `main`; current HEAD observed `f150e55 Harden stage3 architecture intake criteria`. |
| `archive/` | Workspace-level archive. |
| `README.md`, `project_pointer.md`, `AGENTS.md` | Workspace-level project control and pointers. |
| `V3_PAGE_DESIGN_AND_FEATURE_EVALUATION_2026-06-19.md` | Workspace-level product evaluation artifact. |

Current UI repo dirty state before this report:

- Modified: `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md`
- Modified: `web/workbench/flutter_app/lib/features/document_library/document_library_product_workflow.dart`
- Modified: `web/workbench/flutter_app/test/stage2_industrial_evidence_refresh_test.dart`
- Untracked: `web/workbench/flutter_app/output/`

Current Core repo dirty state before this report:

- Modified campaign/governance docs under `docs/campaigns/` and `docs/治理/`
- Untracked campaign reports and `output/`

These pre-existing changes were not reverted. Gate1 produced this report only as the intended durable artifact.

## 2. Core / UI / Docs / Tests / Scripts Tree Summary

UI repo tracked top-level distribution:

| Top path | Tracked count |
| --- | ---: |
| `heitang_kb_forge/` | 400 |
| `docs/` | 280 |
| `tests/` | 273 |
| `examples/` | 134 |
| `web/` | 134 |
| `desktop/` | 74 |
| `scripts/` | 3 |
| `.github/` | 2 |

UI Flutter app `lib/` distribution:

| Dir | Files | Lines |
| --- | ---: | ---: |
| `rc6_runtime` | 4 | 26049 |
| `features` | 12 | 10485 |
| `contracts` | 7 | 2137 |
| `main.dart` | 1 | 2037 by `Get-Content`; last physical line 2142 by `rg` due line endings/blanks |
| `app` | 4 | 1313 |
| `workbench` | 2 | 1187 |
| `shared` | 2 | 1092 |
| `skill_factory` | 1 | 870 |
| `core_bridge` | 5 | 628 |
| `backend_evidence` | 1 | 584 |
| `core_actions` | 3 | 519 |

Core repo Python module distribution, top observed modules by file count:

| Module | Python files |
| --- | ---: |
| `schemas` | 68 |
| `llm` | 33 |
| `parser_backends` | 22 |
| `campaign_3_closure` | 17 |
| `cli_commands` | 15 |
| `parsers` | 14 |
| `retrieval` | 13 |
| `workbench` | 12 |
| `external_sources` | 11 |
| `workspace` | 10 |

Docs current/product/governance anchors in UI repo:

- `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- `docs/product/PRD_V3_2026-06-19.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`
- `docs/current/CURRENT_PRODUCT_BASELINE_2026-06-19.md`
- `docs/governance/发布流程.md`
- `docs/governance/登记项目治理.md`
- `docs/governance/外部运行时参考队列.md`

`docs/code_map/` does not exist yet. Existing related file: `docs/WORKBENCH_PRODUCT_FLOW_CODE_MAP_2026-06-19.md`.

Scripts in UI repo:

- `scripts/smoke_agent_flow.ps1`
- `scripts/smoke_quickstart.ps1`
- `scripts/smoke_windows_exe_launch.ps1`

GitHub workflows in UI repo:

- `.github/workflows/ci.yml`
- `.github/workflows/release-check.yml`

## 3. `main.dart` Current Responsibilities And Line Count

File: `web/workbench/flutter_app/lib/main.dart`

Line count: 2037 by `Get-Content`; last physical line 2142 by `rg`.

Current responsibilities:

- App bootstrap: `main()` and `HeiTangWorkbenchApp`.
- Product page registry and navigation order.
- Desktop shell setup, top bar/sidebar/status bar wiring through `part` files.
- Runtime controller initialization and injection through `_Rc6RuntimeScope`.
- Asset/contract loading futures for Provider capability status, parser backend matrix, campaign-era contracts, skill governance data, and workflow evidence.
- Page routing into dashboard, document library, knowledge base, retrieval, document generation, Skill, Agent, artifact, audit, settings.
- Workspace artifact preview dialog logic.
- Sample fixture constants for campaign/runtime/product status.

Structural finding:

- `main.dart` imports 18 `part` files from `app/`, `shared/`, and `features/`.
- Feature files are visually separated into directories but still compile as parts of `main.dart`, so they are tightly coupled to private symbols and sample constants in `main.dart`.
- Campaign-era sample constants and status payloads remain in the app entry file.

## 4. `rc6_runtime_controller_io.dart` Current Responsibilities And Line Count

File: `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`

Line count: 24518 by `Get-Content`; last physical line 25056 by `rg`.

Current responsibilities observed from public methods and private writer functions:

- Workspace/workbook lifecycle and manifest persistence.
- File/folder/web import, parser/OCR/chunking, DU artifacts.
- Standard knowledge package / OKF candidate export/import and KB build.
- Knowledge base CRUD: build, copy, merge, split, update, rebuild, compare, rollback, delete.
- Search, multi-KB retrieval, retrieval validation reports.
- Markdown/document generation, structured export, document history.
- Redis and Qdrant connection tests and config persistence.
- ProjectConfigProfile CRUD, activation, deletion protection, rollback, persistence smoke.
- Provider runtime settings, registered provider capability sync/test/activation/rollback.
- N8N and RTK runtime load/rollback health-check flows.
- Model Gateway / ModelRoute config, route pool, binding matrix, audit and downstream evidence.
- Exporter settings and validation.
- Parallel task capacity validation.
- Artifact preview/export/delete utilities.
- Skill generation, external Skill import/localization, Skill operation history, versions/diff/rollback/audit.
- Agent generation, dialogue, dialogue export, A2A discussion, permissions/audit/run history.
- Stage2 industrial smoke and EXE smoke report generation.
- Stage3 provider integration/readiness/final acceptance report generation.

Structural finding:

- This file is the dominant runtime god-object. It combines domain schema construction, repository IO, service orchestration, acceptance evidence generation, test fixture materialization, provider readiness, and product runtime state mutation.
- It should remain a compatibility facade during cleanup; direct extraction should be service-by-service with public methods preserved.

## 5. Extracted Feature Pages

Current feature page files under `web/workbench/flutter_app/lib/features/`:

| Feature | File | Lines |
| --- | --- | ---: |
| Agent workspace | `features/agent/agent_product_workflow.dart` | 1593 |
| Artifacts | `features/artifacts/artifact_center_product_workflow.dart` | 336 |
| Audit | `features/audit/audit_center_product_workflow.dart` | 619 |
| Dashboard | `features/dashboard/dashboard_product_workflow.dart` | 1012 |
| Document generation | `features/document_generation/document_generation_product_workflow.dart` | 1211 |
| Document library | `features/document_library/document_library_product_workflow.dart` | 500 |
| Import/parsing | `features/import_parsing/import_product_workflow.dart` | 507 |
| Knowledge base | `features/knowledge_base/knowledge_base_product_workflow.dart` | 906 |
| Retrieval verification | `features/retrieval/retrieval_verification_product_workflow.dart` | 587 |
| Settings | `features/settings/settings_product_workflow.dart` | 1852 |
| Skill factory | `features/skill/skill_builder_product_workflow.dart` | 1004 |
| Workbook | `features/workbook/workbook_product_workflow.dart` | 358 |

All observed feature files start with `part of '../../main.dart';`, so they are not independent libraries yet.

## 6. Extracted Runtime Service

Flutter-side runtime files:

| File | Lines | Role |
| --- | ---: | --- |
| `rc6_runtime/rc6_runtime_controller.dart` | 3 | Conditional export facade. |
| `rc6_runtime/rc6_runtime_controller_io.dart` | 24518 | IO runtime controller and orchestration monolith. |
| `rc6_runtime/rc6_runtime_controller_stub.dart` | 1302 | Web/stub runtime state surface. |
| `rc6_runtime/project_config_profile.dart` | 226 | ProjectConfigProfile domain/model object. |

Core-side service modules already exist across many Python packages including `providers`, `provider_security`, `llm`, `embedding`, `vector`, `parsers`, `ocr`, `retrieval`, `skill`, `agent`, `agent_tools`, `agent_rag`, `workspace`, `runtime`, `schemas`, and `workbench`.

UI-side runtime services are not yet split into `runtime/services`, `runtime/adapters`, `runtime/repositories`, or `domain/*` modules.

## 7. Existing Domain / Schema / Model Files

Flutter UI:

- `rc6_runtime/project_config_profile.dart` defines `ProjectConfigProfile` fields including `profileId`, `displayName`, `mode`, `workspaceId`, config IDs, policy IDs, active/default/version timestamps, test status, last error, and rollback reference.
- `contracts/contract_models.dart`, `contracts/external_capabilities.dart`, `contracts/parser_backend_matrix.dart`, `contracts/workflow_evidence.dart` define UI contract/domain-like models.
- `workbench/task_model.dart` defines task/workbench model data.

Core Python:

- `heitang_kb_forge/schemas/` is the largest schema area in both repos.
- Provider/config schema files observed include `schemas/provider_registry_schema.py`, `schemas/llm_provider_schema.py`, `schemas/prompt_profile_schema.py`, `schemas/config_schema.py`.
- Model/provider modules observed include `llm/provider.py`, `llm/provider_router.py`, `llm/provider_registry.py`, `llm/provider_policy.py`, `llm/provider_health.py`, `embedding/provider.py`, `providers/registry.py`, `providers/readiness.py`, `providers/health.py`, `providers/config.py`.

Gap:

- Flutter has only partial domain extraction. Most runtime schemas and domain payloads are still built as maps inside `rc6_runtime_controller_io.dart`.

## 8. Configuration Capability Files

UI Flutter:

- `features/settings/settings_product_workflow.dart`
- `rc6_runtime/project_config_profile.dart`
- `rc6_runtime/rc6_runtime_controller_io.dart`
- `contracts/external_capabilities.dart`
- Asset contracts under `web/workbench/flutter_app/assets/contracts/` and `assets/external/`

UI/Core Python:

- `provider_config.example.yaml`
- `heitang_kb_forge/config/loader.py`
- `heitang_kb_forge/schemas/config_schema.py`
- `heitang_kb_forge/providers/config.py`
- `heitang_kb_forge/prompt_profiles/*`
- many `tests/test_*config*.py`

Runtime artifact paths observed under output workspaces include:

- `config/project_config_profiles.json`
- `config/project_config_runtime_status.json`
- `config/config_test_log.jsonl`
- `config/profile_change_log.jsonl`
- `config/profile_activation_log.jsonl`
- `config/provider_runtime_settings.json`
- `config/storage_provider_settings.json`
- `config/exporter_settings.json`

## 9. Gateway / Provider / ModelRoute / Profile Files

Flutter UI/runtime anchors:

- `features/settings/settings_product_workflow.dart`: Provider/model/profile UI panels.
- `contracts/external_capabilities.dart`: Provider capability status model and sample provider classification/status data.
- `rc6_runtime/project_config_profile.dart`: Profile schema.
- `rc6_runtime/rc6_runtime_controller_io.dart`: provider sync/test/activate/rollback, Model Gateway config, ModelRoute pool/binding/audit artifact writing.

Core anchors:

- `heitang_kb_forge/llm/provider_router.py`
- `heitang_kb_forge/llm/provider_registry.py`
- `heitang_kb_forge/llm/provider_policy.py`
- `heitang_kb_forge/llm/provider_health.py`
- `heitang_kb_forge/llm/provider_fallback.py`
- `heitang_kb_forge/providers/registry.py`
- `heitang_kb_forge/providers/readiness.py`
- `heitang_kb_forge/providers/health.py`
- `heitang_kb_forge/provider_security/audit.py`
- `heitang_kb_forge/provider_security/governance.py`

Evidence artifact names observed in code/tests:

- `model_route_pool.json`
- `model_route_binding_matrix.json`
- `model_route_audit.jsonl`
- `registered_provider_integration_matrix.json`
- `registered_provider_health_report.json`
- `provider_runtime_load_manifest.json`
- `provider_runtime_load_eligibility_manifest.json`
- `stage3_full_provider_loading_matrix.json`
- `stage3_industrial_provider_loading_report.json`
- `stage3_final_provider_acceptance_report.json`

Local output note:

- `web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/stage3_full_provider_loading_matrix.json` exists.
- A direct `stage3_final_provider_acceptance_report.json` was not present in the checked output paths during Gate1, despite HEAD commit title referencing it. Treat this as inventory fact, not as failure of the commit.

## 10. OCR / OKF / Pipeline Route Files

Flutter anchors:

- `backend_evidence/parser_backend_dashboard.dart`
- `contracts/parser_backend_matrix.dart`
- `features/import_parsing/import_product_workflow.dart`
- `features/document_library/document_library_product_workflow.dart`
- `features/knowledge_base/knowledge_base_product_workflow.dart`
- `rc6_runtime/rc6_runtime_controller_io.dart`

Observed runtime/controller operations:

- Parser/OCR status loading from `assets/parser_backends/parser_backend_matrix.json`.
- Standard knowledge package export/import.
- OKF candidate package runtime manifest writing.
- OKF-to-KB build/materialization.
- Pipeline/model route binding includes `okf_pipeline` and `okf_compilation` route scopes in tests.

Core anchors:

- `heitang_kb_forge/parsers/`
- `heitang_kb_forge/parser_backends/` in core repo
- `heitang_kb_forge/ocr/`
- `heitang_kb_forge/pipeline/`
- `heitang_kb_forge/retrieval/`
- `heitang_kb_forge/vector/`

Boundary finding:

- Current product docs still state OKF is a standard knowledge package candidate layer, not a first-level page.
- OKF boundary scan hits are mostly prohibition/boundary statements, not implementation claims.

## 11. Skill / External Skill / Agent / Tool / A2A Files

Flutter feature/runtime anchors:

- `features/skill/skill_builder_product_workflow.dart`
- `features/agent/agent_product_workflow.dart`
- `skill_factory/skill_factory_workflow.dart`
- `rc6_runtime/rc6_runtime_controller_io.dart`

Observed runtime methods:

- `generateSkill`, `pickAndImportExternalSkill`, `importExternalSkillPath`, `runSkillOperation`, `saveEditedSkill`.
- `generateAgent`, `runAgentDialogue`, `exportAgentDialogue`, `runMultiAgentDiscussion`.
- Internal writers for Skill product operations, Skill factory package artifacts, Skill runtime evidence, Skill version record, Agent product operations, Agent authorization runtime evidence, Agent run history, orchestration plan, A2A discussion.

Core anchors:

- `heitang_kb_forge/skill/`
- `heitang_kb_forge/skill_templates/`
- `heitang_kb_forge/skill_validation/`
- `heitang_kb_forge/skill_suite/` in core repo
- `heitang_kb_forge/skill_reverse_fusion/` in core repo
- `heitang_kb_forge/agent/`
- `heitang_kb_forge/agent_package/`
- `heitang_kb_forge/agent_tools/`
- `heitang_kb_forge/agent_rag/`
- `heitang_kb_forge/local_agent_runtime/` in core repo
- `heitang_kb_forge/memory_lifecycle/` in core repo
- `heitang_kb_forge/multi_kb_orchestration/` in core repo

UI architecture note:

- A2A appears under Agent workspace tests and feature page, not as a separate top-level page in current page registry.

## 12. Artifact / Audit Files

Flutter feature/runtime anchors:

- `features/artifacts/artifact_center_product_workflow.dart`
- `features/audit/audit_center_product_workflow.dart`
- `backend_evidence/parser_backend_dashboard.dart`
- `contracts/contract_models.dart`
- `rc6_runtime/rc6_runtime_controller_io.dart`

Observed runtime operations:

- Workspace artifact preview/export/delete.
- Audit report export.
- Agent run history.
- Skill operation history.
- Provider health/audit logs.
- Profile change/activation/test logs.
- Model route audit.
- Standard package audit.
- Orchestration plan records.

Core anchors:

- `heitang_kb_forge/audit/` in core repo.
- `heitang_kb_forge/evidence_gate/`, `quality_gate/`, `governance/`, `review/`, `risk/`, `release_readiness/`, `release_blockers/`.

Gap:

- Artifact/audit concerns are present but distributed. There is no UI-side `domain/artifact`, `domain/audit`, or `runtime/services/audit_service.dart` layer yet.

## 13. Tests Distribution

UI Flutter app tests: 15 files.

Largest test files:

| Test | Lines |
| --- | ---: |
| `rc6_runtime_truth_blocker_repair_test.dart` | 9510 |
| `widget_test.dart` | 973 |
| `campaign_4_workbench_test.dart` | 788 |
| `stage2_industrial_evidence_refresh_test.dart` | 684 |
| `rc5_full_capability_runtime_repair_test.dart` | 400 |
| `campaign_4_5_contract_test.dart` | 340 |

Core/UI Python tests in UI repo: tracked under root `tests/`, 273 files. Major areas include agent, RAG, config, provider, parser/OCR, docs/governance, release, retrieval, skill, workspace, and web/workbench contracts.

Finding:

- `rc6_runtime_truth_blocker_repair_test.dart` is a second monolith mirroring the runtime controller. It mixes Stage2, Stage3, PRD, provider, OKF, Skill, Agent, artifact, workbook, and smoke tests.
- Many tests retain campaign/rc naming. This preserves regression history but makes product-layer ownership hard to see.

## 14. Legacy / rc / campaign Naming Residue

Observed residues:

- Flutter test files named `campaign*`, `rc3*`, `rc4*`, `rc5*`, `rc6*`, `stage2*`.
- Runtime package name `rc6_runtime`.
- `_appVersionLabel = 'v4.3.0-rc10'` in `main.dart`.
- Campaign status assets under `assets/contracts/campaign*_*.json`.
- Docs under `docs/current/RC12_*`, `docs/audits/current/rc10_*`, `rc11_*`, `rc13_*`.
- Legacy docs such as `docs/CAPABILITY_STATUS.md` still mention older stable/campaign lines.
- UI source still contains internal terms in code/sample data/tests: `Campaign`, `Gate`, `disabled_boundary`, `enabled_real`, and `Core 操作`.

Important distinction:

- Some tests assert these terms do not appear in ordinary product UI. That is acceptable as regression coverage.
- Source/data naming should be cleaned gradually; do not mechanically rename everything in one pass because tests and assets depend on these names.

## 15. Duplicate Code And High Coupling Points

Primary coupling points:

1. `rc6_runtime_controller_io.dart` combines multiple domains and is the highest-risk coupling point.
2. `main.dart` owns app setup, private state, page registry, sample data, runtime injection, and page routing.
3. Feature page files are only physically separated; `part of` keeps them coupled to `main.dart` internals.
4. `settings_product_workflow.dart` overlaps profile, provider, storage, Redis/Qdrant, exporter, and capability status UI.
5. `agent_product_workflow.dart` overlaps Agent creation, single dialogue, A2A discussion, history, recovery, provider/memory/tool settings.
6. Runtime evidence writers duplicate JSON map construction patterns for manifests, audits, health reports, binding reports, and smoke reports.
7. Tests duplicate runtime artifact expectations across Stage2/Stage3 provider acceptance cases.

## 16. High-Risk Areas Not Recommended For Immediate Refactor

Do not start cleanup by rewriting these areas:

- Public methods on `Rc6RuntimeController`; widgets/tests call them directly.
- Artifact paths under output workspaces; many tests assert exact paths and schema versions.
- `rc6_runtime_controller.dart` conditional export behavior.
- Stage2/Stage3 provider readiness and runtime-loaded semantics.
- OKF package/KB/chunk/audit path conventions.
- Agent authorization and secret masking logic.
- `campaign_4_workbench_test.dart` and `widget_test.dart` UI assertions until page files are independent libraries.
- Core Python schema files without a focused migration plan.

## 17. Low-Risk Areas For Safe Mechanical Movement

Potentially safe after a plan and targeted tests:

1. Extract Flutter data/model classes from `main.dart` sample constants into `domain/*` or `shared/sample_data/*` without behavior change.
2. Convert feature page `part` files into independent imports one feature at a time, starting with smaller pages: artifact center, workbook, document library, import parsing.
3. Move repeated status badge/card/layout widgets from `main.dart`/parts into `shared/` libraries after import independence.
4. Extract pure JSON path helpers and serializer helpers from `rc6_runtime_controller_io.dart` into private runtime utility files while preserving public facade methods.
5. Extract `ProjectConfigProfile` adjacent services into `runtime/services/config_profile_service.dart` after tests lock current behavior.
6. Split audit/artifact writer helpers after preserving exact output schemas.
7. Create `docs/code_map/` and generate code maps; this is low-risk documentation structure work.

## 18. Current Analyze / Test / Build Status

Commands run during Gate1:

| Command | Result | Exit code | Log path / note |
| --- | --- | ---: | --- |
| `flutter analyze` | Passed: no issues found | 0 | Temporary log generated then summarized. |
| `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 authorized profile proves full provider loading matrix evidence" --concurrency=1` | Passed | 0 | Proves the targeted Stage3 provider matrix test currently passes. |
| `flutter test` | Failed | 1 | 144 passed, 3 skipped, 13 failed in the observed run. Failures include duplicate `多 Agent / A2A` widget match, Stage2 evidence refresh timeout, and multiple Stage3 provider evidence count/schema assertions. |
| `flutter build web` | Passed | 0 | Built `build/web`; warning about Wasm dry run and missing CupertinoIcons font family while MaterialIcons was present. |
| `flutter build windows` | Passed | 0 | Built `build/windows/x64/runner/Release/heitang_workbench.exe`. |
| `git diff --check` | Passed with Windows LF/CRLF warnings only | 0 | No whitespace errors reported. |
| High-confidence secret scan | Passed | 0 | No high-confidence key/token matches found. |
| Broad secret field scan | Review needed | 0 after normalization | Matches are test fake values and code field names such as `apiKey`, `password`, `secret=redacted`; no confirmed plaintext secret in this pass. |
| Overclaim scan | Review needed | 0 after normalization | Matches are prohibition/boundary text such as “不打 stable v4.3.0”, not positive release claims. |
| OKF boundary scan | Review needed | 0 after normalization | Matches are boundary/prohibition statements, not OKF first-level page claims. |

Remote CI status:

- Latest observed GitHub Actions run: `27900820653`, status `completed/success`, commit `5bc0332 Add stage3 final provider acceptance report`, branch `feature/workbench-ui-prototype`.

## 19. Recommended Refactor Order

Recommended order for Gate2 planning:

1. Freeze public behavior contracts: list `Rc6RuntimeController` public methods and exact artifact paths before extraction.
2. Convert small feature page parts into independent libraries: artifact center, workbook, document library, import parsing.
3. Extract shared UI components from `main.dart` after those pages no longer depend on private symbols.
4. Extract domain models/schemas from runtime maps: config profile, provider status, model route, artifact/audit, document/KB/Skill/Agent records.
5. Extract config/profile/provider/model gateway runtime services while keeping `Rc6RuntimeController` as compatibility facade.
6. Extract document/KB/retrieval/generation runtime services.
7. Extract Skill/external Skill runtime services.
8. Extract Agent/Tool/A2A runtime services.
9. Extract artifact/audit writer services and shared JSON/schema helpers.
10. Split `rc6_runtime_truth_blocker_repair_test.dart` into domain-aligned test files while keeping the legacy file as regression until full coverage is migrated.
11. Rename/contain rc/campaign naming only after code ownership is clear and tests are stable.

## 20. Inputs Needed For Cleanup Plan

Gate2 should use this report plus these concrete inputs:

- Current public method list of `Rc6RuntimeController`.
- Current feature file line counts and `part of` dependencies.
- Current failing full Flutter test list from Gate1.
- Current artifact path/schema conventions from `rc6_runtime_truth_blocker_repair_test.dart`.
- Current docs baseline paths under `docs/product/` and `docs/current/`.
- Existing dirty-file list so cleanup execution does not overwrite unrelated owner/Codex changes.
- Decision to keep `rc6_runtime_controller_io.dart` as compatibility facade during extraction.
- Decision to create `docs/code_map/` in execution phase.
- CI latest green run ID `27900820653` as remote baseline, with local full Flutter test currently failing.

## Final Gate1 Conclusion

The project is ready for Gate2 planning, but not ready for blind mechanical refactor. The UI has product page files and provider/profile/runtime capabilities, yet still relies on a large `main.dart` + monolithic `rc6_runtime_controller_io.dart` structure. Cleanup should preserve user-visible behavior and artifact semantics while gradually extracting independent libraries, services, domain models, and tests.

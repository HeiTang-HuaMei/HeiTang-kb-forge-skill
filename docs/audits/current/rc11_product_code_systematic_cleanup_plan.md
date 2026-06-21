# rc11 Product Code Systematic Cleanup Plan

Gate: `rc11_product_code_systematic_cleanup_plan_gate`

Input report: `docs/audits/current/rc11_project_inventory_before_code_cleanup_report.md`

Generated: 2026-06-21

This plan is based on the Gate1 inventory facts, not historical memory. It does not modify business code, runtime behavior, UI behavior, tags, releases, or Git history.

## 1. Refactor Goal

Restructure the current product code from a history-stacked `main.dart` + `rc6_runtime_controller_io.dart` layout into a maintainable product engineering structure while preserving user-visible behavior, runtime semantics, artifact paths, schema versions, Provider readiness semantics, ModelRoute evidence semantics, and Stage2/Stage3 boundary claims.

Target direction inside `web/workbench/flutter_app/lib/`:

```text
main.dart
app/
features/
runtime/
domain/
shared/
```

The cleanup must not claim external runtimes are all integrated. Stage3 remains provider/gateway/model-route/profile/readiness/binding/rollback/audit mechanism closure unless explicit runtime evidence proves otherwise.

## 2. User-Visible Behavior Freeze

Rules for all execution steps:

- Do not add business features.
- Do not redesign UI or visual style.
- Do not change page order, button availability, artifact paths, schema versions, status semantics, or generated output structure unless a compatibility migration is added and tested.
- Do not rename `rc6_runtime` public imports until all tests and downstream references are migrated.
- Keep `Rc6RuntimeController` public methods callable with the same names/signatures during extraction.
- Keep output workspace paths such as `config/project_config_runtime_status.json`, `config/model_route_pool.json`, `agent/audit/run_history.json`, standard package manifests, KB manifests, Skill artifacts, Agent artifacts, and A2A reports stable.
- Keep reference/readiness/test-only wording accurate: never convert `reference_only`, readiness-only, or test-only zero-token routes into release providers.

## 3. Pre-Execution Stabilization Step

Before moving files, fix or quarantine only the local test-state issues already exposed by Gate1 full `flutter test`:

1. Duplicate widget text assertion in `campaign_4_workbench_test.dart` around `多 Agent / A2A`.
2. Stage2 evidence refresh timeout in `stage2_industrial_evidence_refresh_test.dart`.
3. Stage3 provider evidence count/schema assertions in `rc6_runtime_truth_blocker_repair_test.dart` that failed during full-suite execution but passed for the targeted Stage3 matrix test.

Validation:

```powershell
flutter analyze
$env:NO_PROXY='127.0.0.1,localhost,::1'; $env:no_proxy='127.0.0.1,localhost,::1'; flutter test
```

Rollback:

- Revert only the test changes in the touched files.
- Do not revert existing unrelated dirty edits unless Owner explicitly requests.

Commit boundary:

- Commit 1: `Stabilize UI runtime tests before cleanup`.

Rationale:

- Gate1 proves `flutter analyze`, targeted Stage3 test, web build, and Windows build pass, but full `flutter test` currently fails. Refactoring on top of failing full tests reduces signal quality.

## 4. `main.dart` Complexity Reduction Plan

Current Gate1 facts:

- `main.dart`: 2037 lines by `Get-Content`, 18 `part` files, app bootstrap + page registry + runtime injection + sample data + page routing.
- All feature/app/shared part files depend on `part of` and private symbols.

Execution sequence:

1. Extract product page registry and page IDs into `app/workbench_pages.dart`.
2. Extract runtime scope into `app/rc6_runtime_scope.dart`.
3. Extract sample status payloads into `shared/sample_data/` or `domain/*/sample_*` files.
4. Convert smallest part files to standalone imports first:
   - `features/artifacts/artifact_center_product_workflow.dart`
   - `features/workbook/workbook_product_workflow.dart`
   - `features/document_library/document_library_product_workflow.dart`
   - `features/import_parsing/import_product_workflow.dart`
5. Convert shell/shared part files after feature dependencies are explicit:
   - `app/product_top_bar.dart`
   - `app/desktop_status_bar.dart`
   - `app/workbench_sidebar.dart`
   - `app/workbench_shell.dart`
   - `shared/workbench_layout.dart`
   - `shared/product_components.dart`
6. Convert larger feature files last:
   - dashboard
   - retrieval
   - audit
   - knowledge base
   - skill
   - document generation
   - settings
   - agent

Validation after each small batch:

```powershell
flutter analyze
flutter test test\widget_test.dart --concurrency=1
flutter test test\campaign_4_workbench_test.dart --concurrency=1
flutter test test\rc3_ui_usability_repair_test.dart --concurrency=1
```

Rollback:

- Revert the converted file and import changes for that batch only.
- Keep previous successful batches.

Commit boundary:

- Commit 2: `Split workbench app shell from main entrypoint`.
- Commit 3: `Convert low-risk feature pages to independent libraries`.
- Commit 4: `Convert remaining feature pages to independent libraries`.

Expected outcome:

- `main.dart` becomes bootstrap, high-level app composition, and dependency wiring only.
- Feature files become independent libraries with explicit imports.

## 5. `rc6_runtime_controller_io.dart` Compatibility Facade Plan

Current Gate1 facts:

- `rc6_runtime_controller_io.dart`: 24518 lines by `Get-Content`, dominant runtime god-object.
- `rc6_runtime_controller.dart` is a 3-line conditional export facade.
- Public `Rc6RuntimeController` methods are used by widgets/tests and must remain stable.

Facade rule:

- `Rc6RuntimeController` remains the public compatibility facade throughout rc11 cleanup.
- New services are private dependencies owned by the controller first. Public widgets/tests still call the controller.
- Extraction moves implementation behind the same public methods, not call sites first.

Planned runtime structure:

```text
runtime/
  rc6_runtime_controller.dart       # existing conditional export remains
  facade/                           # optional later, if compatible
  services/
  adapters/
  repositories/
  migrations/
  support/
```

Initial safe extractions:

1. Pure support helpers:
   - JSON map/list/string/bool helpers.
   - path ownership checks.
   - timestamp/id helpers.
   - bounded text read helpers.
2. Repository helpers:
   - workspace file IO helpers.
   - artifact path resolution.
   - manifest read/write helpers.
3. Domain service groups:
   - Config/Profile/Provider/ModelRoute first.
   - Document/KB/Retrieval/Generation second.
   - Skill/External Skill third.
   - Agent/Tool/A2A fourth.
   - Artifact/Audit last, once path semantics are locked.

Validation after each service extraction:

```powershell
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "project config profile lifecycle persists and protects active profile" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "model gateway provider persists masked config and syncs runtime status" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 authorized profile proves full provider loading matrix evidence" --concurrency=1
```

Rollback:

- Revert the new service file and the corresponding delegation in `rc6_runtime_controller_io.dart`.
- Public controller methods remain unchanged, so rollback is localized.

## 6. Config/Profile/ModelRoute/Provider Module Split

Target files:

```text
domain/config_profile/project_config_profile.dart
domain/provider/provider_capability_status.dart
domain/model_gateway/model_gateway_config.dart
domain/model_route/model_route_models.dart
runtime/services/config_profile_service.dart
runtime/services/provider_registry_service.dart
runtime/services/model_gateway_service.dart
runtime/services/model_route_service.dart
runtime/repositories/runtime_config_repository.dart
runtime/repositories/provider_audit_repository.dart
```

Scope:

- Move `ProjectConfigProfile` out of `rc6_runtime/` only after import compatibility is preserved through an export shim.
- Extract config profile CRUD/activation/rollback/test logic.
- Extract provider capability sync/test/activate/rollback logic.
- Extract Model Gateway config/test/route pool/binding/audit writers.
- Keep exact artifact names and schema versions.

Validation:

```powershell
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "project config profile lifecycle persists and protects active profile" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "project config activation synchronizes downstream module status" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "provider failure degradation writes masked config test logs" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "model gateway provider persists masked config and syncs runtime status" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 authorized profile proves full provider loading matrix evidence" --concurrency=1
```

Rollback:

- Restore moved methods inside `rc6_runtime_controller_io.dart` and remove service delegation.
- Keep compatibility export for `ProjectConfigProfile` until all imports are updated.

## 7. OCR / OKF / Pipeline Route Split

Target files:

```text
domain/document/document_source.dart
domain/document/parser_status.dart
domain/knowledge_base/standard_knowledge_package.dart
domain/knowledge_base/knowledge_base_record.dart
domain/model_route/pipeline_route_binding.dart
runtime/services/document_import_service.dart
runtime/services/parser_ocr_service.dart
runtime/services/okf_standard_package_service.dart
runtime/services/knowledge_base_service.dart
runtime/services/pipeline_route_service.dart
```

Scope:

- Extract import/parse/chunk/DU artifact logic.
- Extract standard knowledge package export/import/build logic.
- Keep OKF as candidate standard package layer, not a first-level page.
- Extract KB catalog/materialization/version logic only after standard package tests pass.
- Preserve OKF and KB artifact paths and schema versions.

Validation:

```powershell
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "prd standard knowledge package exports imports and builds KB" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "parser ocr adapters become selectable from real parse artifacts" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "embedding vector adapters become selectable from real index artifacts" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "prd multi knowledge base catalog supports copy merge split delete" --concurrency=1
```

Rollback:

- Revert service file and controller delegation for the exact moved method group.

## 8. Skill / External Skill Split

Target files:

```text
domain/skill/skill_models.dart
domain/external_skill/external_skill_models.dart
runtime/services/skill_generation_service.dart
runtime/services/external_skill_localization_service.dart
runtime/services/skill_version_service.dart
runtime/services/skill_audit_service.dart
```

Scope:

- Extract `generateSkill`, external Skill import/localization, Skill operation history, edited Skill save, version snapshot/diff/rollback, Skill validation and runtime evidence writing.
- Preserve Skill artifact paths and Agent binding semantics.

Validation:

```powershell
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "prd external Skill import localizes real file content into workspace" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "skill generation persists type platform and personalization config" --concurrency=1
flutter test test\skill_factory_workflow_test.dart --concurrency=1
```

Rollback:

- Restore Skill methods into controller and remove delegation.

## 9. Agent / Tool / A2A Decoupling Plan

Target files:

```text
domain/agent/agent_models.dart
domain/tool/tool_policy.dart
domain/a2a/a2a_models.dart
runtime/services/agent_generation_service.dart
runtime/services/agent_dialogue_service.dart
runtime/services/agent_authorization_service.dart
runtime/services/a2a_discussion_service.dart
runtime/services/agent_run_history_service.dart
```

Scope:

- Extract Agent generation, single-agent dialogue, dialogue export, Agent authorization runtime evidence, run history, multi-agent discussion/A2A logs, orchestration plan records.
- Keep A2A under Agent workspace semantics.
- Do not create a new A2A top-level page.
- Preserve unauthorized-resource deny evidence and secret masking semantics.

Validation:

```powershell
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "agent generation persists creation mode type and output config" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "prd p0 product smoke writes multiple KBs, localized skill, and A2A" --concurrency=1
flutter test test\campaign_4_workbench_test.dart --plain-name "agent page owns creation, minimal chat, discussion, and history" --concurrency=1
```

Rollback:

- Restore Agent/A2A methods into controller and remove delegation.

## 10. Artifact / Audit Unification Plan

Target files:

```text
domain/artifact/artifact_models.dart
domain/audit/audit_event.dart
runtime/services/artifact_center_service.dart
runtime/services/audit_center_service.dart
runtime/repositories/audit_log_repository.dart
runtime/repositories/artifact_repository.dart
```

Scope:

- Extract bounded artifact preview/export/delete.
- Extract audit report export.
- Centralize append-only JSONL audit writers without changing file names or schemas.
- Reuse repository helpers for config/profile/provider/Skill/Agent audits.

Validation:

```powershell
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "workspace artifact preview reads only bounded text artifacts" --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "prd artifact center exports bounded file and directory artifacts" --concurrency=1
flutter test test\campaign_4_workbench_test.dart --plain-name "audit center shows real execution records and export action" --concurrency=1
```

Rollback:

- Restore artifact/audit methods into controller and remove repository delegation.

## 11. Feature UI Migration Order

Batch order from lowest to highest risk:

1. `features/artifacts/` and `features/workbook/`.
2. `features/document_library/` and `features/import_parsing/`.
3. `features/retrieval/` and `features/audit/`.
4. `features/knowledge_base/`.
5. `features/document_generation/`.
6. `features/skill/`.
7. `features/settings/`.
8. `features/agent/`.
9. `features/dashboard/` after all page models and runtime status dependencies are explicit.

Each batch should:

- Remove `part of` for that file.
- Add explicit imports.
- Pass dependencies through constructors or public model classes.
- Avoid private `_` symbols from `main.dart` where possible.
- Keep visible text and keys unchanged unless fixing existing failing tests.

Validation:

```powershell
flutter analyze
flutter test test\widget_test.dart --concurrency=1
flutter test test\campaign_4_workbench_test.dart --concurrency=1
flutter test test\rc3_ui_usability_repair_test.dart --concurrency=1
```

## 12. Runtime Service Extraction Order

Order:

1. `runtime/support`: pure helpers and path/json utilities.
2. `runtime/repositories`: workspace/config/artifact/audit IO helpers.
3. `runtime/services/config_profile_service.dart`.
4. `runtime/services/provider_registry_service.dart`.
5. `runtime/services/model_gateway_service.dart` and `model_route_service.dart`.
6. `runtime/services/document_import_service.dart` and `parser_ocr_service.dart`.
7. `runtime/services/okf_standard_package_service.dart` and `knowledge_base_service.dart`.
8. `runtime/services/retrieval_service.dart` and `document_generation_service.dart`.
9. `runtime/services/skill_generation_service.dart`, `external_skill_localization_service.dart`, `skill_version_service.dart`.
10. `runtime/services/agent_generation_service.dart`, `agent_dialogue_service.dart`, `agent_authorization_service.dart`, `a2a_discussion_service.dart`.
11. `runtime/services/artifact_center_service.dart` and `audit_center_service.dart`.

Each extraction should move one cohesive group and leave a thin controller delegation method.

## 13. Domain / Schema Extraction Order

Order:

1. `domain/config_profile` from `project_config_profile.dart` with shim export.
2. `domain/provider` from `contracts/external_capabilities.dart` only if UI imports are stable.
3. `domain/model_gateway` and `domain/model_route` from runtime JSON map builders.
4. `domain/document` and `domain/knowledge_base`.
5. `domain/skill` and `domain/external_skill`.
6. `domain/agent`, `domain/tool`, `domain/a2a`.
7. `domain/artifact` and `domain/audit`.

Validation:

- Run targeted tests for each domain group plus `flutter analyze`.

Rollback:

- Keep shim exports during migration.
- Revert domain file and import changes for the failed batch.

## 14. Tests Migration Order

Current facts:

- `rc6_runtime_truth_blocker_repair_test.dart` is 9510 lines and mixes many domains.
- Full `flutter test` currently fails; targeted Stage3 provider test passes.

Order:

1. Stabilize full-suite failures first.
2. Keep `rc6_runtime_truth_blocker_repair_test.dart` as legacy regression while extracting new focused tests.
3. Add focused tests when a service is extracted:
   - `config_profile_runtime_test.dart`
   - `provider_model_route_runtime_test.dart`
   - `document_kb_runtime_test.dart`
   - `skill_runtime_test.dart`
   - `agent_a2a_runtime_test.dart`
   - `artifact_audit_runtime_test.dart`
4. Move only tests whose coverage has a one-to-one replacement.
5. Do not delete legacy tests until the new suite covers the same artifact paths and schema versions.

Validation:

```powershell
flutter test test\new_focused_test.dart --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "matching legacy test" --concurrency=1
```

## 15. Legacy / rc / campaign Naming Strategy

Strategy:

- Keep file names that are part of regression history during first execution rounds.
- Add code map and comments explaining legacy naming where needed.
- Rename only after tests are independent and references are explicit.
- Prioritize hiding internal wording from ordinary UI over renaming internal tests.
- Do not rewrite historical docs in the code cleanup gate; docs/governance restructuring belongs to rc12.

Allowed in rc11 execution:

- Add `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`.
- Add cleanup execution report.
- Add compatibility exports.

Not recommended in rc11 execution:

- Rename `rc6_runtime` package path.
- Rename all campaign test files.
- Rewrite all campaign docs.

## 16. Validation Commands Per Round

Minimum per commit round:

```powershell
flutter analyze
$env:NO_PROXY='127.0.0.1,localhost,::1'; $env:no_proxy='127.0.0.1,localhost,::1'; flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 authorized profile proves full provider loading matrix evidence" --concurrency=1
git diff --check
```

UI feature rounds:

```powershell
flutter test test\widget_test.dart --concurrency=1
flutter test test\campaign_4_workbench_test.dart --concurrency=1
flutter test test\rc3_ui_usability_repair_test.dart --concurrency=1
```

Runtime service rounds:

```powershell
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1
```

Final rc11 execution gate:

```powershell
flutter analyze
$env:NO_PROXY='127.0.0.1,localhost,::1'; $env:no_proxy='127.0.0.1,localhost,::1'; flutter test
flutter build web
flutter build windows
git diff --check
```

Scans:

- High-confidence no-secret scan.
- Broad secret field scan with manual review.
- Overclaim scan.
- OKF boundary scan.

## 17. Rollback Strategy Per Step

General rollback:

- Use non-destructive git diff review.
- Revert only files touched in the current batch.
- Preserve unrelated dirty files.
- Keep compatibility facade intact so a failed service extraction can be reverted without changing UI call sites.

Specific rollback by type:

| Step type | Rollback |
| --- | --- |
| Feature file import conversion | Restore `part of` and remove explicit imports for that file. |
| Shared component extraction | Inline component back into previous file only for touched component. |
| Domain model extraction | Restore original model location or keep shim export and revert imports. |
| Runtime service extraction | Move method body back into `rc6_runtime_controller_io.dart` and delete service delegation. |
| Test split | Keep new test if passing; otherwise remove only new test file and preserve legacy test. |
| Docs/code map | Revert generated report/map only if incorrect. |

## 18. High-Risk Files To Avoid Early

Do not touch early except for test stabilization or compatibility shims:

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart` large behavior blocks.
- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller.dart` conditional export.
- `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart` broad legacy coverage.
- `web/workbench/flutter_app/test/campaign_4_workbench_test.dart` UI regression coverage, except targeted failing assertions.
- `web/workbench/flutter_app/test/widget_test.dart` broad UI contract coverage.
- Core Python `heitang_kb_forge/schemas/` without focused migration.
- Any output artifact path/schema code used by Stage2/Stage3 evidence.

## 19. Low-Risk Mechanical Moves

Low-risk first moves:

- Create `docs/code_map/` and generate code map after code cleanup.
- Move sample constants out of `main.dart` after all imports are explicit.
- Convert low-risk small feature pages from parts to imports.
- Extract pure helper functions from runtime controller that do not touch state or filesystem.
- Add compatibility exports for moved domain models.
- Add focused tests without deleting legacy tests.

## 20. Estimated Commit Rounds

Recommended commit sequence:

1. Stabilize full Flutter test baseline.
2. Split workbench shell/page registry/runtime scope from `main.dart`.
3. Convert low-risk feature pages to independent libraries.
4. Convert remaining feature pages to independent libraries.
5. Extract runtime support/repositories and config/profile/provider/model route services.
6. Extract document/KB/retrieval/generation services.
7. Extract Skill/external Skill services.
8. Extract Agent/Tool/A2A services.
9. Extract Artifact/Audit services and split tests.
10. Generate `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md` and `docs/audits/current/rc11_product_code_systematic_cleanup_execution_report.md`.

Each commit should be independently analyzable and should not mix UI import conversion with runtime service extraction.

## Gate2 Completion Criteria

This plan is complete when execution can start with clear boundaries:

- Known current failures are identified before refactor.
- `main.dart` reduction path is ordered.
- `rc6_runtime_controller_io.dart` remains a compatibility facade.
- Config/Profile/Provider/ModelRoute split is prioritized before broader runtime extraction.
- OKF remains a standard package candidate layer.
- A2A remains under Agent workspace.
- Validation and rollback are defined for every step.

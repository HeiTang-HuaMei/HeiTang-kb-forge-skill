# Workbench Code Map After rc11 Cleanup

Generated: 2026-06-21

Scope: `rc11_product_code_systematic_cleanup_execution_gate`.

## Product Baseline

Current product baseline remains:

- `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- `docs/product/PRD_V3_2026-06-19.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`

## Flutter App Structure

```text
web/workbench/flutter_app/lib/
  main.dart
  app/
    desktop_status_bar.dart
    product_top_bar.dart
    workbench_pages.dart
    workbench_shell.dart
    workbench_sidebar.dart
  domain/
    config_profile/
      project_config_profile.dart
  rc6_runtime/
    project_config_profile.dart        # compatibility export
    rc6_runtime_controller.dart        # conditional export facade
    rc6_runtime_controller_io.dart     # runtime facade / legacy implementation body
    rc6_runtime_controller_stub.dart
  features/
    agent/
    artifacts/
    audit/
    dashboard/
    document_generation/
    document_library/
    import_parsing/
    knowledge_base/
    retrieval/
    settings/
    skill/
    workbook/
  shared/
  contracts/
  core_bridge/
  core_actions/
  backend_evidence/
  skill_factory/
  workbench/
```

## Public Runtime Facade

The public runtime import remains:

```dart
import 'package:heitang_workbench/rc6_runtime/rc6_runtime_controller.dart';
```

`rc6_runtime_controller.dart` still conditionally exports the IO/stub controller and the profile compatibility shim. No public runtime method was renamed.

## Domain Model Extraction

`ProjectConfigProfile` now lives at:

```text
lib/domain/config_profile/project_config_profile.dart
```

Compatibility path retained:

```text
lib/rc6_runtime/project_config_profile.dart
```

The compatibility file exports the new domain model so existing imports continue to work.

## App Page Registry Extraction

The product page registry and `WorkbenchPage` model moved from `main.dart` into:

```text
lib/app/workbench_pages.dart
```

It remains a `part of '../main.dart'` file for this rc11 pass. This reduces `main.dart` responsibility without changing imports, page order, keys, or UI behavior.

## Feature Page Status

Feature pages are still part files of `main.dart` and should be migrated in later small batches:

- `features/artifacts/artifact_center_product_workflow.dart`
- `features/workbook/workbook_product_workflow.dart`
- `features/document_library/document_library_product_workflow.dart`
- `features/import_parsing/import_product_workflow.dart`
- `features/retrieval/retrieval_verification_product_workflow.dart`
- `features/audit/audit_center_product_workflow.dart`
- `features/knowledge_base/knowledge_base_product_workflow.dart`
- `features/document_generation/document_generation_product_workflow.dart`
- `features/skill/skill_builder_product_workflow.dart`
- `features/settings/settings_product_workflow.dart`
- `features/agent/agent_product_workflow.dart`
- `features/dashboard/dashboard_product_workflow.dart`

## Runtime Cleanup Status

`rc6_runtime_controller_io.dart` remains the compatibility facade and legacy implementation body. It was not split in this pass to avoid changing artifact paths or runtime semantics while stabilizing tests.

Next safe extraction target:

```text
runtime/services/config_profile_service.dart
runtime/repositories/runtime_config_repository.dart
```

## Test Stabilization

UI tests were updated to use stable keys/current product semantics instead of brittle duplicate text matches:

- Document library source tab: `document-library-tab-1`
- Document generation surface: `document-generation-tasks`
- Stage3 provider tests: target-provider evidence assertions instead of exact global ready-count locks.

## Behavior Boundary

No new feature was added. No UI page was added or removed. No artifact path/schema was intentionally changed. OKF remains standard knowledge package candidate layer. A2A remains under Agent workspace.

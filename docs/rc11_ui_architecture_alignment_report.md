# rc11 UI Architecture Alignment Report

Status: implemented for the rc11 gate.

Product baseline:
- `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- `docs/product/PRD_V3_2026-06-19.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`

Scope:
- UI architecture and page responsibility alignment only.
- No runtime main logic changes.
- No stable tag or release creation.

Alignment changes:
- Kept the top-level navigation in the v3 product chain: Home / Workbook, Document Library, Knowledge Base, Retrieval & Verification, Document Generation, Skill Factory, Agent Workbench, Artifact Center, Governance & Audit, Settings.
- Kept A2A inside Agent Workbench rather than adding it as a global top-level page.
- Re-aligned Agent Workbench tabs to: Agent Overview, Single Agent, Multi-Agent / A2A, Run Audit.
- Added a user-facing Agent Run Audit tab that summarizes dialogue, export, A2A, permission, failure, and recovery status without exposing raw artifact paths, Core actions, Campaign history, or backend matrix language.
- Replaced visible tutorial-style wording in Home, Workbook, Skill localization, and Agent audit surfaces with status, artifact, entrypoint, and audit-state language.
- Kept ordinary pages free of numbered user-path tables, path guidance panels, and action-instruction walls.
- Kept Settings focused on workspace, Provider/model, Redis/vector DB, exporters, network authorization, and security.

Validation focus:
- Ordinary UI must not expose Core CLI, Core action panels, operation gates, capability matrices, task job centers, Campaign history, rc history, or raw developer artifacts.
- A2A must remain part of Agent Workbench.
- Run audit must exist as an Agent Workbench sub-page, not as a top-level page.
- Ordinary UI should express state and available entrypoints directly instead of explaining a confused path with tutorial text.

Validation run:
- `flutter analyze`: passed.
- `flutter test test\widget_test.dart`: passed.
- `flutter test test\campaign_4_workbench_test.dart`: passed.
- `git diff --check -- . ':!docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md'`: passed with Windows line-ending warnings only.
- Added-line no-secret scan: passed.
- Added-line overclaim scan: passed.
- Visible-copy scan for tutorial/path wording: passed; only this report's scan-note line matched.

Scan notes:
- Visible-copy scan for `下一步行动`, `Next Actions`, `用户路径`, `User path`, numbered Skill localization steps, and `失败与恢复` has no product-surface hits; remaining hits are negative widget-test assertions.
- Broad internal scans still contain implementation identifiers such as Core bridge types, sample Campaign constants, and disabled-boundary sanitizers. These are implementation/test fixtures; ordinary widget tests assert the strings are not visible in the product UI.

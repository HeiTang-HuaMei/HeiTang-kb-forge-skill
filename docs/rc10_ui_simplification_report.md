# rc10 UI Simplification Report

Status: implemented for current gate.

Scope:
- UI surface only.
- No runtime main logic changes.
- No release or stable tag.

Changes:
- Added a shared more-actions menu for low-frequency, destructive, or operational actions.
- Removed ordinary UI exposure of path-copy actions from Agent and Artifact Center.
- Removed Agent run-audit as a normal Agent tab; audit remains available through audit/artifact surfaces.
- Reduced Agent chat actions to run, view dialogue, and export; history/export preview/clear moved to more menu.
- Kept A2A under Agent Workbench and removed A2A audit-preview buttons from the main collaboration view.
- Changed Artifact Center from raw file inventory to user-level artifact categories.
- Removed manifest/jsonl-style names from Home and Knowledge Base default surfaces.
- Simplified Import & Parsing by removing step-grid and parser settings panels from the default path.
- Made Document Library build-KB the primary user action; reparse/delete/package operations moved to more menu.
- Made Knowledge Base build/update the primary action; copy/merge/split/rebuild/version actions moved to more menu.
- Made Document Generation primary action explicit as Markdown generation; history/export operations moved to more menu.
- Reduced Skill validation/export button wall; copy/fuse/bind/preview/delete moved to more menu.
- Simplified Settings provider capability display to user-facing capability, status, and current behavior.
- Replaced page-level Skill localization preview path construction with runtime-owned artifact paths.

Acceptance focus:
- Main chain remains: Document Library -> Knowledge Base -> Retrieval -> Document Generation -> Skill -> Agent -> A2A.
- Ordinary UI no longer relies on tutorial text to explain routing.
- Low-frequency and developer-oriented actions are no longer flat, first-class buttons.
- Unconfigured advanced outputs remain disabled or shown as needing configuration.

Validation:
- `flutter analyze`: passed.
- `flutter test test\widget_test.dart`: passed.
- `flutter test test\campaign_4_workbench_test.dart`: passed.
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "rc10 importing another file appends instead of replacing library state"`: passed.
- `git diff --check`: passed with Windows line-ending warnings only.

Scan notes:
- Ordinary UI tests assert that `manifest`, `jsonl`, `Campaign`, `disabled_boundary`, and raw Agent artifact filenames are not visible.
- Remaining text-scan hits for `Campaign`, `disabled_boundary`, and `release_bundle_manifest.json` are internal fixture/status constants or sanitizing logic, not normal product-surface copy.

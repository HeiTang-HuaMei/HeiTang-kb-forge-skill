# UI Responsive Layout Repair Report

Status: `ui_responsive_layout_repair_completed_needs_owner_review`

## Scope

Mode: Standard Build / UI Layout Repair

This repair targets the desktop Home page layout only. It does not change Core, Runtime, route structure, primary navigation, or real button actions.

## Fixed Width / Height Findings

- Home content was constrained by `_FigmaPageCanvas` to `_DesktopGrid.figmaContentWidth` / `_DesktopGrid.figmaContentHeight`, which made maximized windows look like a fixed small canvas.
- Home rows used fixed-height and fixed-width layout blocks through `_FigmaFixedRow`.
- Hero CTA buttons used fixed outer widths, which made Chinese labels vulnerable to clipping.
- The default isolation notice was wrapped in a fixed-height container while its own vertical padding exceeded the available height.
- The Hero asset glyph was a small fixed node graphic and did not clearly separate the three stages by color.
- Local card scroll regions inherited the page footer safe area, which visually squeezed dashboard card lists.

## Repair Summary

- Home now opts into a wider responsive canvas with bounded max widths for standard and wide desktop windows.
- Home uses breakpoint-driven rows:
  - compact desktop: stacked modules
  - standard desktop: two-column primary row and adaptive secondary row
  - wide desktop: fuller two-column / three-column layout
- Hero height and content rows now scale by breakpoint instead of staying locked to the former static layout.
- CTA buttons use content-aware minimum widths in the Hero and no longer rely on fixed 150 / 124 widths.
- The default isolation notice no longer has a fixed outer height; it supports one-line desktop display, two-line compact display, ellipsis, and tooltip.
- Hero right-side visual now presents three distinct stages: `资料 -> 知识库 -> 成果`, using indigo, teal, and amber.
- Dashboard local scroll boxes use a small bottom padding so card lists do not appear clipped by page-level footer spacing.

## Screenshots

- Home 1440x900: `web/workbench/flutter_app/output/ui_responsive_layout_repair/home_layout/home_layout_20260624_002848/screenshots/home_1440x900.png`
- Home 1920x1080: `web/workbench/flutter_app/output/ui_responsive_layout_repair/home_layout/home_layout_20260624_002848/screenshots/home_1920x1080.png`
- Home maximized / wide: `web/workbench/flutter_app/output/ui_responsive_layout_repair/home_layout/home_layout_20260624_002848/screenshots/home_maximized_wide.png`
- CTA local region: `web/workbench/flutter_app/output/ui_responsive_layout_repair/home_layout/home_layout_20260624_002848/regions/cta_organize_and_flow.png`
- Isolation notice region: `web/workbench/flutter_app/output/ui_responsive_layout_repair/home_layout/home_layout_20260624_002848/regions/isolation_notice.png`
- Hero asset glyph region: `web/workbench/flutter_app/output/ui_responsive_layout_repair/home_layout/home_layout_20260624_002848/regions/hero_knowledge_asset_glyph.png`

## Validation

- `dart format web/workbench/flutter_app/lib/features/dashboard/dashboard_product_workflow.dart web/workbench/flutter_app/lib/shared/workbench_layout.dart web/workbench/flutter_app/lib/shared/product_components.dart`
  - Result: passed
- `flutter analyze`
  - Result: passed
  - Log: `web/workbench/flutter_app/output/logs/ui_responsive_layout_flutter_analyze.log`
- `flutter build windows`
  - Result: passed
  - Log: `web/workbench/flutter_app/output/logs/ui_responsive_layout_flutter_build_windows.log`
- `powershell -ExecutionPolicy Bypass -File tool/windows_native_product_verifier/run_home_layout_matrix.ps1`
  - Result: passed
  - Log: `web/workbench/flutter_app/output/logs/ui_responsive_layout_home_layout_matrix.log`
- `git diff --check`
  - Result: passed with CRLF working-copy warnings
  - Log: `web/workbench/flutter_app/output/logs/ui_responsive_layout_git_diff_check.log`
- `flutter test --concurrency=1`
  - Result: `test_harness_infrastructure_blocked`
  - Reason: WebSocket 502 while loading Flutter test suites
  - Log: `web/workbench/flutter_app/output/logs/ui_responsive_layout_flutter_test.log`

## Remaining Risk

- Owner visual review is still required for final acceptance.
- `flutter test --concurrency=1` remains blocked by the existing Flutter test harness WebSocket 502 issue.

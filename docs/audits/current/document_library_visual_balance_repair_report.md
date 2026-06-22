# Document Library Visual Balance Repair Report

Generated: 2026-06-22

Gate: `document_library_visual_balance_repair_gate`

Status: `document_library_visual_balance_repaired`

Previous state:

```text
figma_v02_pixel_alignment_candidate
```

Next allowed gate:

```text
ui_acceptance_gate
```

Not claimed:

```text
ui_restructure_accepted
stable
release
packaging_ready
```

## 1. Owner Visual Issues

Owner review accepted the overall Figma V0.2 direction, but rejected the `03 文档库` page balance as not tidy enough:

- The top library foundation banner was acceptable, but the content below did not form a balanced grid.
- The left material intake area was visually heavy.
- The right queue/progress area was dense and did not align cleanly with the left card.
- The import history area felt like a detached lower attachment.
- The page did not yet read as a stable Figma V0.2 two-column workspace.

## 2. Before / After Layout Difference

Before this repair, the document library page still carried a mixed functional layout. The page had useful actions, but the visual weight was uneven and the lower history section did not align strongly with the main grid.

After this repair, the default document-library tab uses a stable three-part structure:

```text
Top: document-library Hero banner
Middle: equal-width two-column workspace
Bottom: full-width import history / recent records card
```

The middle area was changed to:

```text
Left: 添加与整理资料
Right: 资料队列与进度
```

Both columns now use the same width, shared card language, aligned top edges, and a unified height. The right queue content was also given enough vertical room so queue rows are not clipped in the 1440x900 screenshot.

## 3. Left / Right Symmetry Handling

Left card, `添加与整理资料`:

- Two compact stat cards: `本地资料`, `外部链接`.
- Four direct user actions: `添加文件`, `添加文件夹`, `添加链接`, `整理资料`.
- Compact progress indicator.
- Bottom status banner using ordinary-user wording.

Right card, `资料队列与进度`:

- Three compact status cards: `已整理`, `待整理`, `需要设置`.
- Four controlled queue rows: `来源文档`, `资料整理`, `图片文字识别`, `网页导入`.
- Rows use ordinary status labels and avoid raw runtime terms.
- Card height matches the left card so the two-column area reads as one grid.

Bottom card, `导入历史`:

- Full-width horizontal layout aligned to the two-column grid above.
- Includes latest import, source, status, downstream usage, and clear-record action.

## 4. Function Binding Unchanged

This repair did not change runtime semantics, backend capability claims, artifact paths, or the UI binding matrix.

Preserved user-visible bindings:

| User action | Runtime / effect |
| --- | --- |
| `添加文件` | `pickAndImportFile` |
| `添加文件夹` | `pickAndImportFolder` |
| `添加链接` | `importWebLink` after URL input |
| `整理资料` | `parseAndChunkSources` when imported sources exist |
| `清空记录` | Existing import deletion confirmation and runtime cleanup path |
| `待整理 / 已整理 / 需要设置` | Existing runtime/config state mapping |

The page continues to show unconfigured or local-only abilities with ordinary labels such as:

```text
需要设置
本地模式
本地资料可用
需要先添加资料
```

No unconfigured capability was changed into a false available state.

## 5. Screenshot Evidence

Screenshots were captured from the real `flutter build web` output served locally at 1440x900.

Output directory:

```text
web/workbench/flutter_app/output/playwright/document_library_visual_balance/
```

Files:

| Evidence | Path |
| --- | --- |
| Document library screenshot | `web/workbench/flutter_app/output/playwright/document_library_visual_balance/03_document_library.png` |
| Contact sheet | `web/workbench/flutter_app/output/playwright/document_library_visual_balance/document_library_visual_balance_contact_sheet.png` |
| Screenshot manifest | `web/workbench/flutter_app/output/playwright/document_library_visual_balance/screenshot_manifest.json` |

## 6. Test Results

Commands were run from:

```text
web/workbench/flutter_app
```

For Flutter tests, local loopback proxy bypass was set:

```text
NO_PROXY=127.0.0.1,localhost
no_proxy=127.0.0.1,localhost
```

| Command | Result | Log |
| --- | --- | --- |
| `dart format lib\features\import_parsing\import_product_workflow.dart` | Passed | `web/workbench/flutter_app/format_document_library_visual_balance_final2.log` |
| `flutter analyze` | Passed | `web/workbench/flutter_app/analyze_document_library_visual_balance_final3.log` |
| `flutter test test\rc3_ui_usability_repair_test.dart --plain-name "business pages expose natural capability status only" --concurrency=1` | Passed | `web/workbench/flutter_app/test_document_library_visual_balance_rc3_status2.log` |
| `flutter test --concurrency=1` | Passed | `web/workbench/flutter_app/test_document_library_visual_balance_final4.log` |
| `flutter build web` | Passed | `web/workbench/flutter_app/build_web_document_library_visual_balance2.log` |
| `git diff --check` | Passed | `git_diff_check_document_library_visual_balance.log` |

Note: one earlier `flutter test --concurrency=1` attempt failed before suites loaded because local WebSocket connections to `127.0.0.1` were intercepted with HTTP 502. Re-running with `NO_PROXY=127.0.0.1,localhost` passed.

## 7. Gate Decision

The document-library visual balance repair is complete.

Current status:

```text
document_library_visual_balance_repaired
```

The project may re-enter:

```text
ui_acceptance_gate
```

It must not proceed directly to:

```text
full_product_regression_before_packaging_gate
pre_exe_packaging_cleanup_gate
windows_exe_packaging_gate
tag
release
GitHub Release
```

# Figma V0.2 Pixel Alignment Report

Generated: 2026-06-22

Gate: `figma_v02_pixel_alignment_gate`

Status: `figma_v02_pixel_alignment_candidate`

Current product state:

```text
ui_backend_binding_completed
figma_pixel_alignment_candidate
```

Not claimed:

```text
ui_restructure_accepted
stable
release
packaging_ready
```

## 1. Why The Previous UI Was Not A Figma Visual Landing

The previous Flutter implementation had real backend/runtime binding, but Owner review rejected it as a visual acceptance result because the screenshots still read as low-fidelity functional back-office pages:

- Most pages were still dominated by table/list surfaces.
- Warm-gray workspace background, black/gold side navigation, card depth, and low-saturation status chips were not consistently visible.
- Several pages reused old page skeletons instead of the Figma V0.2 page structure.
- Hero areas, metric cards, workflow cards, and right-side detail cards did not carry the page hierarchy.
- Settings and artifact/report pages visually competed with user task pages instead of using normal-user product structure.

This gate therefore focused on visual/page-structure alignment only. Runtime semantics, artifact paths, config gates, and backend method bindings were preserved.

## 2. Page Structure Replacement Summary

| Figma frame | Flutter page | Pixel-alignment result |
| --- | --- | --- |
| `01 首页 Visual V0.2` | Home / dashboard | Rebuilt as Hero + workspace asset overview + five-step workflow + three lower cards + workspace isolation notice. |
| `02 工作区 Visual V0.2` | Workbook | Rebuilt as workspace Hero + isolation boundary card + two-column assets/boundary section + bottom continue actions. |
| `03 文档库 Visual V0.2` | Document library | Rebuilt with warm-gold library foundation card, category chips, source table card, document-library status/progress cards. |
| `04 知识库 Visual V0.2` | Knowledge base | Rebuilt as left KB list and right KB detail/build card with source/action boundaries. |
| `05 检索与验证 Visual V0.2` | Test knowledge base | Rebuilt as query console, verification metric cards, evidence table, and external-checking gate card. |
| `06 文档生成 Visual V0.2` | Document generation | Rebuilt as generation task cards, central document editor/preview, export format cards, and validation/export section. |
| `07 Skill 工厂 Visual V0.2` | Skill factory | Rebuilt around two large top cards for KB-generated Skill and imported template Skill, with config/preview areas below. |
| `08 Agent 工作台 Visual V0.2` | Assistant workspace | Rebuilt with metric cards, assistant list/workspace card, run state card, and memory boundary wording. |
| `09 产物中心 Visual V0.2` | Artifact center | Rebuilt with output statistic cards, artifact list card, artifact detail/export card. |
| `10 设置 Visual V0.2` | Settings | Rebuilt with settings category chips, six setting cards, workspace/storage details, and advanced/service detail areas below. |

## 3. Figma Frame To Flutter Evidence

| Page | Screenshot | Figma-facing visual check | Result |
| --- | --- | --- | --- |
| 首页 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/01_home.png` | Hero, asset overview, workflow cards, lower task/result cards. | Pass |
| 工作区 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/02_workbook.png` | Workspace Hero, isolation card, asset/boundary two-column layout. | Pass |
| 文档库 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/03_document_library.png` | Warm emphasis card, chips, source/status cards. | Pass |
| 知识库 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/04_knowledge_base.png` | KB list/detail structure and gated actions. | Pass |
| 测试知识库 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/05_retrieval_verification.png` | Query console, metrics, evidence table, external gate. | Pass |
| 文档生成 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/06_document_generation.png` | Generation task, editor preview, export format cards. | Pass |
| 技能生成 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/07_skill_factory.png` | Two large Skill entry cards and lower config/preview structure. | Pass |
| 我的助手 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/08_agent_workspace.png` | Metrics, assistant workspace, run/memory boundary cards. | Pass |
| 成果中心 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/09_artifact_center.png` | Output stats, artifact list, artifact detail/export. | Pass |
| 设置 | `web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/10_settings.png` | Category chips, six setting cards, advanced detail area. | Pass |

Contact sheet:

```text
web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/figma_v02_pixel_alignment_contact_sheet.png
```

## 4. Visual Tokens And Component Alignment

Implemented or applied through shared shell/layout/component code:

- Warm-gray background: `#EFE9DF`
- Main panel: `#F6F0E7`
- Surface cards: `#FFFDF8`
- Soft surface: `#F8F2E9`
- Border: `#E3D8C8`
- Primary text: `#151311`
- Secondary text: `#71695E`
- Sidebar: `#111518`
- Gold accent: `#B98542`
- Gold soft: `#F5E4C7`
- Low-saturation sage/blue/plum/red status families.
- Card radii in the 18/20/24px range.
- Main container radius around 28px.
- Button radius around 12px.
- Pill chips with full radius.
- Light card shadows instead of flat table surfaces.

Component alignment areas:

- App shell
- Sidebar
- Topbar/search
- Primary/secondary/ghost actions
- Active/status chips
- Highlight cards
- Base cards
- Stat cards
- Table cards
- Section headers
- Empty/config-gate states

## 5. Runtime Binding Preserved

This gate did not change backend runtime semantics.

Preserved:

- Existing `rc6_runtime_controller` methods and IO/stub boundaries.
- Page-to-runtime binding established by the previous UI binding gate.
- Config-gated availability for external search, model/exporter services, memory/cache services, and Office-style export.
- Workspace isolation wording and existing runtime tests.
- Agent and multi-agent memory boundary wording and existing runtime tests.
- Artifact paths and local output behavior.

Not converted into false claims:

```text
reference_only -> integrated
runtime_loaded=false -> true
template asset -> Provider runtime
unconfigured service -> available
test_only route -> release provider
```

## 6. Fixes Made During Pixel Gate

During verification, `widget_test.dart` still caught fixed-height visual overflow. Minimal layout fixes were applied:

- Compact `FigmaHighlightCard` rendering for 82/88px Hero cards.
- Local scroll containment for the document-generation visual area.
- Screenshot script settings-page coordinate corrected so `10_settings.png` captures the actual settings page.
- Contact sheet regenerated from real 1440x900 screenshots.

No runtime action, artifact path, or config gate behavior was changed.

## 7. Validation Results

Commands were run from:

```text
web/workbench/flutter_app
```

Proxy variables were cleared for Flutter test commands:

```text
NO_PROXY=127.0.0.1,localhost,::1
HTTP_PROXY=
HTTPS_PROXY=
```

| Command | Result | Log |
| --- | --- | --- |
| `flutter analyze` | Passed, no issues found | `web/workbench/flutter_app/analyze_figma_v02_pixel_alignment.log` |
| `flutter test --concurrency=1` | Passed, all tests passed | `web/workbench/flutter_app/test_figma_v02_pixel_alignment.log` |
| `flutter build web` | Passed | `web/workbench/flutter_app/build_web_figma_v02_pixel_alignment.log` |
| `git diff --check` | Passed; CRLF warnings only | `git_diff_check_figma_v02_pixel_alignment.log` |

Additional targeted checks:

| Command | Result | Log |
| --- | --- | --- |
| `flutter test test\widget_test.dart --plain-name "keeps English and dark mode controls usable" --concurrency=1` | Passed | `web/workbench/flutter_app/test_widget_english_dark_pixel_alignment_verify.log` |
| `flutter test test\widget_test.dart --plain-name "renders dedicated p1 pages without Flutter exceptions" --concurrency=1` | Failed before fix, passed after fix | `web/workbench/flutter_app/test_widget_p1_pixel_alignment_verify_after_fix.log` |

Build notes:

- Flutter emitted the existing Wasm dry-run informational warning.
- Flutter emitted the existing MaterialIcons/CupertinoIcons font warning.
- Neither warning blocked `flutter build web`.

## 8. Screenshot Capture

Screenshots were captured from a real `flutter build web` output served locally:

```text
http://127.0.0.1:8788
viewport: 1440x900
```

Capture command:

```text
NODE_PATH=C:\Users\Administrator\AppData\Local\Temp\codex-playwright-capture\node_modules node output\playwright\figma_v02_pixel_alignment\capture_figma_v02_pixel_alignment.js
```

Capture result:

```text
web/workbench/flutter_app/screenshot_figma_v02_pixel_alignment_final2.log
```

The capture script uses sidebar coordinates and stores:

```text
web/workbench/flutter_app/output/playwright/figma_v02_pixel_alignment/screenshot_manifest.json
```

## 9. Difference And Risk List

| Item | Status |
| --- | --- |
| First-level layout matches Figma V0.2 direction | Pass |
| Warm-gray non-white background | Pass |
| Black/gold sidebar | Pass |
| Unified topbar/search area | Pass |
| Card depth/radius/shadow system | Pass |
| Tables no longer dominate the whole page | Pass |
| Unconfigured capabilities remain gated | Pass |
| Runtime binding preserved | Pass |
| Owner acceptance | Pending Owner screenshot review |

Residual risks:

- This is screenshot-based visual candidate evidence, not Owner Acceptance.
- Exact Figma node-by-node numeric parity was not mechanically diffed because Figma node metadata was not imported into the repo.
- Browser screenshots validate web rendering; EXE/native smoke remains a later gate.

## 10. Gate Decision

Allowed next gate:

```text
ui_acceptance_gate
```

Current completion status:

```text
figma_v02_pixel_alignment_candidate
```

Still not allowed:

```text
full_product_regression_before_packaging_gate
pre_exe_packaging_cleanup_gate
windows_exe_packaging_gate
tag
release
GitHub Release
```

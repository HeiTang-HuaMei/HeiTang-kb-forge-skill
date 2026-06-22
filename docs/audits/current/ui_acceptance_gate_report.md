# UI Acceptance Gate Report

Generated: 2026-06-22

Gate: `ui_acceptance_gate`

Status: `ui_restructure_accepted`

Owner acceptance: `accepted_by_owner_direction_2026-06-22`

Stable tag: `not_created`

GitHub Release: `not_created`

## 1. Scope

This gate verifies and closes the current Flutter UI candidate after the Figma V0.2 prototype-to-runtime binding work.

The purpose is to close the UI restructure phase and move the project into full regression, packaging, and release preparation. This is not a stable/release declaration.

This gate covered:

- Real Flutter Web build and browser rendering.
- Screenshot capture for 10 product pages.
- Page navigation/title verification.
- Ordinary-user wording and technical-term exposure review.
- Main action/config-gated state review.
- Runtime binding evidence from existing widget/runtime tests.

This gate did not claim:

- Stable readiness.
- GitHub Release readiness.
- EXE full-chain acceptance.
- Live external Redis/Qdrant/API provider success in the browser session.

## 2. Real Run Setup

| Item | Result |
| --- | --- |
| Repo | `kb-forge-skill-ui` |
| Branch | `feature/workbench-ui-prototype` |
| Head before this gate | `b26a024 Add GitHub repository governance controls` |
| Build command | `flutter build web` |
| Static server | `python -m http.server 53123 --bind 127.0.0.1 --directory build/web` |
| Browser tool | Playwright CLI |
| URL | `http://127.0.0.1:53123/` |
| Console issues | Only `favicon.ico` 404 observed; no Flutter app crash observed |

Note: `flutter run -d web-server` was blocked by the current `web/index.html` relative base href. To avoid changing source for the run environment, this gate used a real `flutter build web` output and served `build/web`.

## 3. Screenshot Evidence

Screenshots are stored under:

```text
web/workbench/flutter_app/output/playwright/
```

| Page | Title Verified | Screenshot |
| --- | --- | --- |
| 首页 | `首页 - HeiTang Knowledge Workbench` | `01_home.png` |
| 工作区 | `工作区 - HeiTang Knowledge Workbench` | `02_workbook.png` |
| 文档库 | `文档库 - HeiTang Knowledge Workbench` | `03_document_library.png` |
| 知识库 | `知识库 - HeiTang Knowledge Workbench` | `04_knowledge_base.png` |
| 测试知识库 | `测试知识库 - HeiTang Knowledge Workbench` | `05_retrieval_verification.png` |
| 文档生成 | `文档生成 - HeiTang Knowledge Workbench` | `06_document_generation.png` |
| 技能生成 | `技能生成 - HeiTang Knowledge Workbench` | `07_skill_factory.png` |
| 我的助手 | `我的助手 - HeiTang Knowledge Workbench` | `08_agent_workspace.png` |
| 成果中心 | `成果中心 - HeiTang Knowledge Workbench` | `09_artifact_center.png` |
| 设置 | `设置 - HeiTang Knowledge Workbench` | `10_settings.png` |
| Contact sheet | All 10 pages | `ui_acceptance_contact_sheet.png` |

## 4. Visual Acceptance Findings

| Check | Result |
| --- | --- |
| 10 pages render | Passed |
| Sidebar unified | Passed |
| Logo fixed in sidebar | Passed |
| Topbar consistent | Passed |
| Primary navigation is user-task based | Passed |
| No first-level OKF/A2A/Provider/Gateway/ModelRoute/Gate/Campaign/Stage page | Passed |
| Main flow uses ordinary labels | Passed |
| Candidate visual density | Acceptable for Owner review |
| Owner final visual approval | Accepted for moving out of UI restructure phase |

## 5. Issues Found And Fixed During Gate

The first real screenshot pass found ordinary UI leakage that should not pass acceptance:

| Finding | Fix |
| --- | --- |
| `测试知识库` showed raw `desktop_runtime_required` in the result table | Mapped internal runtime tokens to user-facing status: `暂不可用，需要桌面运行环境` |
| Retrieval scoring text used `chunk 分数` | Changed visible Chinese copy to `片段匹配` |
| Knowledge Base page used `LLM 增强` in Chinese UI | Changed visible Chinese copy to `模型服务增强` |
| Knowledge Base source selector showed `Document ID` in Chinese UI | Changed visible Chinese copy to `资料编号` |
| Assistant page showed `./workbench_runs/agent...` path before an assistant exists | Changed Chinese subtitle to `当前工作区` |
| Settings page showed `向量索引目录` and English asset types in Chinese UI | Changed to `检索数据目录`, `文档`, and `知识库` |
| Chinese copy used `secret` | Changed visible Chinese copy to `密钥` / `明文密钥` |

After these fixes, the page screenshots were rebuilt and recaptured.

## 6. Functional Binding Acceptance

This gate relies on the binding matrix plus runtime/widget test evidence rather than browser-clicking file pickers or external service connections.

Reference matrix:

```text
docs/audits/current/ui_prototype_backend_binding_matrix.md
```

| Area | Evidence | Result |
| --- | --- | --- |
| 首页 next action routing | Screenshot + widget tests | Passed |
| 工作区 lifecycle/isolation | `rc6_runtime_truth_blocker_repair_test.dart` | Passed |
| 文档库 import/organize binding | Matrix + widget/runtime tests | Passed |
| 知识库 build/test/version operations | Matrix + runtime tests | Passed |
| 测试知识库 retrieval/save validation | Matrix + runtime tests | Passed |
| 文档生成 Markdown and export gating | Matrix + widget/runtime tests | Passed |
| 技能生成/import/template/bind operations | Matrix + widget/runtime tests | Passed |
| 我的助手 single/multi assistant actions | Matrix + runtime tests | Passed |
| 成果中心 preview/export/delete | Matrix + runtime tests | Passed |
| 设置 model/export/storage/memory/network profile config | Matrix + runtime tests | Passed |

Browser limitation: local file picker actions and external provider connections were not manually executed in the Playwright web session. They remain covered by runtime/widget tests and require EXE/Owner smoke for final acceptance.

## 7. State And Empty/Failure Handling

| State | Evidence | Result |
| --- | --- | --- |
| Empty materials | 首页/文档库 screenshots show waiting/import states | Passed |
| Need KB before document generation | 文档生成 screenshot shows `需要知识库` and disabled generate action | Passed |
| Need config for Office export | 文档生成 screenshot shows `需要设置导出工具` | Passed |
| External checking not configured | 测试知识库 screenshot shows `需要配置或授权` / local-only boundary | Passed |
| Local mode without external memory/search | 设置/知识库/助手 screenshots show local mode and non-success status | Passed |
| Raw runtime token hidden from ordinary UI | Retested after fix; `desktop_runtime_required` no longer visible | Passed |
| Secret not shown in plaintext | Widget/runtime tests and visible copy review | Passed |
| Owner empty/failure state visual approval | Accepted for moving out of UI restructure phase |

## 8. Technical Terms Review

Ordinary navigation and visible primary task flow do not expose:

```text
Provider
Gateway
ModelRoute
Gate
Campaign
Stage
Capability Matrix
Operation Gate
Task Job Center
OKF as first-level page
A2A as first-level page
disabled_boundary
desktop_runtime_required
runtime_ready
```

Allowed remaining occurrences are code identifiers, tests, fixtures, advanced settings internals, or usage/audit details.

## 9. Validation

Commands ran from `web/workbench/flutter_app` unless noted.

| Command | Result | Log |
| --- | --- | --- |
| `flutter analyze` | Passed | `output/playwright/analyze_ui_acceptance.log` |
| `flutter test test\widget_test.dart --concurrency=1` | Passed, 26 tests | `output/playwright/test_widget_ui_acceptance.log` |
| `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1` | Passed, 53 tests, 1 skipped | `output/playwright/test_rc6_ui_acceptance.log` |
| `flutter build web` | Passed, warnings only | `output/playwright/flutter_build_web_ui_acceptance.log` |
| `git diff --check` | Passed, CRLF warnings only | `output/playwright/git_diff_check_ui_acceptance.log` |

Build warnings observed:

- Flutter Web wasm dry-run informational warning.
- Cupertino icon font warning already present in build output context.

These warnings did not block build output generation.

## 10. Changed Files In This Gate

This gate added the acceptance report and made minimal UI wording fixes after real screenshot inspection.

```text
docs/audits/current/ui_acceptance_gate_report.md
web/workbench/flutter_app/lib/shared/product_components.dart
web/workbench/flutter_app/lib/features/retrieval/retrieval_verification_product_workflow.dart
web/workbench/flutter_app/lib/features/knowledge_base/knowledge_base_product_workflow.dart
web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart
web/workbench/flutter_app/lib/features/settings/settings_product_workflow.dart
```

Generated local verification artifacts:

```text
web/workbench/flutter_app/output/playwright/
```

These output files are local evidence only and should not be treated as release artifacts.

## 11. Remaining Risks

| Risk | Status |
| --- | --- |
| Owner visual acceptance | Accepted for UI phase closure |
| EXE screenshot and full-chain functional smoke | Pending |
| Real local file picker interaction in packaged EXE | Pending |
| Live external service/provider connection smoke | Pending, must remain config-gated until configured |
| Pixel-perfect parity with Figma | Not claimed |
| Stable tag / GitHub Release | Not performed |

## 12. Phase Closure

Owner direction after this report:

- UI restructure is considered formally complete.
- Do not continue broad UI redesign.
- Future UI work is limited to bug fixes, state fixes, copy fixes, failure prompts, and compatibility fixes found during regression or EXE acceptance.
- The project now enters full regression, packaging, and release preparation.

Current state:

```text
ui_restructure_accepted
```

Recommended next gates:

```text
full_product_regression_before_packaging_gate
pre_exe_packaging_cleanup_gate
windows_exe_packaging_gate
windows_exe_smoke_acceptance_gate
release_candidate_gate
owner_final_acceptance_gate
stable_tag_and_github_release_gate
```

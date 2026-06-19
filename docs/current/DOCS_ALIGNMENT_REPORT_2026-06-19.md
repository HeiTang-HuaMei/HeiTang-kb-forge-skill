# Docs Alignment Report 2026-06-19

Gate: `rc10_docs_baseline_alignment_gate`

## Scope

- Only `docs/` files were changed.
- No Core code, UI code, runtime code, tests, tag, release, or feature behavior was changed.
- Existing unrelated dirty files were intentionally skipped.

## Baseline

The current product baseline is now fixed to:

- [../product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md](../product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md)
- [../product/PRD_V3_2026-06-19.md](../product/PRD_V3_2026-06-19.md)
- [../product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md](../product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md)

All other documents may only reference, explain, or implement those three files.

## Updated Current Docs

- `docs/current/CURRENT_PRODUCT_BASELINE_2026-06-19.md`
- `docs/项目概览.md`
- `docs/产品定位.md`
- `docs/系统架构.md`
- `docs/知识供应链架构.md`
- `docs/路线图.md`
- `docs/使用指南.md`
- `docs/快速开始.md`
- `docs/Skill与Agent生成说明.md`
- `docs/测试与验收.md`
- `docs/发布流程.md`

These docs now use the unified chain:

```text
文档库 → 知识库 → 索引层 → RAG → 编排层 → 文档/Skill/Agent/A2A
```

## Historical Docs

The following historical areas were not deleted because they remain useful for traceability and existing repository checks:

- `docs/campaigns/`
- `docs/治理/C4_Audits/`
- older governance summaries under `docs/治理/`

They are now covered by history notices:

- `docs/archive/README.md`
- `docs/campaigns/README.md`
- `docs/治理/C4_Audits/README.md`

Historical docs are for traceability only and cannot override the v3 baseline.

## Boundary Checks

- OKF is described only as a Standard Knowledge Package candidate layer.
- No OKF runtime, page, or current user-flow implementation was added.
- External/reference projects must remain `reference_only`, `needs_verification`, or separately verified candidates.
- Release flow now includes the PRD / architecture / acceptance baseline consistency gate.

## Intentionally Skipped

Pre-existing dirty files were not rewritten or reverted:

- `docs/campaigns/campaign_9_windows_exe_packaging/v4.3.0-rc6_Owner_Retest_Checklist_2026-06-17.md`
- `docs/治理/Campaign_6_外部运行时参考队列.md`
- untracked campaign_9 rc6 reports
- `output/`

## Validation

- Focused docs tests: `python -m pytest tests/test_final_docs_structure.py tests/test_final_docs_truthfulness.py tests/test_final_product_architecture_truth_docs.py tests/test_release_checklist_docs.py tests/test_agent_integration_docs.py tests/test_agent_tool_docs.py tests/test_capability_status_docs.py -q` passed, 15 passed.
- Markdown basic scan: staged Markdown links passed, 18 files checked.
- No-secret scan: staged Markdown / JSON files passed, 18 files checked.
- Overclaim scan: only negative or boundary wording remained, such as "不得写成", "不开放", "不新增", and "scan".
- OKF runtime scan: only boundary wording remained; no OKF runtime, page, or current user-flow implementation was added.
- `git diff --cached --check`: passed after trimming whitespace in copied v3 baseline files.
- Full local pytest after CI repair: `python -m pytest -q` passed, 1431 passed and 1 skipped.
- Legacy public-surface tests were narrowed to allow only the three v3 baseline files under `docs/product/`; other legacy product/governance/testing/bridge/roadmap directories remain blocked.

# Docs Alignment Report 2026-06-19

Gate: `rc10_docs_baseline_alignment_gate`

## Scope

- Only `docs/` files were changed.
- No Core code, UI code, Flutter runtime code, tests, tag, release, or feature behavior was changed.
- Existing unrelated dirty files were intentionally skipped.

## Baseline

The current product baseline is fixed to:

- [../product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md](../product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md)
- [../product/PRD_V3_2026-06-19.md](../product/PRD_V3_2026-06-19.md)
- [../product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md](../product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md)

All other documents may only reference, explain, or implement those three files.

## Added Current Docs

- `docs/current/CURRENT_PRODUCT_BASELINE_2026-06-19.md`
- `docs/user/项目概览.md`
- `docs/user/产品定位.md`
- `docs/user/快速开始.md`
- `docs/user/使用指南.md`
- `docs/user/Skill与Agent生成说明.md`
- `docs/architecture/系统架构.md`
- `docs/architecture/知识供应链架构.md`
- `docs/architecture/路线图.md`
- `docs/acceptance/测试与验收.md`
- `docs/acceptance/Owner复验清单.md`
- `docs/governance/登记项目治理.md`
- `docs/governance/外部运行时参考队列.md`
- `docs/governance/发布流程.md`

These docs now use the unified chain:

```text
文档库 → 知识库 → 索引层 → RAG → 编排层 → 文档/Skill/Agent/A2A
```

## Historical Docs

Existing English docs and audit records were not moved because many are referenced by tests and engineering workflows. They are now covered by history notices:

- `docs/archive/README.md`
- `docs/audits/README.md`

Historical docs are for traceability only and cannot override the v3 baseline.

## Boundary Checks

- OKF is described only as a Standard Knowledge Package candidate layer.
- No OKF runtime, page, or current user-flow implementation was added.
- Registered projects must resolve to Provider capability, template asset,
  absorbed architecture reference, rejected reference, or deferred reference
  with a named blocker. Indefinite `reference_only` notes are not a current
  delivery state.
- Release flow now includes the PRD / architecture / acceptance baseline consistency gate.

## Intentionally Skipped

Pre-existing dirty file was not rewritten or reverted:

- `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md`

## Validation

- Focused docs tests: `python -m pytest tests/test_capability_status_docs.py tests/test_release_checklist_docs.py tests/test_skill_first_architecture_docs.py tests/test_desktop_docs.py -q` passed, 6 passed.
- Markdown basic scan: staged Markdown links passed, 20 files checked.
- No-secret scan: staged Markdown / JSON files passed, 20 files checked.
- Overclaim scan: only negative or boundary wording remained, such as "不承诺", "不得写成", "不开放", and "scan".
- OKF runtime scan: only boundary wording remained; no OKF runtime, page, or current user-flow implementation was added.
- `git diff --cached --check`: passed after trimming whitespace in copied v3 baseline files.

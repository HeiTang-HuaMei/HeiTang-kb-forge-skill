# RC12.14 Stage 2 Current-HEAD Revalidation

Date: 2026-06-20

Scope: revalidate Stage 2 v3 full-chain industrial evidence after the rc11.1 UI architecture alignment commit.

## Baseline

- Product architecture: `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- PRD: `docs/product/PRD_V3_2026-06-19.md`
- Feature acceptance matrix: `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`
- Required product chain: document library -> knowledge base -> index layer -> RAG -> orchestration -> document / Skill / Agent / A2A.

## Current Checkpoint

- Current UI HEAD before this report: `13824883748c8edeeab5638ccff68d1092596992`
- Latest Stage 1 tag on current HEAD: `v4.3.0-rc11.1-ui-architecture-alignment`
- Existing Stage 2 final tag `v4.3.0-rc12-v3-full-chain-industrial-product` remains historical evidence on an earlier commit, so this checkpoint revalidates the current branch state instead of relying on the earlier tag alone.

## Current-HEAD Findings

The current branch still carries the Stage 2 runtime and artifact capabilities validated by prior rc12 checkpoints. The only current-head drift found during revalidation was in document-library widget tests that still expected the pre-rc10 flat button model:

- `来源文档` tab selection was ambiguous after UI consolidation.
- `删除当前文档` was expected as a flat visible button even though rc10 moved low-frequency/destructive actions into `更多文档操作`.

The fix preserves the rc10/rc11 UI action model:

- Document Library tabs now have a persistent `document-library-tab-*` key prefix.
- Runtime truth tests now verify that delete is not a flat page button and that `更多文档操作` owns low-frequency document operations.

The OKF product boundary was unchanged.

No runtime main logic, Core execution surface, release publication, broad shell surface, desktop automation surface, or registered-project loading was changed.

## Validation Run

| Check | Result |
| --- | --- |
| `flutter analyze` | pass |
| `flutter test test\campaign_4_workbench_test.dart` | 17 passed |
| `flutter test test\widget_test.dart` | 26 passed |
| `flutter test test\rc6_runtime_truth_blocker_repair_test.dart` | 29 passed |
| `python -m pytest -q` in UI repo | 506 passed, 1 skipped |
| `git diff --check -- . ':!docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md'` | pass, CRLF warnings only |
| Added-line credential scan | pass |
| Added-line overclaim scan | pass |
| Added-line OKF boundary scan | pass |

## Stage 2 Boundary

This checkpoint keeps Stage 2 active until the current-head commit, remote CI, tag, Windows EXE build, and Owner handoff are completed.

Stage 3 remains explicitly out of scope:

- No provider hot-swap external project loading.
- No registered project is presented as loaded.
- Providerized capability enhancement remains a post-Owner-approval stage.

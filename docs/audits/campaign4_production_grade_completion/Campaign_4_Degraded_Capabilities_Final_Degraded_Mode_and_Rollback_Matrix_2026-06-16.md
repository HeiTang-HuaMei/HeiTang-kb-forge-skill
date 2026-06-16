# Campaign 4 Degraded Capabilities Final Degraded Mode and Rollback Matrix

Date: 2026-06-16

Gate: `campaign4_degraded_capabilities_finalization_long_run`

Overall status: `campaign4_remaining_capabilities_production_grade_accepted_ui_bound`

## Degraded / Rollback Matrix

| Capability | Accepted path | Degraded trigger | User-facing behavior | Rollback / disable switch |
|---|---|---|---|---|
| External Source Verification | Approved public source fetch, source trace, evidence map, claim verification, freshness/contradiction evidence, validation | Network opt-in absent, public source unavailable, source trust/preflight failure, provider unavailable, malformed evidence | Show unavailable/degraded/review-required status with source URL, failure reason, retry suggestion, and log id; local KB workflows continue | Withhold network opt-in, remove source URL input, or use local/manual evidence files only |
| OCR / Parser / Chunking | Builtin parser/chunking plus registered `parser-paddleocr` optional OCR runtime | PaddleOCR dependency missing, model cache unavailable, backend failure, low confidence, unsupported file type | Continue builtin parsing/chunking when safe; mark OCR-required files review-required; preserve failure reason and artifact path | Disable/uninstall `parser-paddleocr`, remove local model cache, or choose backend `builtin` |

## Shared Safety Rules

- Secret-like values in UI, fixture, report, or log are a hard stop.
- Mock/offline evidence must not be presented as live public source fetch, live Provider output, or real PaddleOCR runtime output.
- Runtime failure must not be silent; it must produce a user-facing status, failure reason, retry suggestion, and evidence/log path.
- Non-target future capability markers remain disabled, omitted, or boundary-only.

## Remaining Boundaries

- External Source Verification acceptance does not include arbitrary crawling, authenticated browsing, paywall bypass, CAPTCHA bypass, or unrestricted live comparison.
- OCR acceptance does not include Campaign 9 EXE packaging of optional dependencies or model files.
- PaddleOCR layout/table/figure/formula/read-order support is not claimed.
- Agent Runtime, Memory, Collaboration, A2A, and Campaign 5-9 remain outside this gate.

## Stop

This rollback matrix stops at `campaign4_remaining_capabilities_production_grade_accepted_ui_bound`.

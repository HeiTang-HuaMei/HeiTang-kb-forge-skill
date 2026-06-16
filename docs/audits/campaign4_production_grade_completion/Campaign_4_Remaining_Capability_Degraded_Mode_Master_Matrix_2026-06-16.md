# Campaign 4 Remaining Capability Degraded Mode Master Matrix

Date: 2026-06-16

Gate: `campaign4_degraded_capabilities_finalization_long_run`

Overall status: `campaign4_remaining_capabilities_production_grade_accepted_ui_bound`

## Runtime Availability Matrix

| Capability | Primary runtime path | Current availability | Degraded / rollback path |
|---|---|---|---|
| External Source Verification | Approved public HTTP source fetch, source trace, evidence map, claim verification, freshness, contradiction, validation, and accepted Provider Runtime opt-in boundary | Available and UI-bound as `enabled_real` | Withhold network opt-in or source URL; continue local/manual evidence verification with explicit unavailable/degraded reason |
| OCR / Parser / Chunking | Builtin parser plus registered `parser-paddleocr` optional OCR backend | Available and UI-bound as `enabled_real` in the current local environment | Use backend `builtin`; OCR-required files become review-required if optional PaddleOCR dependency/model cache is absent |
| Knowledge Quality Gate | Local quality/evidence/retrieval/claim/freshness/contradiction reports | Available and UI-bound as `enabled_real` | Low-confidence/conflict cases become `review_required`, not false pass |
| Document Export | Local Markdown/DOCX/PDF/PPTX generation | Available and UI-bound as `enabled_real` | Disable failing format and continue other local formats with export validation report |
| Skill Governance | Local Skill generation and governance report | Available and UI-bound as `enabled_real` | Block or mark untrusted KB unless explicit trust evidence is present |
| Agent Creation Package | Local Agent Creation Package generation | Available and UI-bound as `enabled_real` for package export only | Keep package export; do not expose Agent CRUD/runtime/save/version |

## Failure Mode Matrix

| Failure mode | Affected capability | User-facing state | Required behavior |
|---|---|---|---|
| Network opt-in missing | External Source Verification | `unavailable` or explicit degraded external comparison status | Do not call network; preserve local/manual verification path and log id |
| Public source fetch fails | External Source Verification | `source_unavailable` / retryable failure | Show source URL, failure reason, retry advice, and preserve local KB workflows |
| Source trust/preflight fails | External Source Verification | `blocked` | Do not fetch unsafe or disallowed source; require Owner/user-approved source change |
| Evidence contradicts claim | External Source Verification | `review_required` / `conflicting` | Keep contradiction report, source trace, evidence id, and repair suggestion |
| Evidence freshness unknown | External Source Verification | `review_required` or `freshness_unknown` | Do not silently pass as fresh; request dated/independent evidence if needed |
| Provider accepted runtime unavailable | External Source Verification | `provider_unavailable` with local fallback | Continue local/manual evidence verification; do not present provider output |
| Optional PaddleOCR dependency missing | OCR / Parser / Chunking | `ocr_unavailable` with builtin fallback | Use builtin parser; show registered `parser-paddleocr` repair guidance |
| PaddleOCR model cache unavailable | OCR / Parser / Chunking | `ocr_unavailable` / retryable setup failure | Keep builtin parser available; log model/cache reason and retry guidance |
| OCR confidence low | OCR / Parser / Chunking | `review_required` | Preserve parsed text and source trace, require human review |
| Unsupported file type | OCR / Parser / Chunking | `unsupported` | Isolate file failure, continue other queued files |
| Parser backend failure | OCR / Parser / Chunking | `backend_failed` with fallback | Fall back to builtin when safe; write failure reason and artifact path |
| Quality conflict or stale evidence | Knowledge Quality Gate | `review_required` | Generate contradiction/freshness reports and keep review signal |
| Export format failure | Document Export | `format_failed` | Continue other formats, write export validation report, show retry advice |
| Untrusted KB export | Skill Governance / Agent Package | `blocked` unless explicitly allowed | Fail closed or require explicit trust evidence |
| Agent runtime requested | Agent Creation Package | `omitted` | Do not run; keep package export only and route runtime to future Campaign scope |
| Secret-like value in UI/Bridge/log | All | hard stop | Block gate and redact; do not print secret-like values |

## User-Facing Status Matrix

| Status | Meaning | Local continuation |
|---|---|---|
| `enabled_real` | Accepted runtime or local path is UI-bound for this Campaign 4 scope | Continue primary workflow |
| `source_unavailable` | Public source fetch failed or timed out | Continue local KB workflows; retry source later |
| `provider_unavailable` | Accepted provider runtime could not be used for this action | Continue local/manual evidence verification |
| `ocr_unavailable` | Registered OCR backend dependency or model runtime is unavailable | Continue builtin parser/chunking; mark OCR-required files review-required |
| `review_required` | Output exists but quality/freshness/OCR/source evidence requires review | Keep artifact and report; ask user to review/retry |
| `unsupported` | File/source/runtime is outside supported local path | Isolate failure; continue other queued items |
| `blocked` | Safety, trust, dependency, or authorization prerequisite is missing | Stop only the unsafe action and show repair suggestion |
| `omitted` | Future Campaign/Post-9 capability | Keep hidden or disabled; do not claim available |

## Rollback / Disable Switches

| Capability | Disable / rollback switch |
|---|---|
| External Source Verification | Withhold live external network opt-in, remove source URL input, or use local/manual evidence files only; local KB and document workflows continue |
| OCR / Parser / Chunking | Disable or uninstall `parser-paddleocr`, remove local model cache, or choose backend `builtin`; queue marks OCR-required files review-required |
| Knowledge Quality Gate | Disable external verification sources; local package quality reports still run |
| Document Export | Remove a requested format from `--formats`; other local formats continue |
| Skill Governance | Keep advanced composition display-only; generated Skill and governance report remain usable |
| Agent Creation Package | Export package draft only; keep save/version/runtime omitted |

## Local / Offline Fallback Statement

Local/offline mode can still run local KB inspection, builtin parsing, chunking, local quality gate, local retrieval, local/manual evidence verification, document export, Skill governance, Agent Creation Package export, reports, and audit review.

Mock/offline or deterministic evidence must not be presented as live external Provider output, live public source fetch, PaddleOCR runtime output, Agent Runtime execution, Memory, A2A, Collaboration, or EXE packaging.

## Remaining Boundaries

- External Source Verification acceptance does not include arbitrary crawling, authenticated browsing, paywall bypass, CAPTCHA bypass, or unrestricted live comparison.
- PaddleOCR acceptance does not imply Campaign 9 EXE bundling of optional dependency or model files.
- PaddleOCR layout/table/figure/formula support remains unsupported or unknown in the current backend contract.
- Agent Runtime, Memory, Collaboration, A2A, and Campaign 5-9 remain outside this gate.

## Stop

This degraded mode matrix stops at `campaign4_remaining_capabilities_production_grade_accepted_ui_bound`.

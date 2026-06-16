# Campaign 4 Degraded Capabilities Final Status Matrix

Date: 2026-06-16

Gate: `campaign4_degraded_capabilities_finalization_long_run`

Overall status: `campaign4_remaining_capabilities_production_grade_accepted_ui_bound`

## Final Status Matrix

| Capability | UI state before finalization | UI state after finalization | Accepted runtime path | Yellow marker decision |
|---|---|---|---|---|
| External Source Verification | `enabled_real_degraded` | `enabled_real` | Public URL ingestion, source preflight, source trace, evidence map, claim verification, freshness/contradiction evidence, validation, accepted Provider Runtime opt-in boundary | Remove this capability's degraded/yellow marker |
| OCR / Parser / Chunking | `enabled_real_degraded` | `enabled_real` | Builtin parser/chunking plus registered `parser-paddleocr` optional OCR backend with real runtime smoke and OCR output | Remove this capability's degraded/yellow marker |

## Non-Target Marker Guard

| Boundary | Decision |
|---|---|
| External Vector DB provider | Remains `disabled_boundary` |
| Agent Runtime / CRUD / save-version | Remains omitted/out of scope |
| Memory / Collaboration / A2A | Remains omitted/out of scope |
| Campaign 5 / 6 / 7 / 8 / 9 | Not started |
| EXE packaging / Stable Release | Not claimed |

## UI / Bridge Fixture

Updated fixture:

`kb-forge-skill-ui/web/workbench/flutter_app/assets/contracts/campaign4_remaining_capability_status_2026_06_16.json`

Required final values:

- `external_source_verification.ui_state = enabled_real`
- `external_source_verification.yellow_marker_removed = true`
- `ocr_parser_chunking.ui_state = enabled_real`
- `ocr_parser_chunking.yellow_marker_removed = true`
- `overall_status = campaign4_remaining_capabilities_production_grade_accepted_ui_bound`

## Stop

This status matrix stops at `campaign4_remaining_capabilities_production_grade_accepted_ui_bound`.

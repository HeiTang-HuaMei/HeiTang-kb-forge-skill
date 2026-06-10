# Release Notes

## v4.1.0

`v4.1.0` is the Parser/OCR Pluggable Backend Runtime release. It industrializes the completed P2.1 runtime integration so a third party can inspect the backend matrix, replay evidence, understand install modes and limitations, and verify controlled fallback behavior.

- Added release evidence at `docs/audits/p2_1_parser_ocr_backends/`.
- Added stable CLI surfaces for backend registry, matrix, inspect, smoke, and release evidence generation.
- Integrated Docling, PaddleOCR, and Unstructured as opt-in local runtime adapters only.
- Preserved builtin parser fallback and default install behavior.
- Kept heavy parser/OCR dependencies optional; no default bundling or model download.
- Documented Unstructured stable surface as `.md/.txt`; broader PDF/DOCX/image extras remain future hardening.
- Kept `v4.0.0` untouched as the historical stable tag.
- Did not start P2.2.

## v4.0.0

Stable `v4.0.0` starts after P1 Final Gate Re-run, Pre-v4 External Project Registry, S/A Contract Inclusion, rc.1 acceptance, and release hardening completed. Core pre-v4 RC readiness remains attached as historical evidence. The latest Core P0 proof reports `ready_for_v4_rc=true` and `P0 blockers=0`, and the latest P1 final gate re-run also reports `ready_for_v4_rc=true`.

This stable release preserves local-first boundaries: Core tests do not require real LLM/API/network calls, external projects remain visibility or planned-adapter boundaries unless separately implemented, and provider secrets stay outside committed outputs.

## v4.0.0-rc.1

This release candidate starts after P1 Final Gate Re-run, Pre-v4 External Project Registry, and S/A Contract Inclusion have completed. Core pre-v4 RC readiness remains complete. The latest Core P0 proof reports `ready_for_v4_rc=true` and `P0 blockers=0`, and the latest P1 final gate re-run also reports `ready_for_v4_rc=true`.

This is not the stable `v4.0.0` release. Stable `v4.0.0` requires rc.1 acceptance and hardening evidence.

## Current Main

## P1 Final Gate Re-run

- Added `docs/audits/p1_final_gate_rerun/`.
- Re-verified P1-RWF-V1, P1-RWF-V2, 57 ready local action executions, 10 user paths, UI consumption, drift count, and provider/secret/network blocked boundaries.
- Promoted `ready_for_v4_rc_candidate=true` to `ready_for_v4_rc=true` without starting v4.0, creating a tag, or writing a release.

## P0.6 GitHub Documentation Governance

- Slimmed the GitHub-facing documentation surface.
- Kept current product entry points, current truth, command usage, version matrix, final architecture truth, final gate JSON, and latest P0 proof.
- Moved historical version details back to git history and tags instead of keeping them as top-level docs on main.
- Added documentation governance and README link checks.

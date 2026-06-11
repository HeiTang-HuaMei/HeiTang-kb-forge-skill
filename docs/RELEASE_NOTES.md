# Release Notes

## v4.2.0

`v4.2.0` is the P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline. It starts from existing knowledge asset packages, extracts methodology evidence, plans a Skill Suite, builds routable Skills, and closes validation, diff, installability, governance, UI, and CLI evidence.

- Added the P2.2 methodology flow: `extract-methodology --kb <knowledge_package> --out <methodology>` with evidence windows, methodology map, source trace, confidence, and risk flags.
- Added Skill Suite planning and build commands: `plan-skill-suite` and `build-skill-suite`, including Planning / Functional / Atomic classifications, routing rules, dependency graph, duplicate/conflict detection, merge/split evidence, and suite manifests.
- Added controlled Skill Pack export through `export-skill-pack`, with allowed-file boundaries, manifest hashes, description/trigger quality, evaluation checklist, and optimization notes.
- Added suite-level governance commands: `validate-skill-suite`, `diff-skill-suite`, `check-skill-suite-installability`, and `skill-suite-governance-report`.
- Closed UI/CLI industrial workflow evidence for Knowledge Package -> Evidence -> Methodology -> Candidates -> Hierarchy -> Skill Suite -> Reports -> Export while keeping the static Workbench evidence-only and not a local CLI executor.
- Corresponding UI release commit: `0049ccf135a3cd7fd76b51ec923db3ceb583c1c0`.
- Kept `v4.1.1` as the P2.2 Entry Gate / Test Governance Stable Baseline, `v4.1.0` as the Parser/OCR Stable Baseline, and `v4.0.0` untouched.
- Did not start P2.3 and did not add external runtime/provider/API integration or runtime vendoring.

## v4.1.1

`v4.1.1` is the Test Framework Governance release. It turns the v4.1.0 validation hardening lessons into executable governance artifacts while preserving the v4.1.0 Parser/OCR runtime boundary.

- Added `docs/testing/VALIDATION_GATE_MANIFEST.json` as the structured gate manifest.
- Added `python -m heitang_kb_forge.test_governance.gates` for changed-file impact selection and dry-run/executable validation plans.
- Added pytest markers for Fast, Medium, Full, docs truth, parser backend, release, UI contract, and slow gate grouping.
- Added `docs/testing/TEST_PRUNING_REGISTER.md` and zh-CN peer to track obsolete/duplicate test pruning before deletion.
- Kept `v4.1.0` and `v4.0.0` tags untouched.
- Did not start P2.2.

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

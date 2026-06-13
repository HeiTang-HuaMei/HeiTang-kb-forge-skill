# Integration Decision Policy

This policy normalizes adapter integration decisions after dependency checks, remediation attempts, smoke runs, UI impact review, and tests.

## Allowed Decisions

- `real_integration`
- `reference_only`
- `needs_strengthening`
- `stop_integration`

## Adapter Flow

Every Document Understanding backend must follow this flow:

1. Check dependency.
2. If missing, attempt dependency remediation when project-approved.
3. Re-check dependency.
4. Run smoke.
5. Run the real adapter when possible.
6. Produce `integration_decision_report`.
7. Produce UI impact note.
8. Run focused tests.
9. Update active-agent and checkpoint records if sub-agents or recovery were used.

Applies to PaddleOCR, MinerU, Docling, Marker, OpenDataLoader, Surya, Unstructured, and fallback parser paths.

## Required Adapter Artifacts

Each adapter must produce:

- `<adapter>_dependency_remediation_report.json`
- `<adapter>_dependency_remediation_report.md`
- `<adapter>_integration_decision_report.json`
- `<adapter>_integration_decision_report.md`
- `<adapter>_ui_impact_note.md`

## Decision Evidence

Initial missing dependency evidence is an input, not a final decision. The final decision must be based on post-remediation dependency checks, smoke results, runtime output contracts, and UI truthfulness impact.

## Acceptance

Validation must cover decision values, remediation-before-final-blocked behavior, structured skipped failures, UI impact note presence, and focused adapter tests.

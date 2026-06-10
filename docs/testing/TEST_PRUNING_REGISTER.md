# Test Pruning Register

Version: `v4.1.1`

This register makes obsolete-test pruning auditable. It does not mark tests as passed or removed by default. A test can be deleted or merged only after the canonical replacement is named and covered by a validation gate.

## Canonical Truth Sources

| Surface | Canonical source | Guard test |
| --- | --- | --- |
| Version metadata | `pyproject.toml`, `skill.json`, `docs/VERSION_MATRIX.md` | `tests/test_version_alignment.py`, `tests/test_skill_metadata.py` |
| Release checklist | `docs/RELEASE_CHECKLIST.md` and zh-CN peer | `tests/test_release_checklist_docs.py` |
| Workbench contract | `web/workbench/contracts.json` | `tests/test_workbench_ui_contract.py` |
| Parser/OCR evidence fixture | `examples/ui_mock_data/parser_backends/parser_backend_matrix.json` and Flutter asset peer | `tests/test_workbench_ui_mock_data.py` |
| Test governance | `docs/testing/VALIDATION_GATE_MANIFEST.json` | `tests/test_test_governance_manifest.py` |

## Current Pruning Candidates

| Candidate pattern | Risk | Replacement before pruning | Status |
| --- | --- | --- | --- |
| Repeated exact version string checks across README, matrix, and metadata tests | High maintenance cost when the release line changes | Keep one canonical version alignment test and assert release roles semantically elsewhere | tracked |
| Workbench source exact-string checks | Can fail on harmless layout refactors | Prefer contract, fixture, model, and asset drift tests | tracked |
| Duplicate parser/OCR fixture checks | Can report the same fixture drift in several places | Keep one owner for fixture parity and one owner for display contract | tracked |
| Flutter widget text assertions for long evidence strings | Fragile against copy edits and localization refinements | Prefer presence of stable semantic labels and layout overflow checks | tracked |
| Broad docs tests that duplicate release checklist checks | Repeated failures for one release-line edit | Keep release checklist as the owner and use manifest impact rules for docs changes | tracked |

## Pruning Rule

Before deleting or merging any candidate:

1. Name the canonical owner test.
2. Name the replacement invariant.
3. Add or update the validation gate manifest if the impacted surface changes.
4. Run the impacted Fast Gate.
5. Record the deletion or merge in the release validation report.

No skipped, deferred, blocked, env-blocked, or unavailable test may be reported as passed.

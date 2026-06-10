# Test Pruning Register

Version: `v4.1.1`

This register keeps obsolete-test pruning auditable. It does not mark tests as passed or removed by default. A test can be deleted or merged only after the canonical replacement is named and covered by a validation gate.

## Canonical Truth Sources

| Surface | Canonical source | Guard test |
| --- | --- | --- |
| Version metadata | `pyproject.toml`, `skill.json`, `docs/VERSION_MATRIX.md` | `tests/test_version_alignment.py`, `tests/test_final_version_metadata.py` |
| Release checklist | `docs/RELEASE_CHECKLIST.md` and zh-CN peer | `tests/test_release_checklist_docs.py` |
| Documentation structure | `docs/DOCS_INDEX.md` and `docs/DOCS_INDEX.zh-CN.md` | `tests/test_final_docs_structure.py` |
| Parser/OCR boundaries | `docs/audits/p2_1_parser_ocr_backends/` | `tests/test_v28_parser_backends.py` |
| Test governance | `docs/testing/VALIDATION_GATE_MANIFEST.json` | `tests/test_test_governance_manifest.py` |

## Current Pruning Candidates

| Candidate pattern | Risk | Replacement before pruning | Status |
| --- | --- | --- | --- |
| Repeated exact version string checks across docs tests | High maintenance cost when release version changes | Keep one canonical version alignment test and assert semantic release roles elsewhere | tracked |
| Repeated README phrase checks for release boundaries | Fragile against wording-only docs edits | Prefer structured release checklist or version matrix assertions | tracked |
| Duplicate docs index link checks | Repeated failures for one missing file | Keep one link-existence owner and use manifest impact rules for docs changes | tracked |
| UI source exact-string checks | Can fail on harmless layout refactors | Prefer fixture/asset/model contract tests | tracked |
| Parser boundary wording checks in broad docs tests | Can duplicate parser backend tests | Keep parser backend capability boundaries in parser-focused gate | tracked |

## Pruning Rule

Before deleting or merging any candidate:

1. Name the canonical owner test.
2. Name the replacement invariant.
3. Add or update the validation gate manifest if the impacted surface changes.
4. Run the impacted Fast Gate.
5. Record the deletion or merge in the release validation report.

No skipped, deferred, blocked, or unavailable test may be reported as passed.

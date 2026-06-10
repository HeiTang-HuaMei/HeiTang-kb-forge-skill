# Validation Report

Version: v4.1.0

Gate: Chunked Full Gate

Repository: Core

Decision: `chunked_full_gate_passed_pending_commit_push_ci`

## Chunks

| Chunk | Command | Exit code | Status | Summary | Log |
| --- | --- | --- | --- | --- | --- |
| core_docs_truth_gate | `python -m pytest tests/test_final_docs_truthfulness.py tests/test_final_bilingual_docs_parity.py tests/test_final_docs_structure.py tests/test_release_checklist_docs.py tests/test_readme_scope.py tests/test_version_alignment.py tests/test_version_matrix_docs.py -q` | 0 | passed | 13 passed in 1.50s | `docs/audits/test_engineering/full_gate_logs/core_docs_truth_gate.log` |
| core_parser_backend_gate | `python -m pytest tests/test_v28_parser_backends.py -q` | 0 | passed | 31 passed in 6.48s | `docs/audits/test_engineering/full_gate_logs/core_parser_backend_gate.log` |
| core_external_boundary_gate | `python -m pytest tests/test_external_project_registry.py tests/test_planned_adapter_boundaries.py tests/test_s_a_contract_inclusion.py tests/test_post_v4_external_roadmap.py -q` | 0 | passed | 16 passed in 2.80s | `docs/audits/test_engineering/full_gate_logs/core_external_boundary_gate.log` |
| core_remaining_or_full_gate | `python -m pytest -q` | 0 | passed | 895 passed, 1 skipped in 2993.07s | `docs/audits/test_engineering/full_gate_logs/core_remaining_or_full_gate.log` |
| core_git_diff_check | `git diff --check` | 0 | passed | no whitespace errors; LF/CRLF warnings only | `docs/audits/test_engineering/full_gate_logs/core_git_diff_check.log` |
| core_secret_provider_scan | `rg` keyword scan for secrets/provider config | 0 | passed | keyword hits reviewed; no real secret or local provider credential found | `docs/audits/test_engineering/full_gate_logs/core_secret_provider_scan.log` |
| core_untracked_files_review | `git ls-files -o --exclude-standard` | 0 | passed | intended source/audit additions only; no build output, raw runtime output, local provider config, or temporary debug directory | `docs/audits/test_engineering/full_gate_logs/core_untracked_files.log` |

## Deferred Or Skipped

None. No release-blocking chunk is deferred or skipped.

## Remaining Release Gates

- Commit Core changes.
- Push Core branch.
- Commit and push UI changes.
- Wait for Core CI green.
- Wait for UI CI green.
- Create `v4.1.0` tag only after CI is green.
- Create GitHub release only after tag checks pass.

## Boundaries

- `v4.0.0` tag remains untouched.
- `v4.1.0` is not tagged in this report.
- P2.2 is not started.
- No skipped/deferred test is reported as passed.
- Opaque full pytest is not used as the sole release evidence; release evidence is chunked with logs and exit codes.
- Unstructured stable surface remains `.md/.txt`.

# Validation Report

Version: `v4.2.0`

Release: P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline

Repository: Core

Decision: `chunked_full_gate_and_post_codex_full_review_passed_pending_remote_release_gates`

Generated local date: 2026-06-11

## Chunked Full Gate

| Chunk | Exit code | Status | Summary | Evidence |
| --- | ---: | --- | --- | --- |
| `core_full_docs_truth_chunk` | 0 | passed | 26 passed | `full_gate_logs/core_full_docs_truth_chunk.log` |
| `core_full_parser_backend_chunk` | 0 | passed | 47 passed | `full_gate_logs/core_full_parser_backend_chunk.log` |
| `core_full_a_c_chunk` | 0 | passed | 109 passed | `full_gate_logs/core_full_a_c_chunk.log` |
| `core_full_d_f_chunk` | 0 | passed | 120 passed | `full_gate_logs/core_full_d_f_chunk.log` |
| `core_full_g_m_chunk` | 0 | passed | 119 passed, 1 skipped | `full_gate_logs/core_full_g_m_chunk.log` |
| `core_full_n_s_chunk` | 0 | passed | 259 passed | `full_gate_logs/core_full_n_s_chunk.log` |
| `core_full_t_z_chunk` | 0 | passed | 320 passed | `full_gate_logs/core_full_t_z_chunk.log` |
| `core_git_diff_check` | 0 | passed | No whitespace errors; CRLF conversion warnings only | `full_gate_logs/core_git_diff_check.log` |

Every chunk has a sibling `.exitcode` file and `.result.json` sidecar.

## Skipped Tests

No release-blocking chunk was skipped or deferred.

The executed G-M chunk reported one skipped test, which is not counted as passed:

| Test | Reason | Release impact |
| --- | --- | --- |
| `tests/test_live_provider_smoke.py::test_live_provider_smoke_entrypoint_is_explicitly_opt_in` | Requires explicit `HEITANG_RUN_LIVE_TESTS=1` opt-in and a live provider boundary | non-blocking; no external provider/API was added to P2.2 |

## Post-Codex Full Review

- Status: passed
- Report: `post_codex_full_review.md`
- Open P0/P1/P2: 0
- Resolved issue: `PCR-v4.2.0-001`

## Remaining Remote Release Gates

- Commit and push the reviewed Core release commit.
- Core CI green.
- Core Release Check green.
- Verify the green run commit equals Core HEAD.
- Create the new `v4.2.0` tag and GitHub Release after both repositories are green.

## Boundaries

- v4.1.0 remains the Parser/OCR Stable Baseline.
- v4.1.1 remains the P2.2 Entry Gate / Test Governance Stable Baseline.
- P2.3 is not started.
- No external runtime/provider/API integration or runtime vendoring was added.
- Unstructured remains stable only for `.md/.txt`.
- No skipped or deferred check is reported as passed.

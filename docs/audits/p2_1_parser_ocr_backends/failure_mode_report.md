# Parser Backend Failure Mode Report

- Status: `pass`
- Fallback preserved: `true`
- Crash-only failures allowed: `false`

| Case | Error code | Workbench status | Fallback |
| --- | --- | --- | --- |
| missing_backend_dependency | optional_runtime_dependency_missing | blocked_by_dependency | builtin_available |
| invalid_backend_id | invalid_backend_id | not_ready | builtin_available |
| unsupported_file_type | unsupported_file_type | not_ready | builtin_available_when_supported |
| backend_import_unavailable | optional_runtime_dependency_missing | blocked_by_dependency | builtin_available |
| runtime_exception | backend_runtime_exception | not_ready | builtin_available_when_supported |
| empty_result | empty_parse_result | not_ready | manual_review_required |

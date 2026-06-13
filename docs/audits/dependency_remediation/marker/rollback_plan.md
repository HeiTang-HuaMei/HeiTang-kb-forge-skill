# Marker Runtime Rollback Plan

- Remove `_local_dependency_remediation/marker`.
- Remove Marker-only model files under `.heitang_cache/marker`.
- Revert only Marker adapter and Marker-specific test changes if integration is abandoned.
- Do not change the global Python environment.
- Re-run Marker check and smoke to verify the rolled-back state.

Marker may be used for local development smoke. EXE bundling remains subject to a separate GPL/model-weight license compatibility review.

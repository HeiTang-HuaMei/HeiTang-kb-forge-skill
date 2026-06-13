# Rollback Plan

If 5.14 evidence introduces drift or failing gates:

1. Remove `heitang_kb_forge/external_retrieval/sirchmunk.py` and the corresponding exports.
2. Remove `build-sirchmunk-direct-file-search` and `validate-sirchmunk-direct-file-search` CLI commands.
3. Remove `tests/test_sirchmunk_direct_file_search.py` and any 5.14 registry/assertion updates.
4. Revert Sirchmunk entries in external project registry, Workbench capability mappings, audit manifest/index, and UI synced assets.
5. Re-run focused registry/governance tests and `git diff --check`.

No system paths, global PATH, registry keys, external runtimes, credentials, or user-global caches are touched by this action.

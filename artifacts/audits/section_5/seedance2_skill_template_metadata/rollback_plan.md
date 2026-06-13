# Rollback Plan

If item 5.11 validation fails:

1. Revert only the local Seedance template-metadata module, CLI registration, item 5.11 reports, registry/UI status updates, tests, and sequence updates.
2. Restore the sequence position to `5.11 seedance2-skill`.
3. Preserve all item 5.1-5.10 evidence and Campaign 3 Supplement 3.0 governance files.
4. Do not remove unrelated worktree changes.
5. Re-run registry, governance, UI asset, and `git diff --check` validations.

No external provider request, credential, account, generated media, remote branch, tag, or release is affected.

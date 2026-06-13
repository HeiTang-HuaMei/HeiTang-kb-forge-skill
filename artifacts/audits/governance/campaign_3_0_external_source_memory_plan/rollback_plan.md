# Rollback Plan

If the Campaign 3.0 governance insertion fails validation:

1. Revert only the Campaign 3.0 additions in project governance, tests, validation manifest, audit index, and project memory files.
2. Restore the prior next-item state: `5.11 seedance2-skill`.
3. Preserve all existing Campaign 3 2.0 evidence and all completed items 5.1-5.10.
4. Do not delete or rewrite unrelated dirty-worktree changes.
5. Re-run the focused governance tests and `git diff --check`.

No runtime data, dependency environment, external account, cookie, credential, remote branch, tag, or release is modified by this governance action.

# V1 Package Gate B1 Retry Tracked Drift RCA Report

Generated: 2026-06-29

## Scope

This report is tracked-drift RCA only.

No restore, artifact deletion, build rerun, package rerun, git add, commit, push, tag/release, Final Owner Review, code edit, or `capability_chain_status.json` edit was performed.

Current state remains:

`package_gate_b1_retry_failed_pending_failure_review`

Completion state:

`package_gate_b1_retry_tracked_drift_rca_completed_pending_owner_decision`

## Current State

| Item | Value |
| --- | --- |
| `git log -1 --oneline` | `0013fdb fix(package): stabilize tauri build exit handling` |
| Branch | `v1-clean-baseline-reconstruction` |
| Retry command exit code | `0` |
| Artifact path | `desktop\tauri\src-tauri\target\release\bundle\nsis\HeiTang KB Forge Desktop_1.2.3_x64-setup.exe` |
| Artifact size | `1992576` bytes |
| `capability_chain_status.json` diff | empty |
| Ready-claim scan | clean; non-claim matches only |

Package Gate remains failed because the retry left tracked Tauri files marked modified after build. Owner-defined failure criteria classify build-created tracked code/config drift as a failure even when the command exit code is `0` and the NSIS artifact exists.

## Drifted Files

```text
desktop/tauri/src-tauri/Cargo.toml
desktop/tauri/src-tauri/gen/schemas/desktop-schema.json
desktop/tauri/src-tauri/gen/schemas/windows-schema.json
```

## Diff Classification

Commands inspected:

```text
git diff --ignore-space-at-eol --exit-code -- desktop/tauri/src-tauri/Cargo.toml desktop/tauri/src-tauri/gen/schemas/desktop-schema.json desktop/tauri/src-tauri/gen/schemas/windows-schema.json
git diff --numstat -- desktop/tauri/src-tauri/Cargo.toml desktop/tauri/src-tauri/gen/schemas/desktop-schema.json desktop/tauri/src-tauri/gen/schemas/windows-schema.json
git diff --word-diff -- desktop/tauri/src-tauri/Cargo.toml desktop/tauri/src-tauri/gen/schemas/desktop-schema.json desktop/tauri/src-tauri/gen/schemas/windows-schema.json
git diff -- desktop/tauri/src-tauri/Cargo.toml
git diff -- desktop/tauri/src-tauri/gen/schemas/desktop-schema.json
git diff -- desktop/tauri/src-tauri/gen/schemas/windows-schema.json
```

Observed results:

- `git diff --ignore-space-at-eol --exit-code` returned exit code `0`.
- `git diff --numstat` emitted no insertion/deletion counts.
- `git diff --word-diff` emitted no content diff.
- Per-file `git diff -- <file>` emitted no content diff.
- Git emitted warnings that LF will be replaced by CRLF the next time Git touches the files.

Classification:

| File | Classification | Evidence |
| --- | --- | --- |
| `desktop/tauri/src-tauri/Cargo.toml` | `line-ending-only` | no content diff; no word diff; no numstat; LF/CRLF warning only |
| `desktop/tauri/src-tauri/gen/schemas/desktop-schema.json` | `line-ending-only` | no content diff; no word diff; no numstat; LF/CRLF warning only |
| `desktop/tauri/src-tauri/gen/schemas/windows-schema.json` | `line-ending-only` | no content diff; no word diff; no numstat; LF/CRLF warning only |

No evidence of whitespace-only body changes or real content changes was found.

## EOL And Attributes

`git check-attr text eol -- <files>` result:

```text
desktop/tauri/src-tauri/Cargo.toml: text: unspecified
desktop/tauri/src-tauri/Cargo.toml: eol: unspecified
desktop/tauri/src-tauri/gen/schemas/desktop-schema.json: text: unspecified
desktop/tauri/src-tauri/gen/schemas/desktop-schema.json: eol: unspecified
desktop/tauri/src-tauri/gen/schemas/windows-schema.json: text: unspecified
desktop/tauri/src-tauri/gen/schemas/windows-schema.json: eol: unspecified
```

`git ls-files --eol -- <files>` result:

```text
i/lf    w/lf    attr/                 desktop/tauri/src-tauri/Cargo.toml
i/lf    w/lf    attr/                 desktop/tauri/src-tauri/gen/schemas/desktop-schema.json
i/lf    w/lf    attr/                 desktop/tauri/src-tauri/gen/schemas/windows-schema.json
```

Repository attributes:

```text
NO .gitattributes
```

RCA conclusion: the repository does not define explicit text/eol policy for these Tauri files. On this Windows worktree, Tauri/Cargo build activity leaves the files marked modified even though content-level diff tools show no substantive changes.

## Generated Content Assessment

No real Tauri/Cargo generated content change was found:

- no `Cargo.toml` manifest body diff;
- no `desktop-schema.json` body diff;
- no `windows-schema.json` body diff;
- no insertion/deletion counts;
- no word-level changes.

The drift is best classified as line-ending/worktree-state drift rather than generated schema or Cargo content drift.

## Policy Questions

Does the project need `.gitattributes`?

- Yes, likely. Explicit EOL policy for Tauri/Cargo generated/config files would reduce cross-platform Package Gate drift.

Does the project need to commit normalized generated files?

- Not as generated content updates. Current evidence does not show real generated changes.
- If `.gitattributes` is added, a normalization commit may be needed, but that is an EOL policy commit, not a schema/Cargo content update.

Does `build_tauri.ps1` need to force a clean worktree check after success?

- Yes, likely. A future Package Gate script or wrapper should fail explicitly when tracked drift remains after a successful build, and report the drift clearly.
- It should not silently restore generated drift unless Owner explicitly chooses that policy.

## Recommended Next Action

Recommended option: **A. add .gitattributes + normalize files, commit, then rerun B1**.

Reason: the evidence points to line-ending-only drift caused by missing EOL policy. Option A addresses the root policy gap and preserves Package Gate's clean-worktree requirement.

Other options:

| Option | Assessment |
| --- | --- |
| B. commit generated schema/Cargo changes, then rerun B1 | not recommended; no real generated content changes were found |
| C. harden build script to restore generated drift after successful build, then rerun B1 | not recommended as first choice; auto-restore could hide real future generated drift |
| D. classify as environment-only and rerun from fresh clone/worktree | possible diagnostic path, but does not create a durable repo policy |
| E. block Package Gate until Tauri drift policy is decided | conservative fallback if Owner does not approve EOL normalization |

## Non-Claims

This RCA does not claim:

- `package_gate_passed`
- `release_ready`
- `production_ready`
- `runtime_ready`
- `final_owner_review_passed`

## Final State

`package_gate_b1_retry_tracked_drift_rca_completed_pending_owner_decision`

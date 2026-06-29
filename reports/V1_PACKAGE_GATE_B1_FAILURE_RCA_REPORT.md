# V1 Package Gate B1 Failure RCA Report

Generated: 2026-06-29

## Scope

This report is failure review and root-cause analysis only.

No restore, cleanup, build rerun, package rerun, git add, commit, push, tag/release, or Final Owner Review was performed. No code file or `capability_chain_status.json` edit was performed.

Current state remains:

`package_gate_b1_failed_pending_failure_review`

Completion state for this RCA:

`package_gate_b1_failure_rca_completed_pending_owner_decision`

## Current State

| Item | Value |
| --- | --- |
| Worktree | `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui-v1-clean-reconstruction` |
| `git log -1 --oneline` | `136adc5 docs: record v1 package gate preflight readiness` |
| Branch | `v1-clean-baseline-reconstruction` |
| B1 command | `.\packaging\desktop\build_tauri.ps1` |
| B1 command exit code | `1` |
| Result state before RCA | `package_gate_b1_failed_pending_failure_review` |

## Artifact

An NSIS artifact was produced:

| File | Path | Size bytes | Timestamp |
| --- | --- | ---: | --- |
| `HeiTang KB Forge Desktop_1.2.3_x64-setup.exe` | `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui-v1-clean-reconstruction\desktop\tauri\src-tauri\target\release\bundle\nsis\HeiTang KB Forge Desktop_1.2.3_x64-setup.exe` | `1992895` | `2026-06-29T21:43:00.2939450+08:00` |

The artifact does not make Package Gate pass because the authorized command returned exit code `1` and the post-run worktree was not clean.

## Command Evidence

`reports/V1_PACKAGE_GATE_RESULT_REPORT.md` records:

- command: `.\packaging\desktop\build_tauri.ps1`
- start time: `2026-06-29T21:39:00+08:00`
- end time: approximately `2026-06-29T21:43:01+08:00`
- observed exit code: `1`
- stdout log: `reports/package_gate_b1_logs/build_tauri_20260629_213900.stdout.log`
- stderr log: `reports/package_gate_b1_logs/build_tauri_20260629_213900.stderr.log`

stdout summary:

```text
> heitang-kb-forge-desktop@1.2.3 tauri:build
> tauri build
```

stderr log summary:

```text
empty
```

The direct observed trigger for the non-zero command result was a PowerShell/native-command error emitted while `npm.cmd run tauri:build` was looking up installed Tauri packages. The error surfaced at `packaging/desktop/build_tauri.ps1:5`.

No evidence was found that `build_tauri.ps1` has a post-build artifact check, diff check, signing check, or Package Gate validation step after `npm.cmd run tauri:build`.

## Script And Config Review

`packaging/desktop/build_tauri.ps1`:

```powershell
$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location (Join-Path $Root "desktop\tauri")
npm.cmd run tauri:build
```

`desktop/tauri/package.json` defines:

- `tauri:build`: `tauri build`
- `build`: `vite build --config vite.config.mjs`
- `typecheck`: `tsc --noEmit`

`desktop/tauri/src-tauri/tauri.conf.json` defines:

- product name: `HeiTang KB Forge Desktop`
- version: `1.2.3`
- identifier: `com.heitang.kbforge`
- bundle target: `nsis`
- before-build command: `npm run build`

The script itself is minimal and does not explicitly fail on tracked-file diffs. The non-zero result is most likely from the PowerShell/native-command handling of Tauri/NPM output under `$ErrorActionPreference = "Stop"`, not from an explicit package-gate assertion in the script.

## Tracked Diff Review

Post-B1 modified tracked files:

```text
desktop/tauri/src-tauri/Cargo.toml
desktop/tauri/src-tauri/gen/schemas/desktop-schema.json
desktop/tauri/src-tauri/gen/schemas/windows-schema.json
```

Per-file diff inspection:

| File | `git diff -- <file>` result | RCA summary |
| --- | --- | --- |
| `desktop/tauri/src-tauri/Cargo.toml` | no content diff body; LF/CRLF warning only | line-ending/worktree normalization drift |
| `desktop/tauri/src-tauri/gen/schemas/desktop-schema.json` | no content diff body; LF/CRLF warning only | line-ending/worktree normalization drift |
| `desktop/tauri/src-tauri/gen/schemas/windows-schema.json` | no content diff body; LF/CRLF warning only | line-ending/worktree normalization drift |

Additional Git evidence:

- `git diff --raw` shows the same object id before and after for each of the three files.
- `git status --porcelain=v2` marks them as worktree-modified (`.M`) while index and HEAD object IDs match.
- `git ls-files --eol` reports `i/lf w/lf` for the three files, while Git still warns that LF will be replaced by CRLF when touched.

RCA interpretation: the three tracked files do not show substantive Cargo manifest, generated schema, or Tauri config content changes. They are still unsafe to ignore because the worktree is marked modified after B1.

## Root Cause Classification

| Category | Assessment |
| --- | --- |
| Real package artifact failure | not proven; installer was generated |
| Build script post-check failure | not found; script has no post-check after `npm.cmd run tauri:build` |
| Tauri generated file drift | not content drift; only worktree status/line-ending drift observed |
| Cargo/Tauri manifest drift | not content drift; `Cargo.toml` has no diff body |
| Environment / PowerShell handling | likely contributor; native-command/Tauri info output surfaced as PowerShell error under `$ErrorActionPreference = "Stop"` |
| Script robustness issue | likely contributor; script does not isolate native stderr handling or normalize exit-code capture/reporting |
| Package Gate failure status | correct; exit code `1` and dirty tracked status block pass conclusion |

## Safety Of Revert Or Commit Options

Is it safe to revert the tracked diff?

- Likely yes for the three tracked files, because no content diff body is present and object IDs match.
- Revert must still be Owner-authorized because this RCA task explicitly forbids restore.

Should generated schema / `Cargo.toml` changes be included in a fix commit?

- Not based on current evidence. There is no substantive generated schema or manifest change to commit.
- If a later clean rerun produces content diffs, reassess then.

Should `build_tauri.ps1` be modified?

- Possibly yes in a later Owner-authorized fix task.
- Candidate fix area: make the script capture native command output and `$LASTEXITCODE` explicitly, without treating informational native stderr as a terminating PowerShell error.
- Any script change must be followed by a fresh B1 rerun under Owner authorization.

## Recommended Next Action

Recommended path: **C then A, with Owner authorization**.

1. Fix `build_tauri.ps1` so native command execution and exit-code capture are deterministic.
2. Revert or normalize the three line-ending/worktree drift files if Owner authorizes cleanup.
3. Rerun B1 Package Gate from a clean worktree.

Option assessment:

| Option | Recommendation |
| --- | --- |
| A. revert generated tracked diff and rerun | useful cleanup, but may not fix exit code `1` by itself |
| B. commit required generated file updates then rerun | not recommended from current evidence; no content update found |
| C. fix build script then rerun | recommended primary fix path |
| D. environment fix then rerun | secondary path if script hardening still reports native/Tauri failure |

## Non-Claims

This RCA does not claim:

- `package_gate_passed`
- `release_ready`
- `production_ready`
- `runtime_ready`
- `final_owner_review_passed`

## Final State

`package_gate_b1_failure_rca_completed_pending_owner_decision`

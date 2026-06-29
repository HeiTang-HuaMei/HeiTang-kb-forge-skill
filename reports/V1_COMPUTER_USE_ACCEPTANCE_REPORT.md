# V1 Computer Use Acceptance Report

Generated: 2026-06-29

## Scope

This report records Computer Use / desktop automation evidence collected before Final Owner Review.

This is not Final Owner Review. No push, tag/release, Package Gate rebuild, product-code edit, or `capability_chain_status.json` edit was performed.

Current result:

`v1_computer_use_acceptance_failed_pending_fix_or_owner_decision`

Reason: packaged release app launch and visible page navigation passed, but the actual NSIS installer wizard was not executed and the packaged desktop shell did not expose an Agent new-assistant failure-state entry for automated verification.

## Baseline

| Item | Value |
| --- | --- |
| HEAD | `99a5a29 docs: record v1 package gate result evidence` |
| Worktree | `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui-v1-clean-reconstruction` |
| Pre-run `git status --short` | `?? reports/V1_FINAL_OWNER_REVIEW_PREPARATION_PACK.md` |
| Automation target | Package Gate artifact and packaged release app |

## Installer Artifact

| Item | Value |
| --- | --- |
| EXE path | `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui-v1-clean-reconstruction\desktop\tauri\src-tauri\target\release\bundle\nsis\HeiTang KB Forge Desktop_1.2.3_x64-setup.exe` |
| Size | `1992001` bytes |
| Modified time | `2026-06-29T22:55:01.4107136+08:00` |
| SHA256 | `A329BE28F3949469EEDC2F9CA128F89FBA9FF9C43A415A23D5F3B33882E92148` |
| Existence check | pass |

Installer wizard execution:

- Status: `needs_owner_check`
- Reason: automated run used the packaged release executable for startup/UI verification and did not perform an installer wizard flow. No UAC, security, or installer confirmation prompt was bypassed.

## Launch And Window State

Packaged release executable launched:

```text
desktop\tauri\src-tauri\target\release\heitang-kb-forge-desktop.exe
```

| Check | Result |
| --- | --- |
| Window opened | pass |
| Window title | `HeiTang KB Forge Desktop` |
| White screen | not observed |
| Black screen | not observed |
| Crash during navigation | not observed |
| Close app | pass; packaged app window no longer listed after `Alt+F4` |

## Screenshot Evidence

Screenshot directory:

```text
output/v1_computer_use_acceptance/screenshots/
```

| Page / state | Result | Screenshot |
| --- | --- | --- |
| Initial settings | pass | `output/v1_computer_use_acceptance/screenshots/00_initial_settings.png` |
| Home / Dashboard | pass | `output/v1_computer_use_acceptance/screenshots/01_home.png` |
| New knowledge package | pass | `output/v1_computer_use_acceptance/screenshots/02_new_package.png` |
| Batch processing | pass | `output/v1_computer_use_acceptance/screenshots/03_batch.png` |
| Workspace | pass | `output/v1_computer_use_acceptance/screenshots/04_workspace.png` |
| Update and incremental | pass | `output/v1_computer_use_acceptance/screenshots/05_update_incremental.png` |
| Quality and acceptance | pass | `output/v1_computer_use_acceptance/screenshots/06_quality_acceptance.png` |
| Knowledge package detail | pass | `output/v1_computer_use_acceptance/screenshots/07_package_detail.png` |
| Q&A test | pass | `output/v1_computer_use_acceptance/screenshots/08_qa_test.png` |
| Publish/export | pass | `output/v1_computer_use_acceptance/screenshots/09_publish_export.png` |
| Planning readiness | pass | `output/v1_computer_use_acceptance/screenshots/10_planning.png` |
| Desktop settings | pass | `output/v1_computer_use_acceptance/screenshots/11_settings.png` |

## Acceptance Items

| Item | Status | Evidence / note |
| --- | --- | --- |
| Installer exists | pass | EXE path, size, timestamp, SHA256 recorded |
| Installed-app startup | needs_owner_check | Installer wizard not executed by automation |
| Packaged release app startup | pass | `HeiTang KB Forge Desktop` window opened |
| White/black screen check | pass | not observed across captured pages |
| Main page / Dashboard | pass | `01_home.png` |
| Data import / document library equivalent | pass | `02_new_package.png`; packaged shell exposes `新建知识包` rather than a separate document library entry |
| Knowledge base entry | pass | `07_package_detail.png`; packaged shell exposes knowledge package detail/workspace-oriented KB surfaces |
| Artifact / results entry | pass | `09_publish_export.png`; export artifacts listed |
| Skill entry | needs_owner_check | packaged shell branding says Skill local desktop shell, but no separate Skill Builder page was exposed in this package UI |
| Agent entry | needs_owner_check | no separate Agent page or new-assistant control was exposed in the packaged shell navigation |
| Settings entry | pass | `11_settings.png` |
| Task workbench | needs_owner_check | no separate task workbench entry was exposed in the packaged shell navigation |
| Agent missing model-service prompt | needs_owner_check | not automatable in this packaged shell because Agent/new-assistant entry was not exposed |
| Basic navigation | pass | 11 visible nav entries opened without crash |
| Empty state readability | pass | workspace/detail/Q&A/planning empty or unloaded states were readable |
| Close application | pass | app window closed and was no longer listed |

## Internal Error Term Scan

Visible accessibility text across captured pages was scanned for:

```text
Provider, Adapter, stack trace, StackTrace, exception, Exception, internal exception, raw exception, null
```

Result:

```text
pass; no forbidden internal error terms observed in captured page text
```

Note: this does not cover the untested Agent failure-state path in the packaged shell.

## State And Claims Checks

`capability_chain_status.json` diff:

```text
empty
```

Ready-claim scan:

```text
clean; no positive claim found in product code, tests, or capability_chain_status.json.
reports/docs matches are non-claim only: forbidden terms, scan commands, DeepSeek enums, or negative/authorization-gated statements.
```

## Non-Executed Actions

The following were not performed:

- push
- tag/release
- Final Owner Review
- build/package rerun
- product-code edit
- `capability_chain_status.json` edit
- historical evidence cleanup

## Owner Spot-Check List

Owner should manually check:

1. Run the NSIS installer wizard and confirm installation behavior.
2. Launch the installed app from the installed location or Start menu entry, if created.
3. Confirm whether this packaged desktop shell is the intended V1.0 Owner Review surface.
4. Confirm whether the absence of separate Agent, Skill Builder, and task workbench entries is acceptable for V1.0 package acceptance.
5. If Agent entry is expected, identify the correct installed app/surface and rerun Agent failure-state automation.
6. Capture Owner screenshots/logs for installer flow and any missing V1.0 page.

## Final State

`v1_computer_use_acceptance_failed_pending_fix_or_owner_decision`

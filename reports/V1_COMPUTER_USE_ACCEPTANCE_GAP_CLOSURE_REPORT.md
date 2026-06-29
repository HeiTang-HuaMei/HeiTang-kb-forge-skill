# V1 Computer Use Acceptance Gap Closure Report

Generated: 2026-06-29 23:44:47 +08:00

## 1. Scope

This report records L0 Computer Use acceptance gap closure evidence only.

Current state before this pass:

`v1_acceptance_and_hardening_master_plan_created_pending_owner_scope_decision`

Scope decision:

- Continue L0 baseline acceptance closure.
- Do not execute L1 Post-Package Hardening Test.
- Do not enter Final Owner Review.
- Do not push, tag, or release.
- Do not modify product code.
- Do not modify `capability_chain_status.json`.
- Do not rebuild or repackage.

Final gap closure state:

`v1_computer_use_acceptance_gap_partially_closed_pending_owner_spot_check`

## 2. Repository State

HEAD:

`99a5a29 docs: record v1 package gate result evidence`

Branch:

`v1-clean-baseline-reconstruction`

Pre-report `git status --short`:

```text
?? output/
?? reports/V1_ACCEPTANCE_AND_HARDENING_MASTER_PLAN.md
?? reports/V1_COMPUTER_USE_ACCEPTANCE_DEEPSEEK_REVIEW_PACKET.md
?? reports/V1_COMPUTER_USE_ACCEPTANCE_REPORT.md
?? reports/V1_FINAL_OWNER_REVIEW_PREPARATION_PACK.md
```

`capability_chain_status.json` diff:

`empty`

No build, package, push, tag, release, or Final Owner Review command was run during this gap closure pass.

## 3. Acceptance Object

NSIS installer:

`desktop/tauri/src-tauri/target/release/bundle/nsis/HeiTang KB Forge Desktop_1.2.3_x64-setup.exe`

Installer metadata:

| Field | Value |
| --- | --- |
| Size | `1992001` bytes |
| Last modified | `2026-06-29 22:55:01 +08:00` |
| SHA256 | `A329BE28F3949469EEDC2F9CA128F89FBA9FF9C43A415A23D5F3B33882E92148` |

Packaged executable used for packaged shell probing:

`desktop/tauri/src-tauri/target/release/heitang-kb-forge-desktop.exe`

Packaged executable metadata:

| Field | Value |
| --- | --- |
| Size | `8401408` bytes |
| Last modified | `2026-06-29 22:55:01 +08:00` |

## 4. Gap A: NSIS Installer Wizard

Goal:

Automate the NSIS installer wizard far enough to verify that the wizard opens and exposes expected installer pages, or classify remaining steps for Owner spot-check.

Result:

`partially_closed_needs_owner_spot_check`

Observed facts:

- The installer process launched.
- A window titled `HeiTang KB Forge Desktop Setup` opened.
- The welcome page was visible and contained `Welcome to HeiTang KB Forge Desktop Setup`.
- The wizard exposed `Next >` and `Cancel`.
- The install-location page was reached by clicking `Next >`.
- The install-location page displayed a destination folder field, `Browse...`, `Space required: 8.0 MB`, and `Space available: 45.1 GB`.
- The wizard was closed with `Cancel` before clicking any install/finish action.
- No UAC, security prompt, or installer completion step was bypassed.

Screenshots:

| Evidence | Path |
| --- | --- |
| Installer welcome page | `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_a_nsis_installer_initial.png` |
| Installer install-location page | `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_a_nsis_installer_second_page.png` |

Owner spot-check still required:

- Confirm the install/finish path manually if full installer completion is required.
- Confirm installed Start Menu/Desktop shortcuts, if those are in Owner acceptance scope.
- Confirm uninstall behavior only if Owner explicitly adds it to scope.

Reason for conservative classification:

The wizard opened and two pages were captured, but this automated pass intentionally did not click through to an installation mutation. That leaves the install completion page and post-install shortcut checks as Owner spot-check items.

## 5. Gap B: Agent Missing-Model Failure State

Goal:

Verify the Agent missing-model failure state from the packaged shell, or classify the gap for Owner spot-check with widget-test evidence reference.

Result:

`partially_closed_needs_owner_spot_check`

Observed packaged shell facts:

- The packaged desktop executable opened a window titled `HeiTang KB Forge Desktop`.
- The visible navigation contained:
  - `首页`
  - `新建知识包`
  - `批量处理`
  - `工作区`
  - `更新与增量`
  - `质量与验收`
  - `知识包详情`
  - `问答测试`
  - `发布导出`
  - `规划准备`
  - `桌面设置`
- No dedicated `Agent` page, `新建助手`, or equivalent assistant creation control was exposed in the packaged shell navigation.
- The `问答测试` page exposed Agent-adjacent reserved controls:
  - `Agent 对接目标`
  - `generic_rag`
  - `mcp_server_future`
  - `对接模式`
  - `export_only`
  - `local_runtime_future`
  - `remote_api_future`
- These controls are reserved or export-oriented and did not expose the Agent new-assistant missing-model failure path in the packaged shell.
- No visible internal error terms were observed in the captured packaged-shell pages.

Screenshots:

| Evidence | Path |
| --- | --- |
| Packaged shell initial state | `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_packaged_shell_initial.png` |
| Q&A / Agent-adjacent page | `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_packaged_shell_qa_test.png` |
| Agent target selector | `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_agent_target_dropdown.png` |
| Agent mode selector | `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_agent_mode_dropdown.png` |

Widget-test evidence reference:

- `reports/V1_UI_CLOSURE_PHASE2_DEEPSEEK_REVIEW_PACKET.md`
- `reports/rc6_blocker_fix_validation_logs/widget_test_after_rc6_fix.log`

Referenced widget-test fact:

`agent creation path explains missing model setup` passed in the widget-test evidence. The DeepSeek review packet records product-facing text such as `请先配置模型服务` and states that internal terms such as Provider, Adapter, stack trace, raw exception, and null were not visible in the Agent text scan.

Owner spot-check still required:

- Confirm whether the packaged shell is expected to expose a dedicated Agent/new-assistant path in V1.0.
- If yes, identify the correct packaged entry and rerun automation against that surface.
- If no, accept widget-test evidence for the Agent missing-model prompt and record packaged-shell Agent path as not exposed in V1.0.

Reason for conservative classification:

The packaged shell exposes Agent-adjacent reserved controls, but it does not expose a direct assistant creation path. Therefore the missing-model failure state could not be fully automated from the packaged shell and remains an Owner spot-check item with widget-test evidence support.

## 6. Internal Error Term Scan

Captured packaged-shell evidence was checked for internal error wording in the relevant Agent-adjacent surfaces.

Terms checked:

- `Provider`
- `Adapter`
- `stack trace`
- `StackTrace`
- `internal exception`
- `raw exception`

Result:

No captured packaged-shell page showed these internal error terms as a user-facing failure state.

Limitation:

This scan covers the captured packaged-shell pages and does not prove the unexposed Agent new-assistant path in the packaged shell.

## 7. Ready-Claim Scan Result

Ready-claim scan classification:

`clean / non-claim only`

Classification detail:

- No current positive readiness status claim was found in `capability_chain_status.json`.
- Existing product code, tests, schemas, and fixtures may contain readiness-related field names or assertions as domain/test vocabulary. Those are classified as `non-claim` unless they assert the current V1 package or Final Owner Review state.
- Reports/docs matches are classified as `non-claim` when they appear in forbidden-term lists, quoted scan commands, DeepSeek output enums, negative statements, or authorization-gated statements.
- This report does not claim package gate completion beyond the already committed Package Gate evidence and does not claim release or Final Owner Review completion.

## 8. Forbidden Actions Check

Not performed:

- L1 Post-Package Hardening Test
- Final Owner Review
- Push
- Tag
- Release
- Product code modification
- `capability_chain_status.json` modification
- Build or package rerun
- Historical evidence cleanup

## 9. Gap Closure Result

Overall result:

`partial`

Final state:

`v1_computer_use_acceptance_gap_partially_closed_pending_owner_spot_check`

Rationale:

- Gap A is partially closed because the NSIS wizard launches and early pages are captured, but install completion was intentionally not automated.
- Gap B is partially closed because packaged-shell Agent-adjacent controls are captured, but the true Agent new-assistant missing-model path is not exposed in the packaged shell. Widget-test evidence exists and should be reviewed by Owner/DeepSeek.

Recommended next step:

DeepSeek should review this gap closure packet, then Owner should decide whether the remaining NSIS install completion and Agent new-assistant checks can be accepted as spot-check items for L0 Final Owner Review preparation.

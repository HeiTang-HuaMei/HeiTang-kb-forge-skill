# V1 Invalidated Acceptance Evidence Report

Generated: 2026-06-30

## 1. Scope

Current state:

`v1_stale_tauri_shell_removed_pending_package_gate_retry_authorization`

Current effective fix commit:

`edc2df1 fix(package): remove stale tauri shell and package flutter v1 ui`

This report records acceptance/preparation evidence that is preserved for audit and RCA only after the Package Gate artifact provenance mismatch was identified.

These files must not be used as V1.0 acceptance pass evidence.

## 2. Evidence Collected In This Commit

Reports:

- `reports/V1_ACCEPTANCE_AND_HARDENING_MASTER_PLAN.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_DEEPSEEK_REVIEW_PACKET.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_GAP_CLOSURE_DEEPSEEK_PACKET.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_GAP_CLOSURE_REPORT.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_REPORT.md`
- `reports/V1_FINAL_OWNER_REVIEW_PREPARATION_PACK.md`
- `reports/V1_INVALIDATED_ACCEPTANCE_EVIDENCE_REPORT.md`

Screenshot evidence:

- `output/v1_computer_use_acceptance/screenshots/00_initial_settings.png`
- `output/v1_computer_use_acceptance/screenshots/01_home.png`
- `output/v1_computer_use_acceptance/screenshots/02_new_package.png`
- `output/v1_computer_use_acceptance/screenshots/03_batch.png`
- `output/v1_computer_use_acceptance/screenshots/04_workspace.png`
- `output/v1_computer_use_acceptance/screenshots/05_update_incremental.png`
- `output/v1_computer_use_acceptance/screenshots/06_quality_acceptance.png`
- `output/v1_computer_use_acceptance/screenshots/07_package_detail.png`
- `output/v1_computer_use_acceptance/screenshots/08_qa_test.png`
- `output/v1_computer_use_acceptance/screenshots/09_publish_export.png`
- `output/v1_computer_use_acceptance/screenshots/10_planning.png`
- `output/v1_computer_use_acceptance/screenshots/11_settings.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_a_nsis_installer_initial.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_a_nsis_installer_second_page.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_packaged_shell_initial.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_packaged_shell_qa_test.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_agent_target_dropdown.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_agent_mode_dropdown.png`

## 3. Why This Evidence Is Invalidated

The old Package Gate artifact was later determined to have an artifact provenance mismatch.

Root cause:

The old Package Gate packaged the stale React/Vite shell from:

`desktop/tauri/src`

It did not package the intended Flutter V1 UI from:

`web/workbench/flutter_app`

Impact:

- Computer Use acceptance evidence targeted the stale Tauri shell artifact.
- Computer Use gap closure evidence also observed the stale Tauri shell artifact.
- Final Owner Review preparation material incorporated evidence from that wrong artifact.
- The evidence remains useful for audit, timeline reconstruction, and RCA, but cannot support V1.0 acceptance pass.

## 4. Provenance RCA And Fix References

RCA report:

`reports/V1_PACKAGE_ARTIFACT_PROVENANCE_RCA_REPORT.md`

RCA conclusion:

`D. package artifact genuinely contains old UI`

Fix report:

`reports/V1_PACKAGE_ARTIFACT_PROVENANCE_FIX_REPORT.md`

Current effective fix commit:

`edc2df1 fix(package): remove stale tauri shell and package flutter v1 ui`

Fix summary:

- Removed stale `desktop/tauri/src/**` React/Vite shell from Tauri package input.
- Rewired Package Gate to build Flutter web from `web/workbench/flutter_app`.
- Rewired Tauri `frontendDist` to `web/workbench/flutter_app/build/web`.

## 5. Audit-Only Use

Allowed use:

- audit trail
- RCA review
- evidence partition review
- comparison against post-fix Package Gate retry evidence
- verifying why old acceptance evidence was invalidated

Not allowed use:

- V1.0 acceptance pass
- Final Owner Review pass
- release/tag decision
- package pass claim
- runtime or production readiness claim

## 6. Required Next Steps

Before any V1.0 acceptance can resume:

1. Owner must authorize a new clean Package Gate retry.
2. Package Gate retry must build `web/workbench/flutter_app` with `flutter build web`.
3. Tauri must package `web/workbench/flutter_app/build/web`.
4. The produced desktop app must be verified to display the current Flutter V1 UI.
5. Computer Use acceptance must be rerun against the verified post-fix artifact.
6. Any Final Owner Review preparation must be regenerated or explicitly amended to reference only post-fix artifact evidence.

## 7. Safety Checks

`capability_chain_status.json` diff:

`empty`

Ready-claim scan result:

`clean / non-claim only`

Classification:

- No positive current-state readiness claim was introduced.
- Existing schema/test/fixture readiness terms remain domain/test vocabulary.
- This report uses readiness terms only as forbidden, invalidated, or negative/gated audit language.

## 8. Actions Not Performed

Not performed in this evidence commit:

- build/package
- Package Gate retry
- push
- tag/release
- Final Owner Review
- product code modification
- `capability_chain_status.json` modification
- evidence deletion

## 9. Completion State

After this evidence commit, expected state:

`v1_invalidated_acceptance_evidence_committed_pending_package_gate_retry_authorization`

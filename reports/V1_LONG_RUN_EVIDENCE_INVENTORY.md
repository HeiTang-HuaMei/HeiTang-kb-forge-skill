# V1 Long-Run Evidence Inventory

Generated: 2026-06-30

## 1. Scope

Current HEAD:

`2daf0c1 docs: recover deepseek edge automation via cdp`

Current state:

`v1_long_run_blocked_by_deepseek_edge_cdp_unavailable`

This inventory reconciles valid V1.0 pass evidence, invalidated audit-only evidence, and decisions that remain Owner-only.

It is partial long-run evidence. DeepSeek Edge Web/CDP final-review automation is blocked, no final-review raw result was captured, and no DeepSeek final-review enum was obtained.

## 2. Valid Pass Evidence

### Package Gate Flutter UI Retry2

Status:

pass

Evidence:

- `reports/V1_PACKAGE_GATE_FLUTTER_UI_RETRY2_RESULT_REPORT.md`
- `reports/V1_PACKAGE_GATE_FLUTTER_UI_RETRY2_DEEPSEEK_PACKET.md`
- `reports/V1_PACKAGE_GATE_FLUTTER_UI_RETRY2_DEEPSEEK_RESULT.md`
- `reports/package_gate_flutter_ui_retry2_logs/`

DeepSeek result:

`PASS_PACKAGE_GATE_FLUTTER_UI_RESULT`

### Computer Use Acceptance Rerun

Status:

pass

Evidence:

- `reports/V1_COMPUTER_USE_ACCEPTANCE_RERUN_REPORT.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_RERUN_DEEPSEEK_PACKET.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_RERUN_DEEPSEEK_RESULT.md`
- `output/v1_computer_use_acceptance_rerun/screenshots/`

DeepSeek result:

`PASS_COMPUTER_USE_ACCEPTANCE_RERUN`

### Artifact Identity

Artifact:

`desktop/tauri/src-tauri/target/release/bundle/nsis/HeiTang KB Forge Desktop_1.2.3_x64-setup.exe`

Size:

`14541425` bytes

SHA256:

`DA01679B48E01AE70159C8A1E22EFB45727679E36A95932CA72E6B606CD0FBC4`

Artifact identity:

valid

### UI Provenance

Current package source:

Flutter V1 UI from `web/workbench/flutter_app/build/web`

Evidence:

- `reports/V1_PACKAGE_GATE_FLUTTER_UI_RETRY2_RESULT_REPORT.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_RERUN_REPORT.md`
- `output/v1_computer_use_acceptance_rerun/screenshots/01_home_task_workbench.png`

Conclusion:

current Flutter V1 UI confirmed.

### Agent Friendly Failure-State

Status:

pass

Evidence:

- `output/v1_computer_use_acceptance_rerun/screenshots/05_nav_agent.png`
- `output/v1_computer_use_acceptance_rerun/screenshots/09_agent_config_or_missing_model_state.png`
- `output/v1_computer_use_acceptance_rerun/screenshots/agent_failure_state_observation.json`

Observed:

- `先创建助手`
- `请先配置模型服务`
- `尚未创建助手`

Internal error exposure:

none observed.

## 3. Invalidated Audit-Only Evidence

The following evidence is retained only for audit and RCA. It must not be used as V1.0 pass evidence.

Evidence:

- `reports/V1_INVALIDATED_ACCEPTANCE_EVIDENCE_REPORT.md`
- `reports/V1_PACKAGE_ARTIFACT_PROVENANCE_RCA_REPORT.md`
- `reports/V1_PACKAGE_ARTIFACT_PROVENANCE_FIX_REPORT.md`
- earlier Computer Use acceptance / gap closure evidence referenced by the invalidation report

Invalidation reason:

The old Package Gate artifact packaged the stale Tauri React/Vite shell from `desktop/tauri/src`, not the intended Flutter V1 UI.

Old artifact classification:

invalidated. The old approximately 1.9 MB artifact must not be used as V1.0 pass evidence.

Old shell status:

invalidated and removed from Tauri package input.

Current effective fix:

`edc2df1 fix(package): remove stale tauri shell and package flutter v1 ui`

## 4. Pending Owner-Only Decisions

The following decisions remain Owner-only:

- Final Owner Review decision
- whether to proceed from preparation to the actual Final Owner Review
- whether to push
- whether to tag
- whether to release

The Owner final decision is not ready until DeepSeek final-review succeeds or Owner explicitly changes that gate.

Allowed Owner final decision template:

- `PASS_FINAL_OWNER_REVIEW`
- `CONDITIONAL_PASS_WITH_FIXES`
- `BLOCK_V1_ACCEPTANCE`

This inventory does not choose any Owner final decision.

## 5. Safety Status

`capability_chain_status.json` diff:

empty

Ready-claim scan:

clean / non-claim only, `claim_like_matches=0`

DeepSeek Edge Web/CDP final-review:

blocked by unavailable Edge DevTools endpoints

DeepSeek final-review enum:

not obtained

No push/tag/release:

confirmed by current workflow evidence.

No Final Owner Review:

confirmed pending.

## 6. Phase 1 Conclusion

Phase 1 result:

partial pass before Phase 4 blocker

Evidence provenance is reconciled:

- valid artifact size and SHA256 match expected values
- old stale-shell evidence is separated as audit-only
- current package uses Flutter V1 UI
- DeepSeek Package Gate PASS exists
- DeepSeek Computer Use PASS exists

Current long-run state:

`v1_long_run_blocked_by_deepseek_edge_cdp_unavailable`

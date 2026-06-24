# Agent P0 EXE Blackbox Lifecycle Report

Generated: 2026-06-24 05:35 +08:00

Updated: 2026-06-24 09:35 +08:00

Edit UX follow-up: 2026-06-24 11:44 +08:00

## Status

single_agent_lifecycle_blackbox_verified_needs_owner_review

global_blackbox_lifecycle_partial_completed

Do not mark `agent_runtime_passed`, `my_assistant_passed`, `industrial_acceptance_passed`, `production_ready`, or `fully_verified`.

## Scope

This pass validated Agent P0 in the real Windows EXE:

- Create assistant
- Edit assistant
- Restart and re-entry persistence
- Single assistant chat with configured LLM environment
- Knowledge base and skill binding visibility/persistence
- Save latest assistant reply to a real artifact
- Homepage recent output linkage
- Activity log writes
- Work group downgrade
- Rebuilt EXE regression for safe fallback copy, persisted conversation reload, disabled work-group entry, and assistant reply artifact preview

This was not a full-product blackbox pass for every module.

## Modified Files

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`
- `web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart`
- `web/workbench/flutter_app/lib/features/dashboard/dashboard_product_workflow.dart`
- `web/workbench/flutter_app/output/agent_runtime_repair/agent_p0_exe_blackbox_matrix.json`
- `docs/audits/current/agent_p0_exe_blackbox_lifecycle_report.md`

The repository already contained many unrelated UI Campaign changes before this pass. They were not reverted.

## Blackbox Evidence

Workspace:

`C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace`

Observed real product-chain artifacts:

- `source_manifest.json`
- `du/document_understanding_manifest.json`
- `kb/manifest.json`
- `query/validation_report.json`
- `doc/generated.md`
- `export/structured/structured_export_manifest.json`
- `skill/knowledge_qa_skill/SKILL.md`
- `agent/catalog/agents.json`
- `agent/conversations/agent_任务总控_1_1782242119205/conversation.json`
- `agent/artifacts/artifact_catalog.json`
- `agent/activity/agent_activity.jsonl`

## Repairs Made During Blackbox

1. Agent LLM endpoint normalization

   `OPENAI_BASE_URL=https://ai-pixel.online/` was being called as `/chat/completions`, which returned HTML. The EXE then fell back to local placeholder reply. The URL builder now routes root endpoints to `/v1/chat/completions` while preserving configured `/v1` or full `/chat/completions` paths.

2. Agent reply artifact status

   Saving a real model reply no longer writes `local_fallback_saved`. Real replies now write `llm_completed_saved` and catalog status `agent_artifacts_recorded`.

3. Assistant config action row

   `保存到成果` was accessible in the tree but clipped behind a full-width `保存配置` button. The config page now displays `保存配置` and `保存到成果` side by side, so both are visibly clickable.

4. Homepage recent output linkage

   Saved Agent reply artifacts now appear first in `最近成果`, and the Hero output count includes Agent artifacts. The EXE showed `7 个成果` and `任务abcdef回复成果` after restart.

5. Homepage output count consistency

   The Work Zone asset card now uses the same output count formula as the Hero. The EXE showed `7 个成果` in both places after restart.

6. Agent fallback copy safety

   Rebuilt EXE regression showed historical `local_fallback` messages no longer expose internal `FormatException` or HTML response fragments in the ordinary user UI. The raw error remains in the activity/conversation evidence for audit.

7. Work group false-availability repair

   The right-side context action now shows a disabled `工作小组暂不可用` state instead of a primary `启动工作小组` button while Work Group is gated.

8. Current assistant output routing

   `打开成果` now prioritizes saved reply artifacts for the selected assistant before falling back to older dialogue/work-group outputs. Rebuilt EXE opened `任务abcdef回复` with `真实模型回复已保存`.

9. Explicit assistant delete entry

   The assistant config page now exposes a visible `删除助手` destructive button instead of hiding the only delete action behind a hard-to-reach single-item overflow menu. The button still uses the same confirmation dialog and `deleteAgentProfile` runtime path.

10. Per-agent conversation directory cleanup

   Owner-authorized deletion first showed that `deleteAgentProfile` removed `conversation.json` but left an empty per-agent conversation directory. The runtime now clears the entire per-agent conversation directory. A rebuilt EXE regression created and deleted `agent_任务总控_2_1782264426746`; both its `conversation.json` and per-agent directory were absent afterward.

11. Assistant edit dirty-state UX

   The assistant config panel now exposes a saved/unsaved status row, disables `保存配置` until editable fields or bindings change, enables `还原` only when unsaved changes exist, and restores the last saved profile without touching disk. The real EXE verified a reversible name edit from `任务abcdef` to `任务abcdefux`, catalog persistence, restart persistence, and a UI save back to the original name.

## Path Results

Path 1 create assistant: blackbox_lifecycle_verified

Path 2 edit assistant: blackbox_lifecycle_verified

The edit persisted and survived restart. Follow-up EXE validation used a reversible lowercase ASCII suffix to avoid the Windows IME noise that affected the previous run:

- Initial config showed `当前配置已保存`, with `保存配置` disabled until a change.
- Editing the assistant name from `任务abcdef` to `任务abcdefux` changed the page to `有未保存更改`.
- Saving wrote `agent/catalog/agents.json`, emitted `update_agent`, and returned the UI to `当前配置已保存`.
- Restarting the EXE restored `任务abcdefux` in the assistant list and config field.
- The suffix was removed through the UI, saved back to `任务abcdef`, and verified in `agents.json`.

Evidence screenshots:

- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_unsaved_suffix_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_saved_suffix_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_restart_suffix_persisted_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_restored_original_after_save_1266x713.png`

Path 3 delete assistant: blackbox_lifecycle_verified

The latest rebuilt EXE now reaches the real `删除助手？` confirmation dialog from assistant config. Evidence screenshots:

`web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_delete_assistant_confirmation_opened_1266x713.png`

`web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_delete_assistant_confirmation_latest_rebuild_1266x713.png`

After owner confirmation, the EXE deleted `agent_任务总控_2_1782251029988`; `agents.json` no longer contained that id and `agent_activity.jsonl` contained `delete_agent`. That first run exposed an empty per-agent conversation directory residue, so the runtime was repaired to clear the directory rather than only `conversation.json`.

Rebuilt EXE regression:

- Created disposable assistant: `agent_任务总控_2_1782264426746`
- Deleted it through the real EXE confirmation flow
- Verified `agents.json` no longer contained `agent_任务总控_2_1782264426746`
- Verified `agent/conversations/agent_任务总控_2_1782264426746` did not exist
- Verified `agent_activity.jsonl` contained `delete_agent`
- Restarted EXE and verified only `任务abcdef` remained visible

Path 4 single assistant chat: blackbox_lifecycle_verified

First send exposed the endpoint bug and saved `local_fallback`. After repair, the second reply was saved with:

- message: `assistant_0004_1782242933427`
- status: `llm_completed`
- provider_kind: `openai_compatible`

Rebuilt EXE regression confirmed the persisted conversation reloads after restart and the older fallback message is displayed as a safe local-placeholder state instead of leaking internal exception text.

Path 5 bind knowledge base / skill: blackbox_lifecycle_verified

The assistant catalog persisted:

- knowledge bases: `K1`, `K2`, `K3`, `K4`
- skill: `primary_skill`

Path 6 save to output: blackbox_lifecycle_verified

Saved markdown:

`agent/artifacts/agent_任务总控_1_1782242119205-assistant_0004_1782242933427.md`

Catalog:

`agent/artifacts/artifact_catalog.json`

Rebuilt EXE regression confirmed `打开成果` opens the selected assistant reply markdown, not the older work-group notes.

Path 7 activity records: partial

The activity file contains real events for create, update, send, and save. Dashboard recent activity still summarizes assistant activity coarsely rather than showing the full event stream.

Path 8 work group downgrade: blackbox_lifecycle_verified

The Work Group tab shows temporarily unavailable/degraded copy and a disabled start button. The rebuilt EXE also shows the right-side context action as disabled `工作小组暂不可用`.

Additional artifact center check: blackbox_lifecycle_verified

From the Homepage `查看成果` action, the EXE opened `全部成果`. The page showed real runtime output counts and included `任务abcdef回复成果` in the artifact list, confirming the saved Agent markdown is visible beyond the Homepage recent-output card.

Additional document library check: partial

The Document Library page restored real imported state from disk: `12 已导入`, `435 片段`, and the real input path `D:\HeiTang-Codex-WorkSpace\input`. Add/delete document lifecycle was not executed in this pass.

Additional knowledge base check: partial

The Knowledge Base page restored real output state: `6` selected sources, `435` local chunks, generated quality report, and internal tabs `概览 / 来源 / 验证 / 引用 / 缺口`. Regeneration/deletion lifecycle was not executed in this pass.

## Matrix

`web/workbench/flutter_app/output/agent_runtime_repair/agent_p0_exe_blackbox_matrix.json`

## Validation Commands

`dart format ...`

Result: passed

`flutter analyze`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_analyze_global_blackbox_repair7.log`

`flutter build windows`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_build_windows_global_blackbox_repair7.log`

`dart format web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/dart_format_agent_delete_button.log`

`flutter build windows`

Result: passed after exposing the explicit delete button

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_build_windows_agent_delete_button.log`

Follow-up validation after replacing deprecated color opacity API:

`dart format web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/dart_format_agent_delete_button_fix.log`

`flutter analyze`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_analyze_agent_delete_button_fix.log`

`flutter build windows`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_build_windows_agent_delete_button_fix.log`

`dart format web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/dart_format_agent_delete_dir_fix.log`

`flutter analyze`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_analyze_agent_delete_dir_fix.log`

`flutter build windows`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_build_windows_agent_delete_dir_fix.log`

Final validation after the owner-authorized delete regression:

`dart format web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/dart_format_agent_p0_final.log`

`flutter analyze`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_analyze_agent_p0_final.log`

`flutter build windows`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_build_windows_agent_p0_final.log`

`git diff --check`

Result: exit code 0, with line-ending warnings only.

Log:

`web/workbench/flutter_app/output/capability_reality/git_diff_check_agent_p0_final.log`

`flutter test test/campaign6_agent_runtime_status_test.dart`

Result: `test_harness_infrastructure_blocked`

Reason: WebSocket listener failed with HTTP 502 before the suite loaded.

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_test_campaign6_agent_runtime_status_final.log`

`git diff --check`

Result: exit code 0, with line-ending warnings only.

Log:

`web/workbench/flutter_app/output/capability_reality/git_diff_check_agent_delete_button_fix.log`

`git diff --check`

Result: exit code 0, with line-ending warnings only.

Log:

`web/workbench/flutter_app/output/capability_reality/git_diff_check_global_blackbox_repair7.log`

`flutter test test/campaign6_agent_runtime_status_test.dart`

Result: `test_harness_infrastructure_blocked`

Reason: WebSocket listener failed with HTTP 502 before the suite loaded.

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_test_campaign6_agent_runtime_status_repair7.log`

Edit UX follow-up validation:

`dart format web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/dart_format_agent_edit_ux_followup.log`

`flutter analyze`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_analyze_agent_edit_ux_followup.log`

`flutter build windows`

Result: passed

Log:

`web/workbench/flutter_app/output/capability_reality/flutter_build_windows_agent_edit_ux_followup.log`

`git diff --check`

Result: exit code 0, with line-ending warnings only.

Log:

`web/workbench/flutter_app/output/capability_reality/git_diff_check_agent_edit_ux_followup.log`

## Rebuilt EXE Screenshots

- `web/workbench/flutter_app/output/global_blackbox_lifecycle/screenshots/rebuilt_exe_agent_after_restart_1266x713.png`
- `web/workbench/flutter_app/output/global_blackbox_lifecycle/screenshots/rebuilt_exe_agent_context_drawer_bottom_1266x713.png`
- `web/workbench/flutter_app/output/global_blackbox_lifecycle/screenshots/rebuilt_exe_agent_open_reply_artifact_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_delete_assistant_confirmation_opened_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_delete_assistant_confirmation_latest_rebuild_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_saved_suffix_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_restart_suffix_persisted_1266x713.png`
- `web/workbench/flutter_app/output/agent_runtime_repair/screenshots/agent_edit_ux_restored_original_after_save_1266x713.png`

## Remaining Blockers

- dashboard_recent_activity_is_coarse_not_full_event_stream.
- Historical empty directory residue remains from the pre-fix deletion of `agent_任务总控_2_1782251029988`; the repaired delete path no longer leaves a new per-agent conversation directory.
- Full-product blackbox lifecycle remains incomplete. Other modules still need their own lifecycle gates.

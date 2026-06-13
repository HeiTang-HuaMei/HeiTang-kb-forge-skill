# Rollback Plan

If the Section 5 item 5.10 implementation or validation fails:

1. Remove only the new `heitang_kb_forge/video_pipeline_schema/` module and its new focused tests.
2. Remove only the new CLI import and the two `video-pipeline-schema` command registrations.
3. Restore story-flicks registry and UI capability status to the previous `template_reference / future_adapter` values.
4. Remove only `artifacts/audits/section_5/story_flicks_video_pipeline_schema/` and its audit index entry.
5. Restore `PLAN_SEQUENCE_LOCK`, `TARGET_ACCEPTANCE_MATRIX`, `CAMPAIGN_STAGE_GATE_POLICY`, and `GOAL_ACCEPTANCE_LEDGER` to item 5.10 pending.
6. Re-run the prior Jellyfish Fast Gate and governance focused tests.

This rollback does not touch unrelated project files, existing Campaign 3 evidence, local dependency environments, caches, Git history, tags, or remote state.

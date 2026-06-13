# story-flicks AIGC Video Pipeline Schema Run Summary

- Run ID: `story_flicks_video_pipeline_schema`
- Section: `5.10 story-flicks`
- Status: `passed`
- Decision: `reference_only`
- Integration mode: `aigc_video_pipeline_schema_reference`
- Evidence root: `artifacts/audits/section_5/story_flicks_video_pipeline_schema`

## Evidence

- `video_pipeline_schema/video_pipeline_manifest.json`
- `video_pipeline_schema/video_pipeline_stages.jsonl`
- `video_pipeline_schema/asset_handoff_schema.json`
- `video_pipeline_schema/timeline_schema.json`
- `validation/video_pipeline_validation_report.json`
- `story_flicks_integration_decision_report.json`
- `story_flicks_ui_impact_note.json`

## Boundary

No story-flicks repository clone, external source/content/prompts/scripts/runtime, story-to-video runtime, image/audio/video generation runtime, voice cloning, media rendering, media upload/download, provider execution, or account operation is bundled or executed.

## Next

Campaign 3 remains `in_progress`, Campaign 4 remains blocked, and the next Section 5 item is `5.11 seedance2-skill` only.

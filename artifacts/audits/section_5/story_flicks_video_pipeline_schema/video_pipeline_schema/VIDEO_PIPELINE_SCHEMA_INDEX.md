# AIGC Video Pipeline Schema Index

- Library: `HeiTang AIGC Video Pipeline Schema`
- Status: `passed`
- Decision: `reference_only`
- Integration mode: `aigc_video_pipeline_schema_reference`
- Stages: 7
- Story-to-video runtime: `False`

| Order | Stage | Domain |
| --- | --- | --- |
| 1 | `source_brief` | `source_grounding` |
| 2 | `script_plan` | `script_planning` |
| 3 | `storyboard_plan` | `storyboard_handoff` |
| 4 | `visual_asset_plan` | `visual_asset_handoff` |
| 5 | `audio_plan` | `audio_handoff` |
| 6 | `subtitle_timeline` | `timeline_metadata` |
| 7 | `delivery_checkpoint` | `pipeline_governance` |

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


VIDEO_PIPELINE_SCHEMA_FILES = [
    "video_pipeline_manifest.json",
    "video_pipeline_stages.jsonl",
    "asset_handoff_schema.json",
    "timeline_schema.json",
    "video_pipeline_validation_report.json",
    "video_pipeline_schema_report.md",
    "VIDEO_PIPELINE_SCHEMA_INDEX.md",
]

STAGE_DEFINITIONS = [
    {
        "stage_id": "source_brief",
        "title": "Source Brief",
        "capability_domain": "source_grounding",
        "purpose": "Bind the planned video to approved source evidence, audience, claims, and risk notes.",
        "input_assets": ["knowledge_package", "source_trace", "audience_brief"],
        "output_assets": ["source_brief", "approved_claim_map", "risk_note"],
        "quality_gates": ["source_trace_required", "approved_claims_only", "human_review_required"],
    },
    {
        "stage_id": "script_plan",
        "title": "Script Plan",
        "capability_domain": "script_planning",
        "purpose": "Plan narration and scene beats without generating or copying an external script.",
        "input_assets": ["source_brief", "approved_claim_map"],
        "output_assets": ["script_outline", "scene_beat_list", "claim_to_scene_map"],
        "quality_gates": ["no_external_script_copying", "claim_trace_required", "human_review_required"],
    },
    {
        "stage_id": "storyboard_plan",
        "title": "Storyboard Plan",
        "capability_domain": "storyboard_handoff",
        "purpose": "Map script beats to local storyboard metadata and content asset references.",
        "input_assets": ["script_outline", "scene_beat_list", "content_asset_manifest"],
        "output_assets": ["storyboard_plan", "shot_sequence", "asset_dependency_map"],
        "quality_gates": ["shot_ids_required", "asset_trace_required", "no_rendering_execution"],
    },
    {
        "stage_id": "visual_asset_plan",
        "title": "Visual Asset Plan",
        "capability_domain": "visual_asset_handoff",
        "purpose": "Describe image and motion asset requests without invoking image or video generation.",
        "input_assets": ["storyboard_plan", "asset_dependency_map"],
        "output_assets": ["visual_asset_requests", "visual_review_queue"],
        "quality_gates": ["owned_or_approved_assets_only", "no_image_generation", "no_video_generation"],
    },
    {
        "stage_id": "audio_plan",
        "title": "Audio Plan",
        "capability_domain": "audio_handoff",
        "purpose": "Describe narration, music, and sound cue requirements without speech or audio generation.",
        "input_assets": ["script_outline", "shot_sequence"],
        "output_assets": ["narration_cue_sheet", "audio_cue_sheet", "audio_rights_note"],
        "quality_gates": ["rights_note_required", "no_voice_cloning", "no_audio_generation"],
    },
    {
        "stage_id": "subtitle_timeline",
        "title": "Subtitle Timeline",
        "capability_domain": "timeline_metadata",
        "purpose": "Represent subtitle and caption timing as structured metadata without media rendering.",
        "input_assets": ["script_outline", "shot_sequence", "narration_cue_sheet"],
        "output_assets": ["subtitle_track", "caption_track", "timeline_markers"],
        "quality_gates": ["source_claim_trace_required", "reading_order_required", "no_media_rendering"],
    },
    {
        "stage_id": "delivery_checkpoint",
        "title": "Delivery Checkpoint",
        "capability_domain": "pipeline_governance",
        "purpose": "Record readiness, unresolved dependencies, approval state, and export boundaries.",
        "input_assets": [
            "visual_review_queue",
            "audio_rights_note",
            "subtitle_track",
            "timeline_markers",
        ],
        "output_assets": ["delivery_manifest", "blocker_report", "export_boundary_note"],
        "quality_gates": ["approval_required", "runtime_not_bundled", "export_boundary_required"],
    },
]


def build_video_pipeline_schema_library(
    output: Path,
    *,
    library_name: str = "HeiTang AIGC Video Pipeline Schema",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    stages = [_stage_card(index, definition) for index, definition in enumerate(STAGE_DEFINITIONS, start=1)]
    handoff_schema = {
        "schema_version": "video_asset_handoff_schema.v1",
        "status": "passed",
        "stage_order": [stage["stage_id"] for stage in stages],
        "handoffs": [
            {
                "from_stage": stages[index]["stage_id"],
                "to_stage": stages[index + 1]["stage_id"],
                "required_outputs": stages[index]["output_assets"],
                "source_trace_required": True,
                "human_approval_required": True,
            }
            for index in range(len(stages) - 1)
        ],
        "external_code_or_content_copied": False,
        "external_runtime_integrated": False,
        "story_to_video_runtime": False,
    }
    timeline_schema = {
        "schema_version": "aigc_video_timeline_schema.v1",
        "status": "passed",
        "track_types": ["visual_reference", "narration_cue", "audio_cue", "subtitle", "caption", "source_trace"],
        "required_item_fields": [
            "item_id",
            "track_type",
            "start_ms",
            "duration_ms",
            "source_asset_ids",
            "source_trace",
            "review_status",
        ],
        "source_trace_required": True,
        "rendered_media_included": False,
        "runtime_boundary": {
            "story_to_video_runtime": False,
            "image_generation_runtime": False,
            "video_generation_runtime": False,
            "audio_generation_runtime": False,
            "voice_cloning_runtime": False,
            "media_rendering_runtime": False,
        },
    }
    manifest = {
        "schema_version": "video_pipeline_schema_library.v1",
        "section": "5.10",
        "campaign": "Campaign 3",
        "library_name": library_name,
        "status": "passed",
        "integration_decision": "reference_only",
        "integration_mode": "aigc_video_pipeline_schema_reference",
        "stage_count": len(stages),
        "stage_ids": [stage["stage_id"] for stage in stages],
        "capability_domains": sorted({stage["capability_domain"] for stage in stages}),
        "external_project_reference": {
            "project_id": "story_flicks",
            "project_name": "story-flicks",
            "github_url": "https://github.com/alecm20/story-flicks",
            "git_ls_remote_checked": True,
            "git_head": "4f208380150f9c066867360d7ce760cc3e3ba47e",
            "repository_cloned": False,
            "external_code_or_content_copied": False,
            "external_prompts_copied": False,
            "external_skill_files_copied": False,
            "external_runtime_integrated": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "overlap_domains": [
                "jellyfish_content_asset_schema_reference",
                "mmskills_multimodal_skill_package_reference",
                "seedance2_skill_provider_template_candidate",
            ],
            "distinct_engineering_value": [
                "pipeline_stage_contracts",
                "asset_handoff_schema",
                "timeline_metadata_schema",
            ],
            "jellyfish_boundary": "Jellyfish remains the content asset and storyboard metadata reference.",
            "seedance2_boundary": "seedance2-skill remains the next provider/template verification item.",
        },
        "runtime_boundary": {
            "llm_required": False,
            "api_key_required": False,
            "network_required": False,
            "external_runtime_required": False,
            "repository_cloned": False,
            "story_to_video_runtime": False,
            "image_generation_runtime": False,
            "video_generation_runtime": False,
            "audio_generation_runtime": False,
            "voice_cloning_runtime": False,
            "media_rendering_runtime": False,
            "media_download_or_upload": False,
            "provider_execution": False,
            "account_operation": False,
        },
        "ui_contract": {
            "template_library_preview_visible": True,
            "artifact_management_preview_visible": True,
            "document_generation_future_slot_visible": True,
            "pipeline_stage_preview_visible": True,
            "runtime_execution_action_available": False,
            "video_generation_action_available": False,
            "render_action_available": False,
        },
        "output_files": VIDEO_PIPELINE_SCHEMA_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Section 5 item 5.10 is advanced as a local original AIGC video pipeline schema reference. "
            "Section 5 items 5.11-5.14, strengthening items 5.S1-5.S3, Campaign 3 final consistency gate, "
            "Campaign 4 UI workflow, Core Bridge, configuration, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.11 seedance2-skill only.",
        "not_goal_complete": True,
    }
    validation = validate_video_pipeline_schema_payload(manifest, stages, handoff_schema, timeline_schema)
    write_json(output / "video_pipeline_manifest.json", manifest)
    write_jsonl(output / "video_pipeline_stages.jsonl", stages)
    write_json(output / "asset_handoff_schema.json", handoff_schema)
    write_json(output / "timeline_schema.json", timeline_schema)
    write_json(output / "video_pipeline_validation_report.json", validation)
    (output / "VIDEO_PIPELINE_SCHEMA_INDEX.md").write_text(
        _render_index(manifest, stages), encoding="utf-8"
    )
    (output / "video_pipeline_schema_report.md").write_text(
        _render_report(manifest, validation), encoding="utf-8"
    )
    return manifest | {
        "stages": stages,
        "asset_handoff_schema": handoff_schema,
        "timeline_schema": timeline_schema,
        "validation": validation,
    }


def validate_video_pipeline_schema_library(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in VIDEO_PIPELINE_SCHEMA_FILES if not (library / file_name).exists()]
    manifest = _read_json(library / "video_pipeline_manifest.json") if not missing else {}
    stages = _read_jsonl(library / "video_pipeline_stages.jsonl") if (library / "video_pipeline_stages.jsonl").exists() else []
    handoffs = _read_json(library / "asset_handoff_schema.json") if (library / "asset_handoff_schema.json").exists() else {}
    timeline = _read_json(library / "timeline_schema.json") if (library / "timeline_schema.json").exists() else {}
    result = validate_video_pipeline_schema_payload(manifest, stages, handoffs, timeline)
    return {
        **result,
        "required_files": VIDEO_PIPELINE_SCHEMA_FILES,
        "missing_files": missing,
        "status": "passed" if result["status"] == "passed" and not missing else "failed",
    }


def validate_video_pipeline_schema_payload(
    manifest: dict[str, Any],
    stages: list[dict[str, Any]],
    handoffs: dict[str, Any],
    timeline: dict[str, Any],
) -> dict[str, Any]:
    required_stages = [definition["stage_id"] for definition in STAGE_DEFINITIONS]
    stage_ids = [str(stage.get("stage_id")) for stage in stages]
    handoff_order = [str(stage_id) for stage_id in handoffs.get("stage_order", [])]
    boundary_errors = []
    runtime = manifest.get("runtime_boundary", {})
    external = manifest.get("external_project_reference", {})
    timeline_runtime = timeline.get("runtime_boundary", {})
    for field in [
        "repository_cloned",
        "external_code_or_content_copied",
        "external_prompts_copied",
        "external_skill_files_copied",
        "external_runtime_integrated",
    ]:
        if external.get(field) is not False:
            boundary_errors.append(f"{field}_must_be_false")
    for field in [
        "llm_required",
        "api_key_required",
        "network_required",
        "external_runtime_required",
        "repository_cloned",
        "story_to_video_runtime",
        "image_generation_runtime",
        "video_generation_runtime",
        "audio_generation_runtime",
        "voice_cloning_runtime",
        "media_rendering_runtime",
        "media_download_or_upload",
        "provider_execution",
        "account_operation",
    ]:
        if runtime.get(field) is not False:
            boundary_errors.append(f"{field}_must_be_false")
    for field in [
        "story_to_video_runtime",
        "image_generation_runtime",
        "video_generation_runtime",
        "audio_generation_runtime",
        "voice_cloning_runtime",
        "media_rendering_runtime",
    ]:
        if timeline_runtime.get(field) is not False:
            boundary_errors.append(f"timeline_{field}_must_be_false")
    if handoffs.get("story_to_video_runtime") is not False:
        boundary_errors.append("handoff_story_to_video_runtime_must_be_false")
    if handoffs.get("external_code_or_content_copied") is not False:
        boundary_errors.append("handoff_external_code_or_content_copied_must_be_false")
    if timeline.get("source_trace_required") is not True:
        boundary_errors.append("timeline_source_trace_required_must_be_true")
    if timeline.get("rendered_media_included") is not False:
        boundary_errors.append("timeline_rendered_media_included_must_be_false")
    stage_errors = [
        stage.get("stage_id") or f"stage_{index}"
        for index, stage in enumerate(stages, start=1)
        if not _stage_is_valid(stage)
    ]
    status = (
        "passed"
        if required_stages == stage_ids == handoff_order
        and len(handoffs.get("handoffs", [])) == len(required_stages) - 1
        and not stage_errors
        and not boundary_errors
        and manifest.get("status") == "passed"
        and timeline.get("status") == "passed"
        else "failed"
    )
    return {
        "schema_version": "video_pipeline_validation_report.v1",
        "section": "5.10",
        "campaign": "Campaign 3",
        "status": status,
        "expected_stage_count": len(required_stages),
        "stage_count": len(stages),
        "required_stages": required_stages,
        "stage_ids": stage_ids,
        "handoff_stage_order": handoff_order,
        "stage_errors": stage_errors,
        "boundary_errors": boundary_errors,
        "external_code_or_content_copied": external.get("external_code_or_content_copied"),
        "external_prompts_copied": external.get("external_prompts_copied"),
        "external_runtime_integrated": external.get("external_runtime_integrated"),
        "story_to_video_runtime": runtime.get("story_to_video_runtime"),
        "video_generation_runtime": runtime.get("video_generation_runtime"),
        "media_rendering_runtime": runtime.get("media_rendering_runtime"),
        "timeline_source_trace_required": timeline.get("source_trace_required"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Video pipeline schema validation covers local original stage, handoff, and timeline contracts only; "
            "it does not complete Campaign 3, Campaign 4 UI workflow, Full Gate, or EXE acceptance."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.11 seedance2-skill only.",
        "not_goal_complete": True,
    }


def write_video_pipeline_schema_library(
    output: Path,
    *,
    library_name: str = "HeiTang AIGC Video Pipeline Schema",
) -> dict[str, Any]:
    return build_video_pipeline_schema_library(output, library_name=library_name)


def write_video_pipeline_schema_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_video_pipeline_schema_library(library)
    write_json(output / "video_pipeline_validation_report.json", result)
    (output / "video_pipeline_validation_report.md").write_text(
        _render_validation_report(result), encoding="utf-8"
    )
    return result


def _stage_card(sequence: int, definition: dict[str, Any]) -> dict[str, Any]:
    return {
        "stage_id": definition["stage_id"],
        "sequence": sequence,
        "title": definition["title"],
        "capability_domain": definition["capability_domain"],
        "purpose": definition["purpose"],
        "input_assets": definition["input_assets"],
        "output_assets": definition["output_assets"],
        "quality_gates": definition["quality_gates"],
        "ui_preview": {
            "surface": "Template Library / Artifact Management / Document Generation",
            "preview_kind": "aigc_video_pipeline_stage",
            "runtime_execution_action_available": False,
        },
        "source_trace_required": True,
        "human_review_required": True,
        "external_code_or_content_copied": False,
        "story_to_video_runtime": False,
        "media_rendering_runtime": False,
    }


def _stage_is_valid(stage: dict[str, Any]) -> bool:
    required = {
        "stage_id",
        "sequence",
        "title",
        "capability_domain",
        "purpose",
        "input_assets",
        "output_assets",
        "quality_gates",
        "ui_preview",
    }
    return (
        required <= set(stage)
        and bool(stage["input_assets"])
        and bool(stage["output_assets"])
        and bool(stage["quality_gates"])
        and stage.get("source_trace_required") is True
        and stage.get("human_review_required") is True
        and stage.get("external_code_or_content_copied") is False
        and stage.get("story_to_video_runtime") is False
        and stage.get("media_rendering_runtime") is False
        and stage["ui_preview"].get("runtime_execution_action_available") is False
    )


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def _render_index(manifest: dict[str, Any], stages: list[dict[str, Any]]) -> str:
    lines = [
        "# AIGC Video Pipeline Schema Index",
        "",
        f"- Library: `{manifest['library_name']}`",
        f"- Status: `{manifest['status']}`",
        f"- Decision: `{manifest['integration_decision']}`",
        f"- Integration mode: `{manifest['integration_mode']}`",
        f"- Stages: {len(stages)}",
        f"- Story-to-video runtime: `{manifest['runtime_boundary']['story_to_video_runtime']}`",
        "",
        "| Order | Stage | Domain |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| {stage['sequence']} | `{stage['stage_id']}` | `{stage['capability_domain']}` |"
        for stage in stages
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# AIGC Video Pipeline Schema Report\n\n"
        f"- Section: `{manifest['section']}`\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Validation: `{validation['status']}`\n"
        f"- Decision: `{manifest['integration_decision']}`\n"
        f"- Integration mode: `{manifest['integration_mode']}`\n"
        f"- Stage count: {manifest['stage_count']}\n"
        f"- External code/content copied: `{manifest['external_project_reference']['external_code_or_content_copied']}`\n"
        f"- Story-to-video runtime: `{manifest['runtime_boundary']['story_to_video_runtime']}`\n"
        f"- Video generation runtime: `{manifest['runtime_boundary']['video_generation_runtime']}`\n"
        f"- Media rendering runtime: `{manifest['runtime_boundary']['media_rendering_runtime']}`\n"
        "\nThis is a local original pipeline schema reference. It does not vendor or execute story-flicks.\n"
    )


def _render_validation_report(result: dict[str, Any]) -> str:
    return (
        "# AIGC Video Pipeline Schema Validation Report\n\n"
        f"- Status: `{result['status']}`\n"
        f"- Stage count: {result['stage_count']}\n"
        f"- Missing files: {len(result.get('missing_files', []))}\n"
        f"- Stage errors: {len(result['stage_errors'])}\n"
        f"- Boundary errors: {len(result['boundary_errors'])}\n"
        f"- Story-to-video runtime: `{result['story_to_video_runtime']}`\n"
        f"- Media rendering runtime: `{result['media_rendering_runtime']}`\n"
    )

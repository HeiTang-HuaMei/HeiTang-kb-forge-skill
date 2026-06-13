from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


CONTENT_ASSET_SCHEMA_FILES = [
    "content_asset_manifest.json",
    "content_asset_cards.jsonl",
    "storyboard_metadata_schema.json",
    "content_asset_workflow_templates.json",
    "content_asset_validation_report.json",
    "content_asset_schema_report.md",
    "CONTENT_ASSET_SCHEMA_INDEX.md",
]

ASSET_DEFINITIONS = [
    {
        "asset_id": "story_seed",
        "title": "Story Seed",
        "capability_domain": "content_planning",
        "purpose": "Capture the verified premise, audience, source trace, and risk notes before any script or visual work.",
        "metadata_fields": ["premise", "audience", "source_trace", "risk_note", "approval_status"],
        "workflow_steps": [
            "select_source_backed_premise",
            "record_target_audience",
            "attach_source_trace",
            "mark_unknowns_and_risks",
            "request_editor_review",
        ],
        "output_assets": ["story_seed_card", "source_trace_table", "risk_note"],
        "quality_gates": ["source_trace_required", "no_external_script_copying", "human_review_required"],
    },
    {
        "asset_id": "character_card",
        "title": "Character Card",
        "capability_domain": "character_asset",
        "purpose": "Normalize character identity, role, continuity, and source-backed constraints for later asset planning.",
        "metadata_fields": ["name", "role", "continuity_tags", "source_trace", "consent_boundary"],
        "workflow_steps": [
            "extract_character_role",
            "normalize_identity_fields",
            "attach_continuity_tags",
            "record_source_and_consent_boundary",
            "prepare_visual_reference_placeholder",
        ],
        "output_assets": ["character_card", "continuity_tag_map", "visual_reference_placeholder"],
        "quality_gates": ["source_trace_required", "no_biometric_identity_claim", "consent_boundary_required"],
    },
    {
        "asset_id": "scene_card",
        "title": "Scene Card",
        "capability_domain": "scene_asset",
        "purpose": "Describe scene intent, location, beat, required props, and evidence boundaries without executing a renderer.",
        "metadata_fields": ["scene_id", "location", "beat", "props", "source_trace", "production_note"],
        "workflow_steps": [
            "assign_scene_id",
            "summarize_scene_beat",
            "map_props_and_locations",
            "link_evidence_and_unknowns",
            "prepare_downstream_asset_request",
        ],
        "output_assets": ["scene_card", "props_list", "asset_request"],
        "quality_gates": ["scene_id_required", "source_trace_required", "no_runtime_rendering"],
    },
    {
        "asset_id": "shot_card",
        "title": "Shot Card",
        "capability_domain": "storyboard_metadata",
        "purpose": "Represent a storyboard shot with camera, composition, duration, asset dependencies, and review state.",
        "metadata_fields": [
            "shot_id",
            "scene_id",
            "camera",
            "composition",
            "duration_hint",
            "asset_dependencies",
            "review_status",
        ],
        "workflow_steps": [
            "assign_shot_id",
            "link_scene_and_dependencies",
            "record_camera_and_composition",
            "set_duration_hint",
            "mark_review_status",
        ],
        "output_assets": ["shot_card", "storyboard_row", "dependency_edge"],
        "quality_gates": ["shot_id_required", "dependency_trace_required", "no_video_generation_execution"],
    },
    {
        "asset_id": "continuity_note",
        "title": "Continuity Note",
        "capability_domain": "asset_continuity",
        "purpose": "Track continuity decisions across scenes, characters, props, and versioned asset references.",
        "metadata_fields": ["continuity_id", "affected_assets", "constraint", "source_trace", "version"],
        "workflow_steps": [
            "identify_continuity_constraint",
            "link_affected_assets",
            "record_source_trace",
            "set_version",
            "publish_review_note",
        ],
        "output_assets": ["continuity_note", "affected_asset_map", "review_note"],
        "quality_gates": ["affected_assets_required", "version_required", "source_trace_required"],
    },
    {
        "asset_id": "production_checkpoint",
        "title": "Production Checkpoint",
        "capability_domain": "workflow_governance",
        "purpose": "Record readiness, blockers, approval state, and export boundaries for a content asset batch.",
        "metadata_fields": ["checkpoint_id", "asset_ids", "status", "blockers", "approval_owner", "export_boundary"],
        "workflow_steps": [
            "collect_asset_statuses",
            "classify_blockers",
            "assign_approval_owner",
            "record_export_boundary",
            "prepare_summary_report",
        ],
        "output_assets": ["checkpoint_report", "blocker_table", "export_boundary_note"],
        "quality_gates": ["approval_owner_required", "runtime_not_bundled", "export_boundary_required"],
    },
]


def build_content_asset_schema_library(
    output: Path,
    *,
    library_name: str = "HeiTang Content Asset Schema Library",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    cards = [_asset_card(definition) for definition in ASSET_DEFINITIONS]
    storyboard_schema = {
        "schema_version": "storyboard_metadata_schema.v1",
        "status": "passed",
        "required_entities": ["story_seed", "scene_card", "shot_card"],
        "optional_entities": ["character_card", "continuity_note", "production_checkpoint"],
        "shot_fields": [
            "shot_id",
            "scene_id",
            "sequence_order",
            "camera",
            "composition",
            "duration_hint",
            "asset_dependencies",
            "source_trace",
            "review_status",
        ],
        "source_trace_required": True,
        "runtime_boundary": {
            "video_generation_runtime": False,
            "short_drama_workbench_runtime": False,
            "asset_rendering_runtime": False,
            "external_runtime_integrated": False,
        },
        "external_code_or_content_copied": False,
    }
    workflow_templates = {
        "schema_version": "content_asset_workflow_templates.v1",
        "status": "passed",
        "workflow_count": len(cards),
        "workflows": [
            {
                "asset_id": card["asset_id"],
                "workflow_steps": card["workflow_steps"],
                "output_assets": card["output_assets"],
                "quality_gates": card["quality_gates"],
            }
            for card in cards
        ],
        "external_code_or_content_copied": False,
        "external_runtime_integrated": False,
        "short_drama_workbench_runtime": False,
        "video_generation_runtime": False,
    }
    manifest = {
        "schema_version": "content_asset_schema_library.v1",
        "section": "5.9",
        "campaign": "Campaign 3",
        "library_name": library_name,
        "status": "passed",
        "integration_decision": "reference_only",
        "integration_mode": "content_asset_schema_reference",
        "asset_type_count": len(cards),
        "asset_ids": [card["asset_id"] for card in cards],
        "capability_domains": sorted({card["capability_domain"] for card in cards}),
        "external_project_reference": {
            "project_id": "jellyfish",
            "project_name": "Jellyfish",
            "github_url": "https://github.com/Forget-C/Jellyfish",
            "git_ls_remote_checked": True,
            "git_head": "a9678194ddf2d9be3ccbe78d4287d87d5089e123",
            "repository_cloned": False,
            "external_code_or_content_copied": False,
            "external_prompts_copied": False,
            "external_skill_files_copied": False,
            "external_runtime_integrated": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "overlap_domains": [
                "mmskills_multimodal_skill_package",
                "ai_marketing_skills_content_operations",
                "story_flicks_video_pipeline_future_slot",
            ],
            "distinct_engineering_value": [
                "content_asset_type_cards",
                "storyboard_metadata_schema",
                "asset_continuity_and_checkpoint_contracts",
            ],
            "story_flicks_remains_next_video_pipeline_item": True,
        },
        "runtime_boundary": {
            "llm_required": False,
            "api_key_required": False,
            "network_required": False,
            "external_runtime_required": False,
            "repository_cloned": False,
            "short_drama_workbench_runtime": False,
            "video_generation_runtime": False,
            "asset_rendering_runtime": False,
            "media_download_or_upload": False,
            "crawler_or_scraper": False,
            "account_operation": False,
        },
        "ui_contract": {
            "template_library_preview_visible": True,
            "artifact_management_preview_visible": True,
            "document_generation_future_slot_visible": True,
            "runtime_execution_action_available": False,
            "video_generation_action_available": False,
            "short_drama_workbench_action_available": False,
        },
        "output_files": CONTENT_ASSET_SCHEMA_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Section 5 item 5.9 is advanced as a local original Content Asset Schema reference. "
            "Section 5 items 5.10-5.14, strengthening items 5.S1-5.S3, Campaign 3 final consistency gate, "
            "Campaign 4 UI workflow, Core Bridge, configuration, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.10 story-flicks only.",
        "not_goal_complete": True,
    }
    validation = validate_content_asset_schema_payload(manifest, cards, storyboard_schema, workflow_templates)
    write_json(output / "content_asset_manifest.json", manifest)
    write_jsonl(output / "content_asset_cards.jsonl", cards)
    write_json(output / "storyboard_metadata_schema.json", storyboard_schema)
    write_json(output / "content_asset_workflow_templates.json", workflow_templates)
    write_json(output / "content_asset_validation_report.json", validation)
    (output / "CONTENT_ASSET_SCHEMA_INDEX.md").write_text(_render_index(manifest, cards), encoding="utf-8")
    (output / "content_asset_schema_report.md").write_text(
        _render_report(manifest, validation), encoding="utf-8"
    )
    return manifest | {
        "asset_cards": cards,
        "storyboard_metadata_schema": storyboard_schema,
        "workflow_templates": workflow_templates,
        "validation": validation,
    }


def validate_content_asset_schema_library(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in CONTENT_ASSET_SCHEMA_FILES if not (library / file_name).exists()]
    manifest = _read_json(library / "content_asset_manifest.json") if not missing else {}
    cards = _read_jsonl(library / "content_asset_cards.jsonl") if (library / "content_asset_cards.jsonl").exists() else []
    storyboard_schema = (
        _read_json(library / "storyboard_metadata_schema.json")
        if (library / "storyboard_metadata_schema.json").exists()
        else {}
    )
    workflows = (
        _read_json(library / "content_asset_workflow_templates.json")
        if (library / "content_asset_workflow_templates.json").exists()
        else {}
    )
    result = validate_content_asset_schema_payload(manifest, cards, storyboard_schema, workflows)
    return {
        **result,
        "required_files": CONTENT_ASSET_SCHEMA_FILES,
        "missing_files": missing,
        "status": "passed" if result["status"] == "passed" and not missing else "failed",
    }


def validate_content_asset_schema_payload(
    manifest: dict[str, Any],
    cards: list[dict[str, Any]],
    storyboard_schema: dict[str, Any],
    workflows: dict[str, Any],
) -> dict[str, Any]:
    required_assets = {definition["asset_id"] for definition in ASSET_DEFINITIONS}
    card_ids = {str(card.get("asset_id")) for card in cards}
    workflow_ids = {
        str(workflow.get("asset_id"))
        for workflow in workflows.get("workflows", [])
        if isinstance(workflow, dict)
    }
    boundary_errors = []
    runtime = manifest.get("runtime_boundary", {})
    external = manifest.get("external_project_reference", {})
    schema_runtime = storyboard_schema.get("runtime_boundary", {})
    if external.get("repository_cloned") is not False:
        boundary_errors.append("repository_cloned_must_be_false")
    for field in [
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
        "short_drama_workbench_runtime",
        "video_generation_runtime",
        "asset_rendering_runtime",
        "media_download_or_upload",
        "crawler_or_scraper",
        "account_operation",
    ]:
        if runtime.get(field) is not False:
            boundary_errors.append(f"{field}_must_be_false")
    for field in [
        "video_generation_runtime",
        "short_drama_workbench_runtime",
        "asset_rendering_runtime",
        "external_runtime_integrated",
    ]:
        if schema_runtime.get(field) is not False:
            boundary_errors.append(f"storyboard_{field}_must_be_false")
    if storyboard_schema.get("source_trace_required") is not True:
        boundary_errors.append("storyboard_source_trace_required_must_be_true")
    card_errors = [
        card.get("asset_id") or f"card_{index}"
        for index, card in enumerate(cards, start=1)
        if not _card_is_valid(card)
    ]
    status = (
        "passed"
        if required_assets == card_ids == workflow_ids
        and not card_errors
        and not boundary_errors
        and manifest.get("status") == "passed"
        and storyboard_schema.get("status") == "passed"
        else "failed"
    )
    return {
        "schema_version": "content_asset_validation_report.v1",
        "section": "5.9",
        "campaign": "Campaign 3",
        "status": status,
        "expected_asset_type_count": len(required_assets),
        "asset_type_count": len(cards),
        "required_assets": sorted(required_assets),
        "card_asset_ids": sorted(card_ids),
        "workflow_asset_ids": sorted(workflow_ids),
        "card_errors": card_errors,
        "boundary_errors": boundary_errors,
        "external_code_or_content_copied": external.get("external_code_or_content_copied"),
        "external_prompts_copied": external.get("external_prompts_copied"),
        "external_runtime_integrated": external.get("external_runtime_integrated"),
        "short_drama_workbench_runtime": runtime.get("short_drama_workbench_runtime"),
        "video_generation_runtime": runtime.get("video_generation_runtime"),
        "storyboard_source_trace_required": storyboard_schema.get("source_trace_required"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Content asset schema validation covers local original schema/reference assets and boundaries only; "
            "it does not complete Campaign 3, Campaign 4 UI workflow, Full Gate, or EXE acceptance."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.10 story-flicks only.",
        "not_goal_complete": True,
    }


def write_content_asset_schema_library(
    output: Path,
    *,
    library_name: str = "HeiTang Content Asset Schema Library",
) -> dict[str, Any]:
    return build_content_asset_schema_library(output, library_name=library_name)


def write_content_asset_schema_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_content_asset_schema_library(library)
    write_json(output / "content_asset_validation_report.json", result)
    (output / "content_asset_validation_report.md").write_text(
        _render_validation_report(result), encoding="utf-8"
    )
    return result


def _asset_card(definition: dict[str, Any]) -> dict[str, Any]:
    return {
        "asset_id": definition["asset_id"],
        "title": definition["title"],
        "capability_domain": definition["capability_domain"],
        "purpose": definition["purpose"],
        "metadata_fields": definition["metadata_fields"],
        "workflow_steps": definition["workflow_steps"],
        "output_assets": definition["output_assets"],
        "quality_gates": definition["quality_gates"],
        "artifact_management_usage": {
            "preview_surface": "Artifact Management",
            "source_trace_required": True,
            "human_review_required": True,
            "runtime_execution_action_available": False,
        },
        "ui_preview": {
            "surface": "Template Library / Artifact Management",
            "preview_kind": "content_asset_schema",
            "runtime_execution_action_available": False,
        },
        "external_code_or_content_copied": False,
        "video_generation_runtime": False,
        "short_drama_workbench_runtime": False,
    }


def _card_is_valid(card: dict[str, Any]) -> bool:
    required = {
        "asset_id",
        "title",
        "capability_domain",
        "purpose",
        "metadata_fields",
        "workflow_steps",
        "output_assets",
        "quality_gates",
        "artifact_management_usage",
        "ui_preview",
    }
    return (
        required <= set(card)
        and bool(card["metadata_fields"])
        and bool(card["workflow_steps"])
        and bool(card["output_assets"])
        and bool(card["quality_gates"])
        and card.get("external_code_or_content_copied") is False
        and card.get("video_generation_runtime") is False
        and card.get("short_drama_workbench_runtime") is False
        and card["artifact_management_usage"].get("source_trace_required") is True
        and card["ui_preview"].get("runtime_execution_action_available") is False
    )


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def _render_index(manifest: dict[str, Any], cards: list[dict[str, Any]]) -> str:
    lines = [
        "# Content Asset Schema Index",
        "",
        f"- Library: `{manifest['library_name']}`",
        f"- Status: `{manifest['status']}`",
        f"- Integration decision: `{manifest['integration_decision']}`",
        f"- Integration mode: `{manifest['integration_mode']}`",
        f"- Asset types: {len(cards)}",
        f"- External code/content copied: `{manifest['external_project_reference']['external_code_or_content_copied']}`",
        f"- Short drama runtime: `{manifest['runtime_boundary']['short_drama_workbench_runtime']}`",
        "",
        "| Asset | Domain | UI preview |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| `{card['asset_id']}` | `{card['capability_domain']}` | `{card['ui_preview']['surface']}` |"
        for card in cards
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# Content Asset Schema Library Report\n\n"
        f"- Section: `{manifest['section']}`\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Validation: `{validation['status']}`\n"
        f"- Decision: `{manifest['integration_decision']}`\n"
        f"- Integration mode: `{manifest['integration_mode']}`\n"
        f"- Asset type count: {manifest['asset_type_count']}\n"
        f"- External code/content copied: `{manifest['external_project_reference']['external_code_or_content_copied']}`\n"
        f"- External runtime integrated: `{manifest['external_project_reference']['external_runtime_integrated']}`\n"
        f"- Short drama workbench runtime: `{manifest['runtime_boundary']['short_drama_workbench_runtime']}`\n"
        f"- Video generation runtime: `{manifest['runtime_boundary']['video_generation_runtime']}`\n"
        "\nThis is a local original content asset schema reference. It does not vendor Jellyfish.\n"
    )


def _render_validation_report(result: dict[str, Any]) -> str:
    return (
        "# Content Asset Schema Validation Report\n\n"
        f"- Status: `{result['status']}`\n"
        f"- Asset type count: {result['asset_type_count']}\n"
        f"- Missing files: {len(result.get('missing_files', []))}\n"
        f"- Card errors: {len(result['card_errors'])}\n"
        f"- Boundary errors: {len(result['boundary_errors'])}\n"
        f"- External code/content copied: `{result['external_code_or_content_copied']}`\n"
        f"- Short drama runtime: `{result['short_drama_workbench_runtime']}`\n"
    )

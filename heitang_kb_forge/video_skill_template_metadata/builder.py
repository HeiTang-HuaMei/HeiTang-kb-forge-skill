from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


VIDEO_SKILL_TEMPLATE_METADATA_FILES = [
    "video_skill_template_metadata.json",
    "provider_boundary.json",
    "video_skill_template_validation_report.json",
    "video_skill_template_metadata_report.md",
]

REPOSITORY_HEAD = "e06c7c63a766d623004a2807881c30685ce517af"


def build_video_skill_template_metadata(output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    provider_boundary = _provider_boundary()
    metadata = {
        "schema_version": "video_skill_template_metadata.v1",
        "section": "5.11",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "seedance2_skill",
        "project_name": "seedance2-skill",
        "integration_decision": "reference_only",
        "integration_mode": "verified_video_skill_template_metadata",
        "template_kind": "video_generation_prompt_skill_metadata",
        "source_verification": {
            "repository_url": "https://github.com/dexhunter/seedance2-skill",
            "repository_head": REPOSITORY_HEAD,
            "default_branch": "main",
            "repository_accessible": True,
            "repository_archived": False,
            "repository_disabled": False,
            "repository_size_kb": 21,
            "license_spdx": "MIT",
            "license_file": "LICENSE",
            "license_sha": "4e7c4074517ed0f6e9c7c383361877a76353a85b",
            "repository_files_observed": [
                ".gitignore",
                "LICENSE",
                "README-zh.md",
                "README.md",
                "SKILL.md",
                "zh/",
            ],
            "repository_cloned": False,
            "external_code_copied": False,
            "external_prompt_text_copied": False,
            "external_skill_file_copied": False,
        },
        "official_provider_evidence": {
            "provider": "Volcano Engine Ark",
            "official_docs_root": "https://www.volcengine.com/docs/82379",
            "official_documentation_discovered": True,
            "direct_document_access_status": "network_timeout",
            "exact_api_contract_verified": False,
            "pricing_contract_verified": False,
            "api_key_required_for_provider_call": True,
            "network_required_for_provider_call": True,
            "paid_service_boundary": True,
            "provider_call_executed": False,
        },
        "local_metadata_contract": {
            "allowed_fields": [
                "template_id",
                "template_kind",
                "supported_input_modalities",
                "planned_output_kind",
                "provider_requirement",
                "source_reference",
                "license_reference",
                "safety_boundary",
                "human_review_required",
            ],
            "supported_input_modalities": ["text", "image_reference", "video_reference", "audio_reference"],
            "planned_output_kind": "video_generation_request_metadata",
            "prompt_body_included": False,
            "provider_payload_included": False,
            "provider_response_included": False,
            "generated_media_included": False,
            "human_review_required": True,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "overlaps_with": [
                "story_flicks AIGC video pipeline schema reference",
                "MMSkills multimodal Skill package reference",
                "Jellyfish content asset schema reference",
            ],
            "distinct_value": [
                "verified public Skill-template identity and license metadata",
                "explicit Seedance provider/API boundary",
                "non-executable Template Library metadata candidate",
            ],
            "story_flicks_boundary": "story-flicks remains the local pipeline-stage and asset-handoff schema.",
            "mmskills_boundary": "MMSkills remains the multimodal Skill package and preview schema.",
            "jellyfish_boundary": "Jellyfish remains the content-asset and storyboard metadata reference.",
        },
        "ui_contract": {
            "status_visible": True,
            "template_metadata_preview_visible": True,
            "license_visible": True,
            "provider_requirement_visible": True,
            "verification_state": "verified_source_reference_only",
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "provider_config_action_available": False,
            "video_generation_action_available": False,
        },
        "provider_boundary": provider_boundary,
        "output_files": VIDEO_SKILL_TEMPLATE_METADATA_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "The repository identity and MIT license are verified and represented as local metadata only. "
            "No external prompt content, provider adapter, API key flow, paid provider request, generated media, "
            "Campaign 3 acceptance, Campaign 3.0, Campaign 4, Full Gate, EXE, or release is complete."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.12 RAG-Anything only.",
        "not_goal_complete": True,
    }
    validation = validate_video_skill_template_metadata_payload(metadata, provider_boundary)
    write_json(output / "video_skill_template_metadata.json", metadata)
    write_json(output / "provider_boundary.json", provider_boundary)
    write_json(output / "video_skill_template_validation_report.json", validation)
    (output / "video_skill_template_metadata_report.md").write_text(
        _render_report(metadata, validation), encoding="utf-8"
    )
    return metadata | {"validation": validation}


def validate_video_skill_template_metadata(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in VIDEO_SKILL_TEMPLATE_METADATA_FILES
        if not (library / file_name).exists()
    ]
    metadata = _read_json(library / "video_skill_template_metadata.json") if not missing else {}
    provider_boundary = _read_json(library / "provider_boundary.json") if not missing else {}
    result = validate_video_skill_template_metadata_payload(metadata, provider_boundary)
    return {
        **result,
        "required_files": VIDEO_SKILL_TEMPLATE_METADATA_FILES,
        "missing_files": missing,
        "status": "passed" if result["status"] == "passed" and not missing else "failed",
    }


def validate_video_skill_template_metadata_payload(
    metadata: dict[str, Any],
    provider_boundary: dict[str, Any],
) -> dict[str, Any]:
    source = metadata.get("source_verification", {})
    local = metadata.get("local_metadata_contract", {})
    ui = metadata.get("ui_contract", {})
    boundary_errors: list[str] = []
    required_false = {
        "repository_cloned": source,
        "external_code_copied": source,
        "external_prompt_text_copied": source,
        "external_skill_file_copied": source,
        "prompt_body_included": local,
        "provider_payload_included": local,
        "provider_response_included": local,
        "generated_media_included": local,
        "provider_call_executed": provider_boundary,
        "api_key_collected": provider_boundary,
        "credential_persisted": provider_boundary,
        "provider_adapter_integrated": provider_boundary,
        "video_generation_runtime": provider_boundary,
        "media_upload_or_download": provider_boundary,
        "account_operation": provider_boundary,
        "executable_action": ui,
        "provider_config_action_available": ui,
        "video_generation_action_available": ui,
        "ready": ui,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            boundary_errors.append(f"{field}_must_be_false")
    if source.get("repository_accessible") is not True:
        boundary_errors.append("repository_accessible_must_be_true")
    if source.get("license_spdx") != "MIT":
        boundary_errors.append("license_spdx_must_be_mit")
    if metadata.get("integration_decision") != "reference_only":
        boundary_errors.append("integration_decision_must_be_reference_only")
    if metadata.get("integration_mode") != "verified_video_skill_template_metadata":
        boundary_errors.append("integration_mode_invalid")
    if ui.get("verification_state") != "verified_source_reference_only":
        boundary_errors.append("ui_verification_state_invalid")
    if ui.get("local_ready") is not True:
        boundary_errors.append("local_ready_must_be_true")
    status = "passed" if not boundary_errors else "failed"
    return {
        "schema_version": "video_skill_template_validation_report.v1",
        "section": "5.11",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": boundary_errors,
        "repository_head": source.get("repository_head"),
        "license_spdx": source.get("license_spdx"),
        "repository_cloned": source.get("repository_cloned"),
        "external_prompt_text_copied": source.get("external_prompt_text_copied"),
        "provider_call_executed": provider_boundary.get("provider_call_executed"),
        "provider_adapter_integrated": provider_boundary.get("provider_adapter_integrated"),
        "video_generation_runtime": provider_boundary.get("video_generation_runtime"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation proves source/license metadata and negative provider/runtime boundaries only. "
            "It does not prove Seedance provider execution, Campaign 3 acceptance, UI workflow, Full Gate, or EXE."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.12 RAG-Anything only.",
        "not_goal_complete": True,
    }


def write_video_skill_template_metadata(output: Path) -> dict[str, Any]:
    return build_video_skill_template_metadata(output)


def write_video_skill_template_metadata_validation(
    library: Path,
    output: Path,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_video_skill_template_metadata(library)
    write_json(output / "video_skill_template_validation_report.json", result)
    (output / "video_skill_template_validation_report.md").write_text(
        _render_validation_report(result), encoding="utf-8"
    )
    return result


def _provider_boundary() -> dict[str, Any]:
    return {
        "schema_version": "seedance_provider_boundary.v1",
        "provider": "Volcano Engine Ark",
        "official_documentation_discovered": True,
        "direct_document_access_status": "network_timeout",
        "exact_api_contract_verified": False,
        "pricing_contract_verified": False,
        "api_key_required": True,
        "network_required": True,
        "paid_service_boundary": True,
        "provider_call_executed": False,
        "api_key_collected": False,
        "credential_persisted": False,
        "provider_adapter_integrated": False,
        "video_generation_runtime": False,
        "media_upload_or_download": False,
        "account_operation": False,
        "provider_terms_review_complete": False,
        "future_integration_requires": [
            "explicit provider adapter scope",
            "environment-only credential handling",
            "cost and quota controls",
            "provider terms and content-safety review",
            "user-triggered execution",
            "progress and cancellation",
            "generated media provenance",
        ],
    }


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _render_report(metadata: dict[str, Any], validation: dict[str, Any]) -> str:
    source = metadata["source_verification"]
    return "\n".join(
        [
            "# Video Skill Template Metadata Report",
            "",
            f"- Section: `{metadata['section']}`",
            f"- Decision: `{metadata['integration_decision']}`",
            f"- Mode: `{metadata['integration_mode']}`",
            f"- Repository HEAD: `{source['repository_head']}`",
            f"- License: `{source['license_spdx']}`",
            f"- Validation: `{validation['status']}`",
            "- External prompt text copied: `false`",
            "- Provider call executed: `false`",
            "- Video generation runtime: `false`",
            "- UI executable action: `false`",
            "",
            "The local artifact is metadata for a verified reference only. It contains no external prompt body, "
            "provider payload, credential, generated media, or executable provider action.",
            "",
        ]
    )


def _render_validation_report(result: dict[str, Any]) -> str:
    return "\n".join(
        [
            "# Video Skill Template Metadata Validation",
            "",
            f"- Status: `{result['status']}`",
            f"- Boundary errors: `{len(result['boundary_errors'])}`",
            f"- License: `{result['license_spdx']}`",
            f"- Provider call executed: `{str(result['provider_call_executed']).lower()}`",
            f"- Video generation runtime: `{str(result['video_generation_runtime']).lower()}`",
            "",
        ]
    )

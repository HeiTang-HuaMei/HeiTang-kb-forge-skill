from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


EXTERNAL_SOURCE_FRAMEWORK_FILES = [
    "external_source_framework_manifest.json",
    "external_source_state_schema.json",
    "external_source_chunk_schema.json",
    "external_source_trace_schema.json",
    "external_evidence_map_schema.json",
    "external_source_action_registry.json",
    "external_source_safety_boundary.json",
    "external_source_framework_validation_report.json",
    "external_source_framework_report.md",
]

READABILITY_STATES = [
    "public_readable",
    "partial_readable",
    "login_required",
    "auth_required",
    "blocked_by_platform",
    "anti_crawl_detected",
    "paywall_or_permission_required",
    "video_without_transcript",
    "needs_opencli_verification",
    "needs_manual_evidence",
]

AUTH_SESSION_STATES = [
    "auth_required",
    "user_authorized_session",
    "visible_content_readable",
    "visible_content_partial",
    "user_cancelled",
    "session_expired",
    "permission_denied",
    "manual_evidence_required",
]

VERIFICATION_STATES = [
    "verified",
    "partially_verified",
    "unsupported",
    "outdated",
    "conflicting",
    "low_confidence",
    "needs_human_review",
]

CHUNK_TYPES = [
    "text",
    "image_ocr",
    "video_segment",
    "video_keyframe_ocr",
    "table_ocr",
    "layout_block",
    "mixed_multimodal",
]

P0_ACTIONS = [
    "ingest-link",
    "batch-ingest-links",
    "import-bookmarks",
    "extract-links",
    "check-external-source",
    "refresh-external-source",
    "detect-platform-link",
    "preflight-platform-link",
    "search-external-source",
    "verify-external-source",
    "build-external-evidence",
    "import-manual-evidence",
    "build-manual-evidence-map",
]

P1_ACTIONS = [
    "start-authenticated-browser-session",
    "read-visible-browser-source",
    "clear-authenticated-browser-session",
    "transcribe-video-source",
    "extract-video-keyframes",
    "extract-visual-evidence",
    "ocr-source-images",
    "build-multimodal-chunks",
    "build-image-trace",
    "build-timestamp-trace",
    "verify-knowledge-base",
    "verify-answer",
    "verify-claims",
    "generate-correctness-report",
]


def build_external_source_framework(
    output: Path,
    *,
    library_name: str = "HeiTang External Source Memory & Verification Framework",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    state_schema = _state_schema()
    chunk_schema = _chunk_schema()
    trace_schema = _source_trace_schema()
    evidence_schema = _evidence_map_schema()
    action_registry = _action_registry()
    safety_boundary = _safety_boundary()
    manifest = {
        "schema_version": "external_source_framework_manifest.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 External Source Memory & Verification framework",
        "status": "passed",
        "library_name": library_name,
        "integration_decision": "real_integration",
        "decision_qualifier": "framework_only",
        "integration_mode": "external_source_contract_and_registry_framework",
        "p0_scope": [
            "framework_contracts",
            "state_taxonomy",
            "metadata_and_chunk_schema",
            "source_trace_and_evidence_map_schema",
            "action_registry",
            "safety_boundary",
            "progress_and_failure_contracts",
            "ui_and_bridge_contract_placeholders",
        ],
        "not_implemented_in_this_step": [
            "generic_web_url_fetch",
            "platform_content_extraction",
            "opencli_runtime_search",
            "authenticated_browser_runtime",
            "manual_evidence_file_processing",
            "video_transcription",
            "visual_ocr_runtime",
            "knowledge_verification_runtime",
            "campaign_3_3_0_acceptance",
            "campaign_3_4_0_activation",
            "campaign_4_ui_acceptance",
        ],
        "runtime_boundary": _runtime_boundary(),
        "ui_contract": {
            "external_link_import_entry_required": True,
            "truthful_status_required": True,
            "progress_visible_for_long_tasks": True,
            "ui_entry_implemented": False,
            "ui_workflow_accepted": False,
            "ready": False,
            "executable_action": False,
            "campaign_4_ui_acceptance": False,
        },
        "core_bridge_contract": {
            "allowlist_required": True,
            "registered_in_this_step": False,
            "path_validation_required": True,
            "no_arbitrary_shell_execution": True,
            "bridge_execution_accepted": False,
            "campaign_5_bridge_acceptance": False,
        },
        "default_fetch_policy": {
            "url_depth": 0,
            "max_pages": 1,
            "same_domain_only": True,
            "timeout_seconds": 30,
            "respect_robots": True,
            "user_triggered_only": True,
        },
        "state_schema_path": "external_source_state_schema.json",
        "chunk_schema_path": "external_source_chunk_schema.json",
        "source_trace_schema_path": "external_source_trace_schema.json",
        "evidence_map_schema_path": "external_evidence_map_schema.json",
        "action_registry_path": "external_source_action_registry.json",
        "safety_boundary_path": "external_source_safety_boundary.json",
        "output_files": EXTERNAL_SOURCE_FRAMEWORK_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This advances only the Campaign 3 Supplement 3.0 P0 framework. Generic Web URL ingestion, "
            "platform preflight, OpenCLI verification, manual evidence processing, authenticated browser reading, "
            "video/OCR runtime, knowledge verification runtime, UI workflow acceptance, Core Bridge execution acceptance, "
            "Supplement 3.0 acceptance, Supplement 4.0, Campaign 4, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Run Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion only.",
        "not_goal_complete": True,
    }
    validation = validate_external_source_framework_payload(
        manifest,
        state_schema,
        chunk_schema,
        trace_schema,
        evidence_schema,
        action_registry,
        safety_boundary,
    )
    write_json(output / "external_source_framework_manifest.json", manifest)
    write_json(output / "external_source_state_schema.json", state_schema)
    write_json(output / "external_source_chunk_schema.json", chunk_schema)
    write_json(output / "external_source_trace_schema.json", trace_schema)
    write_json(output / "external_evidence_map_schema.json", evidence_schema)
    write_json(output / "external_source_action_registry.json", action_registry)
    write_json(output / "external_source_safety_boundary.json", safety_boundary)
    write_json(output / "external_source_framework_validation_report.json", validation)
    (output / "external_source_framework_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def validate_external_source_framework(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in EXTERNAL_SOURCE_FRAMEWORK_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "external_source_framework_validation_report.v1",
            "section": "5.3.0-P0",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": EXTERNAL_SOURCE_FRAMEWORK_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required external-source framework evidence is incomplete.",
            "next_required_e2e_step": "Complete Campaign 3 Supplement 3.0 P0 framework before advancing.",
            "not_goal_complete": True,
        }
    result = validate_external_source_framework_payload(
        _read_json(library / "external_source_framework_manifest.json"),
        _read_json(library / "external_source_state_schema.json"),
        _read_json(library / "external_source_chunk_schema.json"),
        _read_json(library / "external_source_trace_schema.json"),
        _read_json(library / "external_evidence_map_schema.json"),
        _read_json(library / "external_source_action_registry.json"),
        _read_json(library / "external_source_safety_boundary.json"),
    )
    return {
        **result,
        "required_files": EXTERNAL_SOURCE_FRAMEWORK_FILES,
        "missing_files": missing,
    }


def write_external_source_framework_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_external_source_framework(library)
    write_json(output / "external_source_framework_validation_report.json", result)
    return result


def validate_external_source_framework_payload(
    manifest: dict[str, Any],
    state_schema: dict[str, Any],
    chunk_schema: dict[str, Any],
    trace_schema: dict[str, Any],
    evidence_schema: dict[str, Any],
    action_registry: dict[str, Any],
    safety_boundary: dict[str, Any],
) -> dict[str, Any]:
    runtime = manifest.get("runtime_boundary", {})
    ui = manifest.get("ui_contract", {})
    bridge = manifest.get("core_bridge_contract", {})
    fetch_policy = manifest.get("default_fetch_policy", {})
    errors: list[str] = []
    required_false = {
        "generic_web_url_ingestion_implemented": runtime,
        "platform_extraction_implemented": runtime,
        "opencli_runtime_integrated": runtime,
        "authenticated_browser_runtime_integrated": runtime,
        "manual_evidence_processing_implemented": runtime,
        "video_transcription_implemented": runtime,
        "visual_ocr_runtime_integrated": runtime,
        "knowledge_verification_runtime_implemented": runtime,
        "campaign_3_3_0_accepted": runtime,
        "campaign_3_4_0_active": runtime,
        "campaign_3_accepted": runtime,
        "campaign_4_allowed": runtime,
        "ui_entry_implemented": ui,
        "ui_workflow_accepted": ui,
        "ready": ui,
        "executable_action": ui,
        "registered_in_this_step": bridge,
        "bridge_execution_accepted": bridge,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if manifest.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if manifest.get("decision_qualifier") != "framework_only":
        errors.append("decision_qualifier_must_be_framework_only")
    if runtime.get("framework_contracts_implemented") is not True:
        errors.append("framework_contracts_implemented_must_be_true")
    if set(state_schema.get("readability_states", [])) != set(READABILITY_STATES):
        errors.append("readability_states_mismatch")
    if set(state_schema.get("auth_session_states", [])) != set(AUTH_SESSION_STATES):
        errors.append("auth_session_states_mismatch")
    if set(state_schema.get("verification_states", [])) != set(VERIFICATION_STATES):
        errors.append("verification_states_mismatch")
    if set(chunk_schema.get("chunk_types", [])) != set(CHUNK_TYPES):
        errors.append("chunk_types_mismatch")
    for field in [
        "chunk_id",
        "chunk_type",
        "source_type",
        "source_url",
        "platform",
        "title",
        "author",
        "published_at",
        "retrieved_at",
        "content_hash",
        "text",
        "ocr_text",
        "visual_summary",
        "timestamp_start",
        "timestamp_end",
        "image_index",
        "bbox",
        "backlink",
        "evidence_id",
        "confidence",
    ]:
        if field not in chunk_schema.get("required_fields", []):
            errors.append(f"chunk_schema_missing:{field}")
    if trace_schema.get("source_trace_required") is not True:
        errors.append("source_trace_required")
    if trace_schema.get("timestamp_trace_supported") is not True:
        errors.append("timestamp_trace_supported")
    if trace_schema.get("image_trace_supported") is not True:
        errors.append("image_trace_supported")
    if evidence_schema.get("evidence_map_required") is not True:
        errors.append("evidence_map_required")
    registry_actions = {item["action"] for item in action_registry.get("actions", [])}
    if not set(P0_ACTIONS).issubset(registry_actions):
        errors.append("missing_p0_actions")
    if not set(P1_ACTIONS).issubset(registry_actions):
        errors.append("missing_p1_actions")
    if any(item.get("arbitrary_shell_allowed") is not False for item in action_registry.get("actions", [])):
        errors.append("action_registry_allows_shell")
    if safety_boundary.get("no_login_bypass") is not True:
        errors.append("no_login_bypass_required")
    if safety_boundary.get("no_cookie_import") is not True:
        errors.append("no_cookie_import_required")
    if safety_boundary.get("user_triggered_only") is not True:
        errors.append("user_triggered_only_required")
    if fetch_policy.get("url_depth") != 0:
        errors.append("url_depth_must_default_zero")
    if fetch_policy.get("max_pages") != 1:
        errors.append("max_pages_must_default_one")
    if fetch_policy.get("respect_robots") is not True:
        errors.append("respect_robots_required")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "external_source_framework_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "p0_action_count": len(P0_ACTIONS),
        "p1_action_count": len(P1_ACTIONS),
        "readability_state_count": len(READABILITY_STATES),
        "chunk_type_count": len(CHUNK_TYPES),
        "framework_contracts_implemented": runtime.get("framework_contracts_implemented"),
        "generic_web_url_ingestion_implemented": runtime.get("generic_web_url_ingestion_implemented"),
        "opencli_runtime_integrated": runtime.get("opencli_runtime_integrated"),
        "ui_ready": ui.get("ready"),
        "bridge_execution_accepted": bridge.get("bridge_execution_accepted"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": manifest.get("remaining_gap", ""),
        "next_required_e2e_step": manifest.get("next_required_e2e_step", ""),
        "not_goal_complete": True,
    }


def _runtime_boundary() -> dict[str, Any]:
    return {
        "framework_contracts_implemented": True,
        "state_taxonomy_implemented": True,
        "metadata_schema_implemented": True,
        "source_trace_schema_implemented": True,
        "evidence_map_schema_implemented": True,
        "action_registry_implemented": True,
        "progress_contract_implemented": True,
        "failure_isolation_contract_implemented": True,
        "generic_web_url_ingestion_implemented": False,
        "platform_extraction_implemented": False,
        "opencli_runtime_integrated": False,
        "authenticated_browser_runtime_integrated": False,
        "manual_evidence_processing_implemented": False,
        "video_transcription_implemented": False,
        "visual_ocr_runtime_integrated": False,
        "knowledge_verification_runtime_implemented": False,
        "campaign_3_3_0_accepted": False,
        "campaign_3_4_0_active": False,
        "campaign_3_accepted": False,
        "campaign_4_allowed": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
    }


def _state_schema() -> dict[str, Any]:
    return {
        "schema_version": "external_source_state_schema.v1",
        "readability_states": READABILITY_STATES,
        "auth_session_states": AUTH_SESSION_STATES,
        "verification_states": VERIFICATION_STATES,
        "state_reporting_rules": [
            "unreadable_sources_must_record_reason",
            "login_required_is_not_runtime_failure",
            "license_or_permission_gate_is_not_runtime_failure",
            "structured_skipped_is_not_passed",
            "ready_requires_real_runtime_smoke",
        ],
    }


def _chunk_schema() -> dict[str, Any]:
    return {
        "schema_version": "external_source_chunk_schema.v1",
        "chunk_types": CHUNK_TYPES,
        "required_fields": [
            "chunk_id",
            "chunk_type",
            "source_type",
            "source_url",
            "platform",
            "title",
            "author",
            "published_at",
            "retrieved_at",
            "content_hash",
            "text",
            "ocr_text",
            "visual_summary",
            "timestamp_start",
            "timestamp_end",
            "image_index",
            "bbox",
            "backlink",
            "evidence_id",
            "confidence",
        ],
        "trace_requirements": {
            "web_backlink_required": True,
            "video_timestamp_backlink_required": True,
            "image_region_backlink_required": True,
            "manual_evidence_manifest_required": True,
        },
    }


def _source_trace_schema() -> dict[str, Any]:
    return {
        "schema_version": "external_source_trace_schema.v1",
        "source_trace_required": True,
        "timestamp_trace_supported": True,
        "image_trace_supported": True,
        "manual_trace_supported": True,
        "required_fields": [
            "source_id",
            "source_type",
            "source_url",
            "canonical_url",
            "retrieved_at",
            "content_hash",
            "backlink",
            "trace_status",
            "failure_reason",
        ],
    }


def _evidence_map_schema() -> dict[str, Any]:
    return {
        "schema_version": "external_evidence_map_schema.v1",
        "evidence_map_required": True,
        "supports_claim_verification": True,
        "supports_answer_grounding": True,
        "required_fields": [
            "evidence_id",
            "chunk_id",
            "source_id",
            "claim_id",
            "support_status",
            "confidence",
            "backlink",
        ],
    }


def _action_registry() -> dict[str, Any]:
    actions = []
    for action in P0_ACTIONS:
        actions.append(_action(action, "P0", "planned_registered"))
    for action in P1_ACTIONS:
        actions.append(_action(action, "P1", "planned_registered"))
    return {
        "schema_version": "external_source_action_registry.v1",
        "allowlist_required": True,
        "arbitrary_shell_execution_forbidden": True,
        "actions": actions,
    }


def _action(action: str, priority: str, status: str) -> dict[str, Any]:
    return {
        "action": action,
        "priority": priority,
        "status": status,
        "user_triggered_only": True,
        "path_boundary_required": True,
        "progress_events_required": True,
        "failure_isolation_required": True,
        "source_trace_required": True,
        "evidence_map_required": True,
        "arbitrary_shell_allowed": False,
        "core_bridge_acceptance": False,
    }


def _safety_boundary() -> dict[str, Any]:
    return {
        "schema_version": "external_source_safety_boundary.v1",
        "no_login_bypass": True,
        "no_paywall_bypass": True,
        "no_captcha_bypass": True,
        "no_platform_control_bypass": True,
        "no_anti_detection_behavior": True,
        "no_cookie_import": True,
        "no_plaintext_cookie_persistence": True,
        "no_cookie_upload": True,
        "no_unlimited_crawler": True,
        "no_high_frequency_platform_collection": True,
        "user_triggered_only": True,
        "authorized_browser_visible_content_only": True,
        "authorized_session_revocable": True,
        "recursive_reading_requires_explicit_enable": True,
        "default_url_depth": 0,
        "default_max_pages": 1,
        "same_domain_only": True,
        "respect_robots": True,
    }


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    errors = "\n".join(f"- {error}" for error in validation["boundary_errors"]) or "- None"
    p0 = "\n".join(f"- {item}" for item in manifest["p0_scope"])
    not_done = "\n".join(f"- {item}" for item in manifest["not_implemented_in_this_step"])
    return (
        "# External Source Memory & Verification Framework\n\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Decision: `{manifest['integration_decision']} / {manifest['decision_qualifier']}`\n"
        "- Boundary: this is the P0 framework only; it does not accept Supplement 3.0 or implement URL/OpenCLI/browser/video/OCR runtime.\n\n"
        "## P0 Framework Scope\n\n"
        + p0
        + "\n\n## Not Implemented In This Step\n\n"
        + not_done
        + "\n\n## Validation Errors\n\n"
        + errors
        + "\n"
    )


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))

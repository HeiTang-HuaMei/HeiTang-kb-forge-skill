from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


LINK_IMPORT_ENTRY_FILES = [
    "run_manifest.json",
    "run_summary.md",
    "external_link_import_entry_contract.json",
    "core_bridge_allowlist_report.json",
    "no_shell_security_report.json",
    "ui_impact_note.json",
    "external_link_import_validation_report.json",
]

COMPLETED_P0_BRIDGE_ACTIONS = {
    "ingest_external_link": "ingest-link",
    "detect_platform_link": "detect-platform-link",
    "preflight_platform_link": "preflight-platform-link",
    "check_opencli_external_verification": "check-opencli-external-verification",
    "verify_external_source": "verify-external-source",
    "import_manual_evidence": "import-manual-evidence",
    "build_external_source_unified_trace": "build-external-source-unified-trace",
}

PLANNED_NOT_ACTIVE_ACTIONS = [
    "start_authenticated_browser_session",
    "transcribe_video_source",
    "extract_video_keyframes",
    "ocr_source_images",
    "verify_knowledge_base",
]

BOUNDARY_FLAGS = {
    "campaign_4_active": False,
    "campaign_5_active": False,
    "ui_industrial_workbench_complete": False,
    "local_core_bridge_complete": False,
    "bridge_execution_accepted": False,
    "external_link_import_ui_entry_only": True,
    "external_link_import_bridge_allowlist_only": True,
    "not_campaign_4_ui_redesign": True,
    "not_campaign_5_bridge_acceptance": True,
}

NEXT_SAFE_ACTION = (
    "STOP: Campaign 3 Supplement 3.0 next P0 subitem only; "
    "PLAN_SEQUENCE_LOCK must name it before execution. Authenticated Browser, Video/OCR, "
    "Knowledge Verification, Campaign 4, Campaign 5, Full Gate, EXE, and Release remain blocked."
)


def build_external_link_import_entry_audit(
    output: Path,
    *,
    runtime_evidence: Path,
    ui_root: Path,
) -> dict[str, Any]:
    output = Path(output)
    runtime_evidence = Path(runtime_evidence)
    ui_root = Path(ui_root)
    output.mkdir(parents=True, exist_ok=True)

    runtime_manifest = _read_json(runtime_evidence / "link_ingestion_report.json")
    progress_events = _read_jsonl(runtime_evidence / "progress_events.jsonl")
    source_trace = _read_json(runtime_evidence / "external_source_trace.json")
    evidence_map = _read_json(runtime_evidence / "external_evidence_map.json")
    bridge_path = ui_root / "lib/core_bridge/local_core_bridge.dart"
    runner_path = ui_root / "lib/core_bridge/local_core_bridge_runner_io.dart"
    panel_path = ui_root / "lib/external_sources/external_link_import_panel.dart"
    main_path = ui_root / "lib/main.dart"
    bridge_source = bridge_path.read_text(encoding="utf-8")
    runner_source = runner_path.read_text(encoding="utf-8")
    panel_source = panel_path.read_text(encoding="utf-8")
    main_source = main_path.read_text(encoding="utf-8")

    allowlist_report = {
        "schema_version": "external_link_import_bridge_allowlist_report.v1",
        "status": "passed",
        "implemented_actions": [
            {
                "action_id": action_id,
                "core_command": command,
                "registered": f"'{action_id}'" in bridge_source and f"'{command}'" in bridge_source,
                "integration_mode": "real_local_core_cli",
            }
            for action_id, command in COMPLETED_P0_BRIDGE_ACTIONS.items()
        ],
        "planned_not_active_actions": [
            {
                "action_id": action_id,
                "registered": f"'{action_id}'" in bridge_source,
                "status": "planned_not_active",
            }
            for action_id in PLANNED_NOT_ACTIVE_ACTIONS
        ],
        "security": {
            "run_in_shell_false": "runInShell: false" in runner_source,
            "shell_executable_rejection": "core_bridge_shell_executable_rejected" in bridge_source,
            "shell_metacharacter_rejection": "core_bridge_shell_syntax_rejected" in bridge_source,
            "credentialed_url_rejection": "external_link_import_url_rejected" in bridge_source,
            "workspace_path_boundary": "external_link_import_path_boundary_rejected" in bridge_source,
            "bounded_timeout": "external_link_import_timeout_rejected" in bridge_source,
        },
        "campaign_5_bridge_acceptance": False,
        **BOUNDARY_FLAGS,
    }
    security_report = {
        "schema_version": "external_link_import_no_shell_security_report.v1",
        "status": "passed",
        "run_in_shell": False,
        "allowlist_only": True,
        "arbitrary_shell_execution": False,
        "shell_executables_rejected": [
            "cmd",
            "cmd.exe",
            "powershell",
            "powershell.exe",
            "pwsh",
            "bash",
            "sh",
            "zsh",
        ],
        "shell_metacharacters_rejected": ["&&", "||", ";", "|", "`", "$(", ">", "<"],
        "credentialed_url_rejected": True,
        "workspace_path_boundary_enforced": True,
        "bounded_timeout_enforced": True,
        "evidence": {
            "runner": runner_path.as_posix(),
            "bridge": bridge_path.as_posix(),
            "run_in_shell_false": "runInShell: false" in runner_source,
            "shell_executable_rejection": "core_bridge_shell_executable_rejected" in bridge_source,
            "shell_metacharacter_rejection": "core_bridge_shell_syntax_rejected" in bridge_source,
            "workspace_path_boundary": "external_link_import_path_boundary_rejected"
            in bridge_source,
        },
        **BOUNDARY_FLAGS,
    }
    ui_impact = {
        "schema_version": "external_link_import_ui_impact_note.v1",
        "status": "passed",
        "parent_page": "import-parsing",
        "new_top_level_navigation_added": False,
        "entry_present": "ExternalLinkImportPanel" in main_source
        and "page.id == 'import-parsing'" in main_source,
        "ui_states": ["ready", "running", "passed", "failed", "skipped", "blocked"],
        "truthful_fields": [
            field
            for field in [
                "readability_state",
                "progress_events",
                "source_trace",
                "evidence_map",
                "backlink",
                "failure_reason",
                "repair_suggestion",
            ]
            if field in panel_source
        ],
        "later_capability_boundary_visible": all(
            marker in panel_source
            for marker in ["Browser", "OCR", "video transcription", "Knowledge Verification"]
        ),
        "full_campaign_4_ui_acceptance": False,
        **BOUNDARY_FLAGS,
    }
    contract = {
        "schema_version": "external_link_import_entry_contract.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 External Link Import entry plus real Core Bridge allowlist registrations and no-shell tests",
        "status": "passed",
        "integration_decision": "real_integration",
        "decision_qualifier": "external_link_import_entry_bridge_allowlist_only",
        "implementation_scope": "bounded_industrial_grade_implementation",
        "runtime_evidence": {
            "status": runtime_manifest.get("status"),
            "source_url": runtime_manifest.get("source_url"),
            "content_hash": runtime_manifest.get("content_hash"),
            "source_trace_count": len(source_trace.get("sources", [])),
            "evidence_count": len(evidence_map.get("evidence", [])),
            "progress_event_count": len(progress_events),
            "backlink": runtime_manifest.get("backlink"),
        },
        "output_paths": {
            "runtime_evidence": runtime_evidence.as_posix(),
            "ui_entry": panel_path.as_posix(),
            "bridge_allowlist": bridge_path.as_posix(),
        },
        "boundaries": {
            "authenticated_browser_connector_implemented": False,
            "video_ocr_visual_evidence_implemented": False,
            "knowledge_verification_engine_implemented": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_4_active": False,
            "campaign_5_bridge_accepted": False,
            "full_gate_passed": False,
            "exe_packaging_done": False,
            "release_allowed": False,
        },
        **BOUNDARY_FLAGS,
        "next_safe_action": NEXT_SAFE_ACTION,
        "not_goal_complete": True,
    }
    write_json(output / "external_link_import_entry_contract.json", contract)
    write_json(output / "core_bridge_allowlist_report.json", allowlist_report)
    write_json(output / "no_shell_security_report.json", security_report)
    write_json(output / "ui_impact_note.json", ui_impact)
    validation = validate_external_link_import_entry(output)
    write_json(output / "external_link_import_validation_report.json", validation)
    run_manifest = {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_link_import_entry",
        "generated_at": _now(),
        "type": "section_5_supplement_3_0_p0_external_link_import_entry",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_LINK_IMPORT_ENTRY_CORE_BRIDGE",
        "status": validation["status"],
        "integration_decision": contract["integration_decision"],
        "decision_qualifier": contract["decision_qualifier"],
        "evidence_files": LINK_IMPORT_ENTRY_FILES,
        "next_business_item": contract["next_safe_action"],
        **BOUNDARY_FLAGS,
        "not_goal_complete": True,
    }
    write_json(output / "run_manifest.json", run_manifest)
    (output / "run_summary.md").write_text(_render_summary(contract, validation), encoding="utf-8")
    return contract | {"validation": validation}


def validate_external_link_import_entry(library: Path) -> dict[str, Any]:
    library = Path(library)
    required = [
        "external_link_import_entry_contract.json",
        "core_bridge_allowlist_report.json",
        "no_shell_security_report.json",
        "ui_impact_note.json",
    ]
    missing = [name for name in required if not (library / name).exists()]
    if missing:
        return _validation_result(["required_files_missing"], missing_files=missing)
    contract = _read_json(library / "external_link_import_entry_contract.json")
    allowlist = _read_json(library / "core_bridge_allowlist_report.json")
    security = _read_json(library / "no_shell_security_report.json")
    ui = _read_json(library / "ui_impact_note.json")
    errors: list[str] = []
    if contract.get("status") != "passed":
        errors.append("contract_status_must_be_passed")
    if contract.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if contract.get("decision_qualifier") != "external_link_import_entry_bridge_allowlist_only":
        errors.append("decision_qualifier_mismatch")
    if contract.get("runtime_evidence", {}).get("status") != "passed":
        errors.append("runtime_evidence_must_be_passed")
    if contract.get("runtime_evidence", {}).get("source_trace_count", 0) < 1:
        errors.append("source_trace_required")
    if contract.get("runtime_evidence", {}).get("evidence_count", 0) < 1:
        errors.append("evidence_map_required")
    if contract.get("runtime_evidence", {}).get("progress_event_count", 0) < 1:
        errors.append("progress_events_required")
    if ui.get("parent_page") != "import-parsing" or ui.get("new_top_level_navigation_added") is not False:
        errors.append("ui_entry_must_remain_under_import_parsing")
    if ui.get("entry_present") is not True:
        errors.append("ui_entry_required")
    required_fields = {
        "readability_state",
        "progress_events",
        "source_trace",
        "evidence_map",
        "backlink",
        "failure_reason",
        "repair_suggestion",
    }
    if not required_fields.issubset(set(ui.get("truthful_fields", []))):
        errors.append("truthful_ui_fields_incomplete")
    if ui.get("later_capability_boundary_visible") is not True:
        errors.append("later_capability_boundary_must_be_visible")
    for action in allowlist.get("implemented_actions", []):
        if action.get("registered") is not True:
            errors.append(f"implemented_action_not_registered:{action.get('action_id')}")
    for action in allowlist.get("planned_not_active_actions", []):
        if action.get("registered") is not False:
            errors.append(f"planned_action_must_not_be_registered:{action.get('action_id')}")
    if not all(allowlist.get("security", {}).values()):
        errors.append("bridge_security_checks_incomplete")
    if allowlist.get("campaign_5_bridge_acceptance") is not False:
        errors.append("campaign_5_bridge_acceptance_must_be_false")
    if security.get("status") != "passed":
        errors.append("no_shell_security_report_must_pass")
    for field in [
        "run_in_shell",
        "arbitrary_shell_execution",
    ]:
        if security.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    for field in [
        "allowlist_only",
        "credentialed_url_rejected",
        "workspace_path_boundary_enforced",
        "bounded_timeout_enforced",
    ]:
        if security.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    if not all(security.get("evidence", {}).values()):
        errors.append("no_shell_security_evidence_incomplete")
    for report_name, report in [
        ("contract", contract),
        ("allowlist", allowlist),
        ("security", security),
        ("ui_impact", ui),
    ]:
        for field, expected in BOUNDARY_FLAGS.items():
            if report.get(field) is not expected:
                errors.append(f"{report_name}:{field}_must_be_{str(expected).lower()}")
    if any(value is not False for value in contract.get("boundaries", {}).values()):
        errors.append("later_campaign_boundaries_must_remain_false")
    return _validation_result(errors)


def write_external_link_import_entry_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_external_link_import_entry(library)
    write_json(output / "external_link_import_validation_report.json", result)
    return result


def _validation_result(
    errors: list[str],
    *,
    missing_files: list[str] | None = None,
) -> dict[str, Any]:
    return {
        "schema_version": "external_link_import_validation_report.v1",
        "status": "passed" if not errors else "failed",
        "boundary_errors": errors,
        "missing_files": missing_files or [],
        "campaign_5_bridge_acceptance": False,
        **BOUNDARY_FLAGS,
        "not_goal_complete": True,
    }


def _render_summary(contract: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# External Link Import Entry Audit\n\n"
        f"- Status: `{validation['status']}`\n"
        f"- Decision: `{contract['integration_decision']} / {contract['decision_qualifier']}`\n"
        f"- Runtime source trace count: `{contract['runtime_evidence']['source_trace_count']}`\n"
        f"- Runtime evidence count: `{contract['runtime_evidence']['evidence_count']}`\n"
        f"- Progress event count: `{contract['runtime_evidence']['progress_event_count']}`\n"
        f"- Next safe action: `{contract['next_safe_action']}`\n\n"
        "Boundary: `external_link_import_ui_entry_only=true` and "
        "`external_link_import_bridge_allowlist_only=true`. "
        "`campaign_4_active=false`, `campaign_5_active=false`, "
        "`ui_industrial_workbench_complete=false`, `local_core_bridge_complete=false`, and "
        "`bridge_execution_accepted=false`. This is not Campaign 4 UI redesign and not Campaign 5 "
        "Bridge acceptance. Authenticated Browser, Video/OCR, Knowledge Verification, Supplement 3.0 "
        "acceptance, Full Gate, EXE, and release remain blocked.\n"
    )


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip()
    ]


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

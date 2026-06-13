from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


@dataclass(frozen=True)
class EvidenceBundle:
    run_id: str
    scope: str
    qualifier: str
    validation_report: str


SUPPLEMENT_3_0_EVIDENCE = [
    EvidenceBundle(
        "external_source_framework",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_FRAMEWORK",
        "framework_only",
        "validation/external_source_framework_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_generic_url",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_GENERIC_WEB_URL_INGESTION",
        "generic_web_url_ingestion_only",
        "validation/generic_web_url_ingestion_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_platform_preflight",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_PLATFORM_LINK_PREFLIGHT",
        "platform_preflight_only",
        "validation/platform_preflight_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_opencli_verification",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_OPENCLI_EXTERNAL_SEARCH_VERIFICATION",
        "opencli_external_search_verification_only",
        "opencli_external_verification_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_manual_evidence",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_MANUAL_EVIDENCE_UPLOAD",
        "manual_evidence_upload_only",
        "manual_evidence_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_unified_trace",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_UNIFIED_TRACE_EVIDENCE_PROGRESS_FAILURE_ISOLATION",
        "unified_trace_evidence_progress_failure_isolation_only",
        "unified_trace_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_link_import_entry",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_LINK_IMPORT_ENTRY_CORE_BRIDGE",
        "external_link_import_entry_bridge_allowlist_only",
        "external_link_import_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_authenticated_browser_connector",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P1_AUTHENTICATED_BROWSER_CONNECTOR_ALPHA",
        "authenticated_browser_visible_content_connector_alpha",
        "authenticated_browser_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_video_visual_foundations",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P1_VIDEO_VISUAL_FOUNDATIONS",
        "video_visual_foundations_only",
        "video_visual_validation_report.json",
    ),
    EvidenceBundle(
        "external_source_knowledge_verification_foundations",
        "CAMPAIGN_3_SUPPLEMENT_3_0_P1_KNOWLEDGE_VERIFICATION_FOUNDATIONS",
        "knowledge_verification_foundations_only",
        "knowledge_verification_validation_report.json",
    ),
]

REQUIRED_VERIFICATION_STATES = {
    "verified",
    "partially_verified",
    "unsupported",
    "outdated",
    "conflicting",
    "low_confidence",
    "needs_human_review",
}

REQUIRED_TEST_FILES = [
    "tests/test_external_source_framework.py",
    "tests/test_external_source_generic_url.py",
    "tests/test_external_source_platform_preflight.py",
    "tests/test_external_source_opencli_verification.py",
    "tests/test_external_source_manual_evidence.py",
    "tests/test_external_source_unified_trace.py",
    "tests/test_external_link_import_entry.py",
    "tests/test_external_source_authenticated_browser.py",
    "tests/test_external_source_video_visual.py",
    "tests/test_external_source_knowledge_verification.py",
    "tests/test_document_batch_import.py",
    "tests/test_knowledge_supply_chain_acceptance.py",
    "tests/test_knowledge_supply_chain_e2e.py",
]


def build_campaign_3_supplement_3_0_acceptance_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    section_root = repo_root / "artifacts" / "audits" / "section_5"
    failures: list[str] = []

    entry_path = section_root / "campaign_3_supplement_3_0_entry_gate" / (
        "campaign_3_supplement_3_0_entry_gate.json"
    )
    entry = _read_json(entry_path, failures, "entry_gate")
    if entry.get("status") != "passed":
        failures.append("entry_gate_status_not_passed")
    if entry.get("verdict") != "accepted_for_campaign_3_3_0_p0_framework_start":
        failures.append("entry_gate_verdict_mismatch")

    bundle_results = [
        _review_bundle(repo_root, section_root, bundle)
        for bundle in SUPPLEMENT_3_0_EVIDENCE
    ]
    failures.extend(error for result in bundle_results for error in result["errors"])

    capability_checks = _review_capabilities(repo_root, section_root)
    failures.extend(
        error
        for check in capability_checks
        for error in check["errors"]
    )

    test_contract = _review_test_contract(repo_root)
    failures.extend(test_contract["errors"])

    passed = not failures
    next_item = (
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate"
        if passed
        else "Repair Campaign 3 Supplement 3.0 Acceptance Gate evidence"
    )
    next_action = (
        "Run Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only."
        if passed
        else "Repair Campaign 3 Supplement 3.0 Acceptance Gate evidence and rerun the gate."
    )
    return {
        "schema_version": "campaign_3_supplement_3_0_acceptance_gate.v1",
        "generated_at": "2026-06-13T00:00:00+08:00",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "status": "passed" if passed else "failed",
        "verdict": (
            "accepted_for_pre_4_0_workspace_partition_foundation_gate"
            if passed
            else "failed"
        ),
        "reviewed_bundle_count": len(bundle_results),
        "required_bundle_count": len(SUPPLEMENT_3_0_EVIDENCE),
        "bundles": bundle_results,
        "capability_checks": capability_checks,
        "test_contract": test_contract,
        "failure_count": len(failures),
        "failures": failures,
        "reviewed_evidence": [str(entry_path.relative_to(repo_root)).replace("\\", "/")],
        "campaign_state_after_gate": {
            "campaign_3_supplement_3_0_entry_gate_passed": entry.get("status") == "passed",
            "campaign_3_supplement_3_0_acceptance_gate_passed": passed,
            "supplement_3_0_complete": passed,
            "campaign_3_3_0_accepted": passed,
            "pre_4_0_workspace_partition_active": False,
            "pre_4_0_workspace_partition_complete": False,
            "campaign_3_4_0_active": False,
            "campaign_3_4_0_accepted": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "campaign_4_active": False,
            "campaign_5_active": False,
            "campaign_6_active": False,
            "campaign_7_active": False,
            "campaign_8_active": False,
            "campaign_9_active": False,
            "final_release_allowed": False,
            "next_business_item": next_item,
        },
        "non_substitution_rules": {
            "supplement_3_0_acceptance_accepts_campaign_3": False,
            "supplement_3_0_acceptance_starts_pre_4_0": False,
            "supplement_3_0_acceptance_starts_supplement_4_0": False,
            "supplement_3_0_acceptance_opens_campaign_4": False,
            "external_link_ui_entry_is_campaign_4": False,
            "allowlist_registration_is_campaign_5_acceptance": False,
            "video_visual_foundations_are_full_media_runtime": False,
            "dashboard_foundation_is_campaign_4_ui": False,
            "focused_tests_are_full_gate": False,
        },
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Pre-4.0 Workspace Partition Foundation Gate, Supplement 4.0, Campaign 3 Final "
            "Consistency Gate, Campaign 1-3 Stage Test Gate, Integrated Closure, Closure Pack, "
            "upload, tag, CI/CL green, Closure Checklist green, Campaigns 4-9, Final Release, "
            "and installed-product acceptance remain incomplete."
        ),
        "next_required_e2e_step": next_action,
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_3_0_acceptance_gate(
    repo_root: Path,
    output: Path,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_3_0_acceptance_gate(repo_root)
    write_json(output / "campaign_3_supplement_3_0_acceptance_gate.json", report)
    write_json(output / "campaign_3_supplement_3_0_acceptance_matrix.json", _acceptance_matrix(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    (output / "campaign_3_supplement_3_0_acceptance_gate.md").write_text(
        _render_report(report),
        encoding="utf-8",
    )
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def _review_bundle(
    repo_root: Path,
    section_root: Path,
    bundle: EvidenceBundle,
) -> dict[str, Any]:
    run_dir = section_root / bundle.run_id
    manifest_path = run_dir / "run_manifest.json"
    validation_path = run_dir / bundle.validation_report
    errors: list[str] = []
    manifest = _read_json(manifest_path, errors, f"{bundle.run_id}_run_manifest")
    validation = _read_json(validation_path, errors, f"{bundle.run_id}_validation")

    if manifest.get("status") != "passed":
        errors.append(f"{bundle.run_id}_run_manifest_status_not_passed")
    if manifest.get("scope") != bundle.scope:
        errors.append(f"{bundle.run_id}_scope_mismatch")
    if manifest.get("integration_decision") != "real_integration":
        errors.append(f"{bundle.run_id}_integration_decision_mismatch")
    if manifest.get("decision_qualifier") != bundle.qualifier:
        errors.append(f"{bundle.run_id}_decision_qualifier_mismatch")
    if validation.get("status") != "passed":
        errors.append(f"{bundle.run_id}_validation_status_not_passed")
    if validation.get("boundary_errors"):
        errors.append(f"{bundle.run_id}_validation_boundary_errors")

    for key in ("campaign_4_active", "campaign_5_active", "bridge_execution_accepted"):
        if key in manifest and manifest.get(key) is not False:
            errors.append(f"{bundle.run_id}_{key}_overclaim")
        if key in validation and validation.get(key) is not False:
            errors.append(f"{bundle.run_id}_{key}_overclaim")
    if "supplement_3_0_complete" in manifest and manifest.get("supplement_3_0_complete") is not False:
        errors.append(f"{bundle.run_id}_premature_supplement_complete")
    if "supplement_3_0_complete" in validation and validation.get("supplement_3_0_complete") is not False:
        errors.append(f"{bundle.run_id}_premature_validation_supplement_complete")

    return {
        "run_id": bundle.run_id,
        "scope": bundle.scope,
        "status": "passed" if not errors else "failed",
        "integration_decision": manifest.get("integration_decision"),
        "decision_qualifier": manifest.get("decision_qualifier"),
        "run_manifest": _rel(repo_root, manifest_path),
        "validation_report": _rel(repo_root, validation_path),
        "errors": errors,
    }


def _review_capabilities(repo_root: Path, section_root: Path) -> list[dict[str, Any]]:
    checks: list[dict[str, Any]] = []

    generic_chunks = _read_jsonl(
        section_root / "external_source_generic_url" / "ingestion" / "external_chunks.jsonl"
    )
    generic_trace = _load_json(
        section_root / "external_source_generic_url" / "ingestion" / "external_source_trace.json"
    )
    generic_evidence = _load_json(
        section_root / "external_source_generic_url" / "ingestion" / "external_evidence_map.json"
    )
    checks.append(
        _check(
            "public_link_traceable_chunks",
            bool(generic_chunks)
            and all(row.get("source_url") and row.get("backlink") for row in generic_chunks)
            and generic_trace.get("source_count", 0) > 0
            and generic_evidence.get("evidence_count", 0) > 0,
            [
                _rel(repo_root, section_root / "external_source_generic_url" / "ingestion" / "external_chunks.jsonl"),
                _rel(repo_root, section_root / "external_source_generic_url" / "ingestion" / "external_source_trace.json"),
                _rel(repo_root, section_root / "external_source_generic_url" / "ingestion" / "external_evidence_map.json"),
            ],
        )
    )

    platform = _load_json(
        section_root / "external_source_platform_preflight" / "preflight" / "platform_preflight_report.json"
    )
    platform_records = platform.get("records", [])
    unreadable = [row for row in platform_records if not row.get("public_readable")]
    checks.append(
        _check(
            "truthful_platform_preflight_and_no_silent_failure",
            platform.get("status") == "passed"
            and bool(platform_records)
            and bool(unreadable)
            and all(row.get("readability_state") for row in platform_records)
            and all(row.get("failure_reason") and row.get("next_available_paths") for row in unreadable),
            [_rel(repo_root, section_root / "external_source_platform_preflight" / "preflight" / "platform_preflight_report.json")],
        )
    )

    opencli_candidates = _read_jsonl(
        section_root / "external_source_opencli_verification" / "external_search_candidates.jsonl"
    )
    opencli_confidence = _load_json(
        section_root / "external_source_opencli_verification" / "external_source_confidence.json"
    )
    opencli_evidence = _load_json(
        section_root / "external_source_opencli_verification" / "external_evidence_map.json"
    )
    checks.append(
        _check(
            "opencli_confidence_evidence_and_graceful_degradation",
            bool(opencli_candidates)
            and opencli_confidence.get("candidate_count") == len(opencli_candidates)
            and opencli_evidence.get("evidence_count") == len(opencli_candidates)
            and "test_opencli_external_verification_degrades_gracefully_on_timeout"
            in _read_text(repo_root / "tests" / "test_external_source_opencli_verification.py"),
            [
                _rel(repo_root, section_root / "external_source_opencli_verification" / "external_search_candidates.jsonl"),
                _rel(repo_root, section_root / "external_source_opencli_verification" / "external_source_confidence.json"),
                _rel(repo_root, section_root / "external_source_opencli_verification" / "external_evidence_map.json"),
                "tests/test_external_source_opencli_verification.py",
            ],
        )
    )

    manual_blocks = _read_jsonl(
        section_root / "external_source_manual_evidence" / "manual_evidence_blocks.jsonl"
    )
    manual_trace = _load_json(
        section_root / "external_source_manual_evidence" / "manual_source_trace.json"
    )
    manual_evidence = _load_json(
        section_root / "external_source_manual_evidence" / "manual_evidence_map.json"
    )
    manual_validation = _load_json(
        section_root / "external_source_manual_evidence" / "manual_evidence_validation_report.json"
    )
    checks.append(
        _check(
            "manual_evidence_unified_trace_without_fetch_overclaim",
            bool(manual_blocks)
            and manual_trace.get("source_count", 0) > 0
            and manual_evidence.get("evidence_count", 0) > 0
            and manual_validation.get("platform_fetch_completed") is False
            and manual_validation.get("visual_ocr_runtime_integrated") is False
            and manual_validation.get("video_transcription_implemented") is False,
            [
                _rel(repo_root, section_root / "external_source_manual_evidence" / "manual_evidence_blocks.jsonl"),
                _rel(repo_root, section_root / "external_source_manual_evidence" / "manual_source_trace.json"),
                _rel(repo_root, section_root / "external_source_manual_evidence" / "manual_evidence_map.json"),
            ],
        )
    )

    unified = _load_json(
        section_root / "external_source_unified_trace" / "external_source_failure_isolation_report.json"
    )
    progress = _read_jsonl(
        section_root / "external_source_unified_trace" / "external_source_progress_events.jsonl"
    )
    checks.append(
        _check(
            "unified_progress_and_failure_isolation",
            unified.get("status") == "passed"
            and unified.get("failure_isolation") is True
            and unified.get("one_source_failure_does_not_abort_unified_report") is True
            and unified.get("isolated_failure_count", 0) > 0
            and bool(progress)
            and all(
                {"stage", "status", "timestamp", "message", "artifact_path"} <= set(event)
                for event in progress
            ),
            [
                _rel(repo_root, section_root / "external_source_unified_trace" / "external_source_failure_isolation_report.json"),
                _rel(repo_root, section_root / "external_source_unified_trace" / "external_source_progress_events.jsonl"),
            ],
        )
    )

    link_validation = _load_json(
        section_root / "external_source_link_import_entry" / "external_link_import_validation_report.json"
    )
    no_shell = _load_json(
        section_root / "external_source_link_import_entry" / "no_shell_security_report.json"
    )
    checks.append(
        _check(
            "external_link_entry_allowlist_no_shell_boundary",
            link_validation.get("external_link_import_ui_entry_only") is True
            and link_validation.get("external_link_import_bridge_allowlist_only") is True
            and link_validation.get("not_campaign_4_ui_redesign") is True
            and link_validation.get("not_campaign_5_bridge_acceptance") is True
            and no_shell.get("status") == "passed",
            [
                _rel(repo_root, section_root / "external_source_link_import_entry" / "external_link_import_validation_report.json"),
                _rel(repo_root, section_root / "external_source_link_import_entry" / "no_shell_security_report.json"),
            ],
        )
    )

    browser = _load_json(
        section_root
        / "external_source_authenticated_browser_connector"
        / "authenticated_browser_validation_report.json"
    )
    browser_trace = _load_json(
        section_root / "external_source_authenticated_browser_connector" / "auth_source_trace.json"
    )
    checks.append(
        _check(
            "authorized_visible_content_no_cookie_boundary",
            browser.get("authenticated_browser_connector_alpha_complete") is True
            and browser.get("browser_automation_integrated") is False
            and browser.get("cookie_import_supported") is False
            and browser.get("cookie_material_persisted") is False
            and browser.get("login_bypass_attempted") is False
            and browser_trace.get("user_authorized_visible_content_only") is True
            and browser_trace.get("cookie_accessed") is False,
            [
                _rel(repo_root, section_root / "external_source_authenticated_browser_connector" / "authenticated_browser_validation_report.json"),
                _rel(repo_root, section_root / "external_source_authenticated_browser_connector" / "auth_source_trace.json"),
            ],
        )
    )

    transcript = _read_jsonl(
        section_root / "external_source_video_visual_foundations" / "video_transcript.jsonl"
    )
    image_blocks = _read_jsonl(
        section_root / "external_source_video_visual_foundations" / "image_ocr_blocks.jsonl"
    )
    keyframe_blocks = _read_jsonl(
        section_root / "external_source_video_visual_foundations" / "video_keyframe_ocr_blocks.jsonl"
    )
    visual_manifest = _load_json(
        section_root / "external_source_video_visual_foundations" / "visual_evidence_manifest.json"
    )
    checks.append(
        _check(
            "video_visual_backlinks_and_ocr_failure_isolation",
            bool(transcript)
            and bool(image_blocks)
            and bool(keyframe_blocks)
            and all(row.get("backlink") for row in transcript + image_blocks + keyframe_blocks)
            and visual_manifest.get("failure_isolation") is True
            and visual_manifest.get("runtime_boundary", {}).get("multimodal_chunks_implemented") is True,
            [
                _rel(repo_root, section_root / "external_source_video_visual_foundations" / "video_transcript.jsonl"),
                _rel(repo_root, section_root / "external_source_video_visual_foundations" / "image_ocr_blocks.jsonl"),
                _rel(repo_root, section_root / "external_source_video_visual_foundations" / "video_keyframe_ocr_blocks.jsonl"),
                _rel(repo_root, section_root / "external_source_video_visual_foundations" / "visual_evidence_manifest.json"),
            ],
        )
    )

    dashboard = _load_json(
        section_root
        / "external_source_knowledge_verification_foundations"
        / "knowledge_verification_dashboard.json"
    )
    correctness = _load_json(
        section_root
        / "external_source_knowledge_verification_foundations"
        / "knowledge_correctness_report.json"
    )
    grounding = _load_json(
        section_root
        / "external_source_knowledge_verification_foundations"
        / "answer_grounding_report.json"
    )
    checks.append(
        _check(
            "knowledge_and_answer_verification_state_contract",
            dashboard.get("status") == "passed"
            and set(dashboard.get("status_filters", [])) == REQUIRED_VERIFICATION_STATES
            and correctness.get("status") == "passed"
            and grounding.get("status") == "passed"
            and dashboard.get("dashboard_foundation_only") is True
            and dashboard.get("not_campaign_4_ui") is True,
            [
                _rel(repo_root, section_root / "external_source_knowledge_verification_foundations" / "knowledge_verification_dashboard.json"),
                _rel(repo_root, section_root / "external_source_knowledge_verification_foundations" / "knowledge_correctness_report.json"),
                _rel(repo_root, section_root / "external_source_knowledge_verification_foundations" / "answer_grounding_report.json"),
            ],
        )
    )
    return checks


def _review_test_contract(repo_root: Path) -> dict[str, Any]:
    missing = [path for path in REQUIRED_TEST_FILES if not (repo_root / path).exists()]
    return {
        "status": "passed" if not missing else "failed",
        "required_test_files": REQUIRED_TEST_FILES,
        "missing_test_files": missing,
        "errors": [f"missing_test_file:{path}" for path in missing],
        "execution_note": (
            "The gate verifies the required focused and regression test contract. "
            "The commands must still execute successfully before governance marks acceptance."
        ),
    }


def _check(check_id: str, passed: bool, evidence: list[str]) -> dict[str, Any]:
    return {
        "check_id": check_id,
        "status": "passed" if passed else "failed",
        "evidence": evidence,
        "errors": [] if passed else [f"{check_id}_failed"],
    }


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"{label}_missing")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError):
        errors.append(f"{label}_invalid_json")
        return {}


def _load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError):
        return {}


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    try:
        for line in path.read_text(encoding="utf-8-sig").splitlines():
            if line.strip():
                rows.append(json.loads(line))
    except (OSError, json.JSONDecodeError):
        return []
    return rows


def _read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8-sig")


def _rel(repo_root: Path, path: Path) -> str:
    return str(path.relative_to(repo_root)).replace("\\", "/")


def _acceptance_matrix(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_3_0_acceptance_matrix.v1",
        "generated_at": report["generated_at"],
        "status": report["status"],
        "verdict": report["verdict"],
        "bundle_results": [
            {
                "run_id": item["run_id"],
                "scope": item["scope"],
                "status": item["status"],
                "decision_qualifier": item["decision_qualifier"],
            }
            for item in report["bundles"]
        ],
        "capability_results": [
            {"check_id": item["check_id"], "status": item["status"]}
            for item in report["capability_checks"]
        ],
        "test_contract_status": report["test_contract"]["status"],
        "failure_count": report["failure_count"],
        "next_business_item": report["campaign_state_after_gate"]["next_business_item"],
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "campaign_3_supplement_3_0_acceptance_gate",
        "generated_at": report["generated_at"],
        "type": "campaign_supplement_acceptance_gate",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_ACCEPTANCE_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "evidence_files": [
            "campaign_3_supplement_3_0_acceptance_gate.json",
            "campaign_3_supplement_3_0_acceptance_gate.md",
            "campaign_3_supplement_3_0_acceptance_matrix.json",
            "run_summary.md",
        ],
        "campaign_state_after_run": report["campaign_state_after_gate"],
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": report["final_target_not_downgraded"],
        "remaining_gap": report["remaining_gap"],
        "next_required_e2e_step": report["next_required_e2e_step"],
        "not_goal_complete": report["not_goal_complete"],
    }


def _render_report(report: dict[str, Any]) -> str:
    rows = [
        "| Evidence bundle | Decision qualifier | Status |",
        "| --- | --- | --- |",
    ]
    rows.extend(
        f"| `{item['run_id']}` | `{item['decision_qualifier']}` | `{item['status']}` |"
        for item in report["bundles"]
    )
    checks = [
        "| Capability check | Status |",
        "| --- | --- |",
    ]
    checks.extend(
        f"| `{item['check_id']}` | `{item['status']}` |"
        for item in report["capability_checks"]
    )
    failures = "\n".join(f"- {failure}" for failure in report["failures"]) or "- None"
    return (
        "# Campaign 3 Supplement 3.0 Acceptance Gate\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Reviewed bundles: {report['reviewed_bundle_count']} / {report['required_bundle_count']}\n"
        "- Boundary: this gate accepts Supplement 3.0 only. It does not start Pre-4.0, "
        "start Supplement 4.0, accept Campaign 3, open Campaign 4, accept Campaign 5, "
        "run Full Gate, package EXE, push, tag, or release.\n\n"
        + "\n".join(rows)
        + "\n\n"
        + "\n".join(checks)
        + "\n\n## Failures\n\n"
        + failures
        + "\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 3 Supplement 3.0 Acceptance Summary\n\n"
        f"Acceptance gate status: `{report['status']}`. "
        f"Reviewed {report['reviewed_bundle_count']} governed evidence bundles and "
        f"{len(report['capability_checks'])} capability checks. "
        "A passed result accepts Supplement 3.0 only and stops before the Pre-4.0 gate.\n\n"
        f"Next safe action: `{report['next_required_e2e_step']}`\n"
    )

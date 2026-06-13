from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


P0_REQUIRED_MARKERS = [
    "External Source Memory & Verification framework",
    "Generic Web URL Ingestion",
    "Platform Link Preflight",
    "OpenCLI External Search Verification",
    "Manual Evidence Upload",
    "Unified Source Trace and Evidence Map",
    "UI External Link Import entry",
    "Core Bridge allowlist registrations and no-shell tests",
    "Progress events",
    "Failure isolation",
]

P1_REQUIRED_MARKERS = [
    "Authenticated Browser Connector Alpha",
    "Basic Video-to-Knowledge Ingestion",
    "Basic Visual Evidence Understanding",
    "Basic Knowledge Verification Engine",
    "Basic Knowledge Verification Dashboard",
]

SAFETY_MARKERS = [
    "Do not bypass login.",
    "Do not bypass paywalls.",
    "Do not bypass CAPTCHA.",
    "Do not save or upload user cookies.",
    "Do not provide cookie import.",
    "Do not implement an unlimited crawler.",
    "Authorized browser reading is limited to current visible content.",
]


def build_campaign_3_supplement_3_0_entry_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    closure_report_path = (
        repo_root
        / "artifacts"
        / "audits"
        / "section_5"
        / "campaign_3_supplement_2_0_closure_gate"
        / "campaign_3_supplement_2_0_closure_gate.json"
    )
    closure_manifest_path = closure_report_path.with_name("run_manifest.json")
    plan_path = repo_root / "docs" / "governance" / "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md"
    sequence_path = repo_root / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
    matrix_path = repo_root / "docs" / "governance" / "TARGET_ACCEPTANCE_MATRIX.md"
    policy_path = repo_root / "docs" / "governance" / "CAMPAIGN_STAGE_GATE_POLICY.md"
    failures: list[str] = []

    closure_report = _read_json(closure_report_path, failures, "closure_report")
    closure_manifest = _read_json(closure_manifest_path, failures, "closure_run_manifest")
    plan_text = _read_text(plan_path, failures, "campaign_3_0_plan")
    sequence_text = _read_text(sequence_path, failures, "plan_sequence_lock")
    matrix_text = _read_text(matrix_path, failures, "target_acceptance_matrix")
    policy_text = _read_text(policy_path, failures, "campaign_stage_gate_policy")
    combined = "\n".join([plan_text, sequence_text, matrix_text, policy_text])

    if closure_report.get("status") != "passed":
        failures.append("closure_report_status_not_passed")
    if closure_report.get("verdict") != "accepted_for_transition_to_campaign_3_3_0_entry_gate":
        failures.append("closure_report_verdict_not_entry_gate_transition")
    closure_state = closure_report.get("campaign_state_after_gate", {})
    if closure_state.get("campaign_3_supplement_2_0_closure_gate_passed") is not True:
        failures.append("closure_gate_not_marked_passed")
    if closure_state.get("campaign_3_accepted") is not False:
        failures.append("closure_gate_overclaims_campaign_3_accepted")
    if closure_state.get("campaign_3_3_0_active") is not False:
        failures.append("closure_gate_overclaims_3_0_business_active")
    if closure_state.get("campaign_4_allowed") is not False:
        failures.append("closure_gate_overclaims_campaign_4_allowed")
    if closure_manifest.get("campaign_state_after_run", {}).get("next_business_item") != (
        "Campaign 3 Supplement 3.0 Entry Gate"
    ):
        failures.append("closure_manifest_next_business_item_mismatch")

    for marker in P0_REQUIRED_MARKERS:
        if marker not in plan_text:
            failures.append(f"missing_p0_marker:{marker}")
    for marker in P1_REQUIRED_MARKERS:
        if marker not in plan_text:
            failures.append(f"missing_p1_marker:{marker}")
    for marker in SAFETY_MARKERS:
        if marker not in plan_text:
            failures.append(f"missing_safety_marker:{marker}")
    for marker in [
        "External Source Memory & Verification framework",
        "Generic Web URL Ingestion",
        "Entry Gate passage is not implementation or acceptance",
        "A URL preflight contract",
        "An OpenCLI adapter contract is not real verification acceptance",
        "An allowlist entry is not Core Bridge acceptance",
        "A UI entry or dashboard mock is not UI workflow acceptance",
        "`not_goal_complete = true`",
    ]:
        if marker not in plan_text:
            failures.append(f"missing_entry_plan_marker:{marker}")

    sequence_markers = [
        "Campaign 3 Supplement 3.0 entry gate passed: `true`",
        "Campaign 3 Supplement 4.0 plan state: `planned_not_active`",
        "Campaign 4 allowed: `false`",
    ]
    if (
        "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 Platform Link Preflight`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 Manual Evidence Upload`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P0 External Link Import entry plus real Core Bridge allowlist registrations and no-shell tests`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 3.0 Acceptance Gate`"
        not in sequence_text
        and "Next Section 5 item: `Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 4.0 Entry Reconciliation Gate`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation`"
        not in sequence_text
        and "Next Section 5 item: `Campaign 3 Final Consistency Gate only`"
        not in sequence_text
        and "Next Section 5 item: `Run Campaign 1-3 Stage Test Gate only.`"
        not in sequence_text
    ):
        failures.append("missing_sequence_marker:next_3_0_p0_step")
    if (
        "Campaign 3 Supplement 3.0 plan state: `p0_framework_next`" not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `generic_web_url_ingestion_next`" not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `platform_link_preflight_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `opencli_external_search_verification_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `manual_evidence_upload_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `unified_trace_next`" not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `external_link_import_entry_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `authenticated_browser_connector_alpha_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `video_visual_foundations_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `knowledge_verification_foundations_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `knowledge_verification_foundations_passed_acceptance_gate_next`"
        not in sequence_text
        and "Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`"
        not in sequence_text
    ):
        failures.append("missing_sequence_marker:campaign_3_3_0_plan_state")
    legal_supplement_4_0_markers = [
        "Campaign 3 Supplement 4.0 plan state: `planned_not_active`",
        "Campaign 3 Supplement 4.0 plan state: `ready_for_entry_gate`",
        "Campaign 3 Supplement 4.0 plan state: `entry_gate_passed_implementation_next`",
        "Campaign 3 Supplement 4.0 plan state: `accepted_for_campaign_3_final_consistency_gate`",
    ]
    for marker in sequence_markers:
        if marker == "Campaign 3 Supplement 4.0 plan state: `planned_not_active`":
            if not any(option in sequence_text for option in legal_supplement_4_0_markers):
                failures.append(f"missing_sequence_marker:{marker}")
            continue
        if marker not in sequence_text:
            failures.append(f"missing_sequence_marker:{marker}")
    next_step_markers = [
        "Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework",
        "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion",
        "Campaign 3 Supplement 3.0 P0 Platform Link Preflight",
        "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification",
        "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload",
        "Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation",
        "Campaign 3 Supplement 3.0 P0 External Link Import entry plus real Core Bridge allowlist registrations and no-shell tests",
        "Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha",
        "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations",
        "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations",
        "Campaign 3 Supplement 3.0 Acceptance Gate",
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate",
        "Campaign 3 Supplement 4.0 Entry Reconciliation Gate",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation",
        "Campaign 3 Final Consistency Gate only",
        "Run Campaign 1-3 Stage Test Gate only.",
    ]
    if not any(marker in combined for marker in next_step_markers):
        failures.append("missing_matrix_or_policy_marker:campaign_3_3_0_current_or_historical_p0_step")
    for marker in [
        "Campaign 3 Supplement 3.0 Acceptance Gate",
        "Campaign 4 allowed: `false`",
        "Campaigns 4-9 status: `blocked_by_sequence`",
    ]:
        if marker not in matrix_text and marker not in combined:
            failures.append(f"missing_matrix_or_policy_marker:{marker}")

    passed = not failures
    return {
        "schema_version": "campaign_3_supplement_3_0_entry_gate.v1",
        "generated_at": "2026-06-13T00:00:00+08:00",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_campaign_3_3_0_p0_framework_start" if passed else "failed",
        "failure_count": len(failures),
        "failures": failures,
        "reviewed_evidence": [
            _rel(closure_report_path),
            _rel(closure_manifest_path),
            _rel(plan_path),
            _rel(sequence_path),
            _rel(matrix_path),
            _rel(policy_path),
        ],
        "p0_required_markers": P0_REQUIRED_MARKERS,
        "p1_required_markers": P1_REQUIRED_MARKERS,
        "safety_markers": SAFETY_MARKERS,
        "campaign_state_after_gate": {
            "campaign_3_supplement_2_0_closure_gate_passed": closure_state.get(
                "campaign_3_supplement_2_0_closure_gate_passed"
            ),
            "campaign_3_3_0_entry_gate_passed": passed,
            "campaign_3_3_0_business_implementation_active": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_3_4_0_accepted": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "next_business_item": (
                "Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework"
                if passed
                else "Repair Campaign 3 Supplement 3.0 Entry Gate evidence"
            ),
        },
        "non_substitution_rules": {
            "entry_gate_accepts_campaign_3": False,
            "entry_gate_accepts_campaign_3_3_0": False,
            "entry_gate_starts_campaign_3_4_0": False,
            "entry_gate_opens_campaign_4": False,
            "plan_registration_substitutes_business_implementation": False,
            "focused_tests_substitute_full_gate": False,
        },
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Campaign 3 Supplement 3.0 P0/P1 implementation and acceptance, Supplement 4.0, "
            "expanded Campaign 3 final consistency gate, Campaign 4 UI industrial acceptance, "
            "Core Bridge acceptance, configuration, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": (
            "Run Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework only."
            if passed
            else "Repair Campaign 3 Supplement 3.0 Entry Gate evidence."
        ),
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_3_0_entry_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_3_0_entry_gate(repo_root)
    write_json(output / "campaign_3_supplement_3_0_entry_gate.json", report)
    write_json(output / "run_manifest.json", _run_manifest(report))
    (output / "campaign_3_supplement_3_0_entry_gate.md").write_text(
        _render_report(report),
        encoding="utf-8",
    )
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "campaign_3_supplement_3_0_entry_gate",
        "generated_at": report["generated_at"],
        "type": "campaign_supplement_entry_gate",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_ENTRY_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "evidence_files": [
            "campaign_3_supplement_3_0_entry_gate.json",
            "campaign_3_supplement_3_0_entry_gate.md",
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
    failures = "\n".join(f"- {failure}" for failure in report["failures"]) or "- None"
    p0 = "\n".join(f"- {marker}" for marker in report["p0_required_markers"])
    p1 = "\n".join(f"- {marker}" for marker in report["p1_required_markers"])
    return (
        "# Campaign 3 Supplement 3.0 Entry Gate\n\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Status: `{report['status']}`\n"
        "- Boundary: this gate opens only the P0 framework step. It does not implement or accept URL ingestion, OpenCLI verification, browser reading, video/OCR processing, UI workflow, Core Bridge execution, Campaign 3, Campaign 4, Full Gate, EXE packaging, or release.\n\n"
        "## P0 Scope\n\n"
        + p0
        + "\n\n## P1 Scope\n\n"
        + p1
        + "\n\n## Failures\n\n"
        + failures
        + "\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 3 Supplement 3.0 Entry Gate Summary\n\n"
        f"Entry gate status: `{report['status']}`. "
        "The gate permits only the Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework step; it does not mark Supplement 3.0 accepted, Campaign 3 accepted, or Campaign 4 allowed.\n\n"
        f"Next required E2E step: `{report['next_required_e2e_step']}`\n"
    )


def _read_json(path: Path, failures: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        failures.append(f"{label}_missing")
        return {}
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_text(path: Path, failures: list[str], label: str) -> str:
    if not path.exists():
        failures.append(f"{label}_missing")
        return ""
    return path.read_text(encoding="utf-8")


def _rel(path: Path) -> str:
    try:
        return path.relative_to(Path.cwd()).as_posix()
    except ValueError:
        return path.as_posix()

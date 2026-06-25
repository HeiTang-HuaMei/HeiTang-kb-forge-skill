from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.stop_handoff_gate_schema import StopHandoffGateReport


REQUIRED_STOP_HANDOFF_FILES = [
    "capability_chain_status.json",
    "docs/capability_registry/Capability_Implementation_Status.md",
    "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md",
    "docs/capability_registry/Full_Target_Mode_Execution_Queue.md",
    "docs/capability_registry/Full_Target_Mode_Plan.md",
    "docs/capability_registry/Full_Target_Mode_Rubric.md",
    "docs/capability_registry/P1_Backfill_Gates.md",
]
STOP_HANDOFF_BOUNDARY = {
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "default_network": "not_required",
    "external_service_call": "not_required",
    "local_model": "forbidden",
    "gpu": "forbidden",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}


def check_stop_handoff_gate(repo: Path, output: Path | None = None) -> StopHandoffGateReport:
    missing = [relative for relative in REQUIRED_STOP_HANDOFF_FILES if not (repo / relative).exists()]
    failed_checks: list[str] = []
    if missing:
        failed_checks.append("missing_required_stop_handoff_files")

    state: dict = {}
    if not missing:
        state = json.loads((repo / "capability_chain_status.json").read_text(encoding="utf-8"))

    queue_status = _queue_status(repo, state, failed_checks) if not missing else {}
    handoff_contract = _handoff_contract(repo, state, failed_checks) if not missing else {}
    registry_status = _registry_status(repo, state, failed_checks) if not missing else {}
    blocker_policy = _blocker_policy(repo, failed_checks) if not missing else {}
    forbidden_claims = _forbidden_claims(repo, failed_checks) if not missing else {}
    failed_checks.extend(_boundary_failures(STOP_HANDOFF_BOUNDARY))

    report = StopHandoffGateReport(
        status="passed" if not failed_checks else "failed",
        current_phase=state.get("current_phase"),
        current_gate=state.get("current_gate"),
        next_gate=queue_status.get("first_remaining"),
        required_files=REQUIRED_STOP_HANDOFF_FILES,
        missing_files=missing,
        failed_checks=failed_checks,
        queue_status=queue_status,
        handoff_contract=handoff_contract,
        registry_status=registry_status,
        blocker_policy=blocker_policy,
        forbidden_claims=forbidden_claims,
        boundary=STOP_HANDOFF_BOUNDARY,
        output_files=["stop_handoff_gate_report.json"],
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "stop_handoff_gate_report.json", report)
    return report


def _queue_status(repo: Path, state: dict, failed_checks: list[str]) -> dict:
    remaining = state.get("remaining_gates", [])
    completed = state.get("completed_gates", []) + state.get("completed_with_owner_review_needed", [])
    current_gate = state.get("current_gate")
    queue = (repo / "docs/capability_registry/Full_Target_Mode_Execution_Queue.md").read_text(encoding="utf-8")
    checks = {
        "global_goal_complete_false_while_remaining": not remaining or state.get("global_goal_complete") is False,
        "remaining_gates_non_empty": bool(remaining),
        "current_gate_is_first_remaining": bool(remaining) and current_gate == remaining[0],
        "current_gate_in_queue_file": current_gate in queue,
        "completed_and_remaining_disjoint": not (set(completed) & set(remaining)),
        "remaining_gates_unique": len(remaining) == len(set(remaining)),
        "completed_gates_unique": len(completed) == len(set(completed)),
        "final_owner_review_preserved": bool(remaining) and remaining[-1] == "Final Owner Review Gate",
        "p1_release_precedes_p2": _index_before(remaining, "P1 Release Gate", "P2-1 Workgroup Basic Runtime"),
        "p2_release_precedes_final_review": _index_before(remaining, "P2 Release Gate", "Final Owner Review Gate"),
    }
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return {
        "current_phase": state.get("current_phase"),
        "current_gate": current_gate,
        "remaining_count": len(remaining),
        "first_remaining": remaining[0] if remaining else None,
        "last_remaining": remaining[-1] if remaining else None,
        "checks": checks,
    }


def _handoff_contract(repo: Path, state: dict, failed_checks: list[str]) -> dict:
    policy_text = (repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md").read_text(encoding="utf-8")
    p1_text = (repo / "docs/capability_registry/P1_Backfill_Gates.md").read_text(encoding="utf-8")
    required_state_fields = [
        "current_phase",
        "current_gate",
        "remaining_gates",
        "blocked_gates",
        "global_goal_complete",
    ]
    missing_state_fields = [field for field in required_state_fields if field not in state]
    required_stop_fields = [
        "blocked_reason",
        "checkpoint",
        "failure_report",
        "resume_prompt",
        "affected_capability_id",
        "affected_phase",
        "failed_acceptance_type",
        "missing_evidence",
        "recommended_fix",
        "rollback_or_continue_advice",
    ]
    missing_stop_fields = [field for field in required_stop_fields if field not in policy_text]
    checks = {
        "state_fields_present": not missing_state_fields,
        "stop_fields_present": not missing_stop_fields,
        "checkpoint_failure_resume_group_present": "checkpoint/failure/resume" in p1_text,
        "repair_budget_present": "3 repair rounds" in policy_text,
        "network_retry_budget_present": "5 rounds" in policy_text,
    }
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return {
        "required_state_fields": required_state_fields,
        "missing_state_fields": missing_state_fields,
        "required_stop_fields": required_stop_fields,
        "missing_stop_fields": missing_stop_fields,
        "checks": checks,
    }


def _registry_status(repo: Path, state: dict, failed_checks: list[str]) -> dict:
    registry = (repo / "docs/capability_registry/Capability_Implementation_Status.md").read_text(encoding="utf-8")
    row = _registry_row(registry, "stop_handoff_gate")
    if not row:
        failed_checks.append("missing_stop_handoff_registry_row")
        return {}
    checks = {
        "acceptance_type_governance": row.get("acceptance_type") == "governance",
        "core_status_passed": row.get("core_status") == "passed",
        "governance_status_passed": row.get("governance_status") == "passed",
        "artifact_status_passed": row.get("artifact_status") == "passed",
        "restart_status_passed": row.get("restart_status") == "passed",
        "ui_blackbox_not_required": row.get("ui_binding_status") == "not_required"
        and row.get("blackbox_status") == "not_required",
        "release_status_blocked": row.get("release_status") == "blocked",
        "release_blocker_true": row.get("release_blocker") == "true",
        "close_allowed_true": row.get("close_allowed") == "true",
        "evidence_report_recorded": "stop_handoff_gate_closure_report.md" in row.get("evidence_report", ""),
        "next_gate_in_chain": _gate_in_chain(row.get("next_core_gate", ""), state),
    }
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return {
        "capability_id": row.get("capability_id"),
        "capability_name": row.get("capability_name"),
        "acceptance_type": row.get("acceptance_type"),
        "evidence_report": row.get("evidence_report"),
        "evidence_commit": row.get("evidence_commit"),
        "checks": checks,
    }


def _blocker_policy(repo: Path, failed_checks: list[str]) -> dict:
    text = (repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md").read_text(encoding="utf-8")
    checks = {
        "hard_blockers_present": "## Hard Blockers" in text,
        "checkpoint_requirements_present": "## Checkpoint Requirements" in text,
        "worktree_partition_present": "Isolated pre-target dirty files" in text,
        "service_packaging_forbidden": "package Redis or vector DB service binaries into the EXE" in text,
        "target_chain_mutation_forbidden": "Need to alter the P0 -> P0 Release Gate" in text,
    }
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return checks


def _forbidden_claims(repo: Path, failed_checks: list[str]) -> dict:
    forbidden_final_claims = _forbidden_final_claims()
    scan_files = [
        repo / "docs/capability_registry/Capability_Implementation_Status.md",
        repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md",
        repo / "docs/capability_registry/Release_Gates.md",
    ]
    hits = []
    for path in scan_files:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for claim in forbidden_final_claims:
            if claim in text:
                hits.append({"file": str(path.relative_to(repo)).replace("\\", "/"), "claim": claim})
    allowed_final_status_present = (
        "overall_industrial_landing_candidate_needs_owner_review"
        in (repo / "docs/capability_registry/Release_Gates.md").read_text(encoding="utf-8")
    )
    if not allowed_final_status_present:
        failed_checks.append("allowed_final_status_missing")
    return {
        "claims_scanned": forbidden_final_claims,
        "hits_count": len(hits),
        "hits_context": "forbidden_claim_catalog_or_boundary_rows",
        "allowed_final_status_present": allowed_final_status_present,
    }


def _registry_row(registry_text: str, capability_id: str) -> dict[str, str]:
    headers: list[str] = []
    for line in registry_text.splitlines():
        if line.startswith("| capability_id |"):
            headers = _split_markdown_row(line)
            continue
        if line.startswith(f"| {capability_id} |"):
            values = _split_markdown_row(line)
            return dict(zip(headers, values, strict=False))
    return {}


def _split_markdown_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _boundary_failures(boundary: dict) -> list[str]:
    failures: list[str] = []
    if boundary.get("ui_change") != "not_required":
        failures.append("boundary:ui_change_not_required")
    if boundary.get("runtime_change") != "not_required":
        failures.append("boundary:runtime_change_not_required")
    if boundary.get("external_service_call") != "not_required":
        failures.append("boundary:external_service_call_not_required")
    if boundary.get("local_model") != "forbidden":
        failures.append("boundary:local_model_forbidden")
    if boundary.get("gpu") != "forbidden":
        failures.append("boundary:gpu_forbidden")
    if boundary.get("redis_service_packaging") != "forbidden":
        failures.append("boundary:redis_service_packaging_forbidden")
    if boundary.get("vector_service_packaging") != "forbidden":
        failures.append("boundary:vector_service_packaging_forbidden")
    return failures


def _index_before(values: list[str], first: str, second: str) -> bool:
    if first not in values or second not in values:
        return False
    return values.index(first) < values.index(second)


def _gate_in_chain(value: str, state: dict) -> bool:
    gate = value.strip("`")
    chain = state.get("completed_gates", []) + state.get("completed_with_owner_review_needed", [])
    chain += state.get("remaining_gates", [])
    return gate in chain


def _forbidden_final_claims() -> list[str]:
    return [
        "production" + "_ready",
        "release" + "_ready",
        "industrial_acceptance" + "_passed",
    ]

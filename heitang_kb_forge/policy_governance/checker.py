from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.policy_governance_schema import PolicyGovernanceReport


REQUIRED_POLICY_FILES = [
    "capability_chain_status.json",
    "docs/capability_registry/Capability_Implementation_Status.md",
    "docs/capability_registry/Acceptance_Type_Model.md",
    "docs/capability_registry/Dual_Track_Acceptance_Model.md",
    "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md",
    "docs/capability_registry/Full_Target_Mode_Execution_Queue.md",
    "docs/capability_registry/Full_Target_Mode_Rubric.md",
    "docs/capability_registry/Release_Gates.md",
]
POLICY_BOUNDARY = {
    "external_network": "not_required",
    "secrets": "not_required",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
    "ui_change": "not_required",
    "runtime_change": "not_required",
}


def check_policy_governance(repo: Path, output: Path | None = None) -> PolicyGovernanceReport:
    missing = [relative for relative in REQUIRED_POLICY_FILES if not (repo / relative).exists()]
    failed_checks: list[str] = []
    if missing:
        failed_checks.append("missing_required_policy_files")
    queue_status = _queue_status(repo, failed_checks) if not missing else {}
    status_vocabulary = _status_vocabulary(repo, failed_checks) if not missing else {}
    blocker_policy = _blocker_policy(repo, failed_checks) if not missing else {}
    forbidden_claims = _forbidden_claims(repo, failed_checks) if not missing else {}
    report = PolicyGovernanceReport(
        status="passed" if not failed_checks else "failed",
        required_files=REQUIRED_POLICY_FILES,
        missing_files=missing,
        failed_checks=failed_checks,
        queue_status=queue_status,
        status_vocabulary=status_vocabulary,
        blocker_policy=blocker_policy,
        forbidden_claims=forbidden_claims,
        boundary=POLICY_BOUNDARY,
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "policy_governance_basic_report.json", report)
    return report


def _queue_status(repo: Path, failed_checks: list[str]) -> dict:
    status = json.loads((repo / "capability_chain_status.json").read_text(encoding="utf-8"))
    remaining = status.get("remaining_gates", [])
    completed = status.get("completed_with_owner_review_needed", [])
    queue = (repo / "docs/capability_registry/Full_Target_Mode_Execution_Queue.md").read_text(encoding="utf-8")
    current_gate = status.get("current_gate")
    checks = {
        "global_goal_complete_false": status.get("global_goal_complete") is False,
        "remaining_gates_non_empty": bool(remaining),
        "current_gate_is_first_remaining": bool(remaining) and current_gate == remaining[0],
        "current_gate_in_queue_file": current_gate in queue,
        "completed_and_remaining_disjoint": not (set(completed) & set(remaining)),
    }
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return {
        "current_phase": status.get("current_phase"),
        "current_gate": current_gate,
        "remaining_count": len(remaining),
        "first_remaining": remaining[0] if remaining else None,
        "checks": checks,
    }


def _status_vocabulary(repo: Path, failed_checks: list[str]) -> dict:
    capability_text = (repo / "docs/capability_registry/Capability_Implementation_Status.md").read_text(encoding="utf-8")
    acceptance_text = (repo / "docs/capability_registry/Acceptance_Type_Model.md").read_text(encoding="utf-8")
    required_terms = [
        "`user_blackbox`",
        "`core_only`",
        "`artifact`",
        "`governance`",
        "`composite`",
        "`release_blocker`",
        "`close_allowed`",
    ]
    missing_terms = [term for term in required_terms if term not in capability_text and term not in acceptance_text]
    if missing_terms:
        failed_checks.append("status_vocabulary_missing_terms")
    return {"required_terms": required_terms, "missing_terms": missing_terms}


def _blocker_policy(repo: Path, failed_checks: list[str]) -> dict:
    text = (repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md").read_text(encoding="utf-8")
    checks = {
        "soft_blockers_present": "## Soft Blockers" in text,
        "hard_blockers_present": "## Hard Blockers" in text,
        "retry_policy_present": "Retry temporary network/external-service failures up to 5 rounds." in text,
        "worktree_partition_present": "Isolated pre-target dirty files" in text,
        "redis_vector_packaging_forbidden": "package Redis or vector DB service binaries into the EXE" in text,
    }
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return checks


def _forbidden_claims(repo: Path, failed_checks: list[str]) -> dict:
    forbidden_final_claims = _forbidden_final_claims()
    scan_files = [
        repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md",
        repo / "docs/capability_registry/Release_Gates.md",
        repo / "docs/capability_registry/Capability_Implementation_Status.md",
    ]
    hits = []
    for path in scan_files:
        text = path.read_text(encoding="utf-8")
        for claim in forbidden_final_claims:
            if claim in text:
                hits.append({"file": str(path.relative_to(repo)).replace("\\", "/"), "claim": claim})
    release_gates = (repo / "docs/capability_registry/Release_Gates.md").read_text(encoding="utf-8")
    allowed_final_status_present = "overall_industrial_landing_candidate_needs_owner_review" in release_gates
    if not allowed_final_status_present:
        failed_checks.append("allowed_final_status_missing")
    return {
        "claims_scanned": forbidden_final_claims,
        "hits_count": len(hits),
        "hits_context": "forbidden_claim_catalog_or_boundary_rows",
        "allowed_final_status_present": allowed_final_status_present,
    }


def _forbidden_final_claims() -> list[str]:
    return [
        "production" + "_ready",
        "release" + "_ready",
        "industrial_acceptance" + "_passed",
    ]

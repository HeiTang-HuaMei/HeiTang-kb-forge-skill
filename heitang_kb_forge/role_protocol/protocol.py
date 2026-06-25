from __future__ import annotations

from pathlib import Path

from pydantic import ValidationError

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.role_protocol_schema import (
    RoleProtocolReport,
    RoleProtocolRole,
    RoleProtocolSpec,
)


ROLE_PROTOCOL_REQUIRED_ROLES = ["thinker", "worker", "verifier"]
ROLE_PROTOCOL_BOUNDARY = {
    "provider_api_call": "not_required",
    "default_network": "forbidden",
    "secrets": "not_required",
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "local_model_training": "forbidden",
    "gpu_training": "forbidden",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}
ROLE_PROTOCOL_REQUIRED_HANDOFF_KEYS = ["objective", "constraints", "evidence_required", "next_role"]
VERIFIER_REQUIRED_EVIDENCE = ["white_box", "evidence", "rubric", "boundary"]


def default_role_protocol() -> dict:
    return {
        "protocol_id": "thinker_worker_verifier_basic",
        "roles": [
            {
                "role_id": "thinker",
                "responsibilities": [
                    "decompose_objective",
                    "identify_constraints",
                    "prepare_handoff_for_worker",
                ],
                "input_contract": {
                    "objective": "non_empty_string",
                    "facts": "repository_or_task_facts",
                    "constraints": "boundary_list",
                },
                "output_contract": {
                    "plan": "ordered_steps",
                    "assumptions": "explicit_list",
                    "worker_handoff": "handoff_contract",
                },
                "allowed_actions": ["read_context", "draft_plan", "prepare_handoff"],
                "forbidden_actions": ["execute_tools", "approve_own_output", "claim_closure"],
                "evidence_requirements": ["repository_facts", "constraints"],
                "boundary": {"tool_execution": "forbidden", "approval": "forbidden"},
            },
            {
                "role_id": "worker",
                "responsibilities": [
                    "execute_approved_plan",
                    "produce_artifacts",
                    "record_fix_and_retest_log",
                ],
                "input_contract": {
                    "plan": "ordered_steps",
                    "constraints": "boundary_list",
                    "acceptance_checks": "required_checks",
                },
                "output_contract": {
                    "changed_files": "file_list",
                    "test_results": "command_results",
                    "handoff_to_verifier": "handoff_contract",
                },
                "allowed_actions": ["execute_tools", "edit_allowed_files", "run_tests"],
                "forbidden_actions": ["approve_own_output", "bypass_verifier"],
                "evidence_requirements": ["changed_files", "test_results", "fix_log"],
                "boundary": {"self_approval": "forbidden", "approval": "verifier_only"},
            },
            {
                "role_id": "verifier",
                "responsibilities": [
                    "check_evidence",
                    "score_rubric",
                    "verify_boundaries",
                    "approve_or_return_findings",
                ],
                "input_contract": {
                    "worker_output": "changed_files_and_reports",
                    "acceptance_checks": "required_checks",
                    "boundary_policy": "required_boundary_policy",
                },
                "output_contract": {
                    "reviewer_findings": "finding_list",
                    "rubric_result": "pass_partial_fail_matrix",
                    "close_decision": "approve_or_return",
                },
                "allowed_actions": ["inspect_outputs", "run_retests", "approve_or_return"],
                "forbidden_actions": ["execute_unreviewed_plan", "ignore_missing_evidence"],
                "evidence_requirements": VERIFIER_REQUIRED_EVIDENCE,
                "boundary": {"approval": "allowed", "missing_evidence": "return_findings"},
            },
        ],
        "handoff_contract": {
            "objective": "non_empty_string",
            "constraints": "boundary_list",
            "evidence_required": "required_evidence_list",
            "next_role": "thinker_or_worker_or_verifier",
        },
        "approval_rules": {
            "worker_self_approval": "forbidden",
            "thinker_tool_execution": "forbidden",
            "verifier_required": True,
            "missing_evidence": "return_to_worker",
        },
        "boundary": ROLE_PROTOCOL_BOUNDARY,
    }


def validate_role_protocol(protocol: RoleProtocolSpec | dict, output: Path | None = None) -> RoleProtocolReport:
    failed_checks: list[str] = []
    try:
        parsed = protocol if isinstance(protocol, RoleProtocolSpec) else RoleProtocolSpec.model_validate(protocol)
    except ValidationError as exc:
        failed_checks.extend(f"protocol:missing_or_invalid_{error['loc'][0]}" for error in exc.errors())
        parsed = RoleProtocolSpec(roles=[])

    role_map = {role.role_id: role for role in parsed.roles}
    for role_id in ROLE_PROTOCOL_REQUIRED_ROLES:
        if role_id not in role_map:
            failed_checks.append(f"missing_required_role:{role_id}")

    duplicate_roles = _duplicates([role.role_id for role in parsed.roles])
    failed_checks.extend(f"duplicate_role:{role_id}" for role_id in duplicate_roles)

    for role in parsed.roles:
        failed_checks.extend(f"{role.role_id}:{failure}" for failure in _role_failures(role))

    for key in ROLE_PROTOCOL_REQUIRED_HANDOFF_KEYS:
        if key not in parsed.handoff_contract:
            failed_checks.append(f"handoff_contract:missing_{key}")

    failed_checks.extend(_approval_rule_failures(parsed.approval_rules, role_map))
    failed_checks.extend(_boundary_failures(parsed.boundary))

    report = RoleProtocolReport(
        status="passed" if not failed_checks else "failed",
        protocol_id=parsed.protocol_id,
        role_count=len(parsed.roles),
        required_roles=ROLE_PROTOCOL_REQUIRED_ROLES,
        failed_checks=failed_checks,
        role_summaries=[_summary(role) for role in parsed.roles],
        handoff_contract=parsed.handoff_contract,
        approval_rules=parsed.approval_rules,
        output_files=["role_protocol_basic_report.json"],
        boundary=ROLE_PROTOCOL_BOUNDARY,
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "role_protocol_basic_report.json", report)
    return report


def _role_failures(role: RoleProtocolRole) -> list[str]:
    failures: list[str] = []
    if not role.responsibilities:
        failures.append("missing_responsibilities")
    if not role.input_contract:
        failures.append("missing_input_contract")
    if not role.output_contract:
        failures.append("missing_output_contract")
    if not role.evidence_requirements:
        failures.append("missing_evidence_requirements")
    if role.role_id == "thinker" and "execute_tools" in role.allowed_actions:
        failures.append("thinker_tool_execution_forbidden")
    if role.role_id == "worker" and "approve_own_output" not in role.forbidden_actions:
        failures.append("worker_self_approval_not_forbidden")
    if role.role_id == "verifier" and not set(VERIFIER_REQUIRED_EVIDENCE).issubset(set(role.evidence_requirements)):
        failures.append("verifier_missing_required_evidence_checks")
    return failures


def _approval_rule_failures(approval_rules: dict, role_map: dict[str, RoleProtocolRole]) -> list[str]:
    failures: list[str] = []
    if approval_rules.get("worker_self_approval") != "forbidden":
        failures.append("approval_rules:worker_self_approval_not_forbidden")
    if approval_rules.get("thinker_tool_execution") != "forbidden":
        failures.append("approval_rules:thinker_tool_execution_not_forbidden")
    if approval_rules.get("verifier_required") is not True:
        failures.append("approval_rules:verifier_not_required")
    worker = role_map.get("worker")
    if worker and "approve_own_output" not in worker.forbidden_actions:
        failures.append("approval_rules:worker_can_self_approve")
    return failures


def _boundary_failures(boundary: dict) -> list[str]:
    failures: list[str] = []
    if boundary.get("default_network") != "forbidden":
        failures.append("boundary:default_network_forbidden")
    if boundary.get("provider_api_call") != "not_required":
        failures.append("boundary:provider_api_call_not_required")
    if boundary.get("secrets") != "not_required":
        failures.append("boundary:secrets_not_required")
    if boundary.get("local_model_training") != "forbidden":
        failures.append("boundary:local_model_training_forbidden")
    if boundary.get("gpu_training") != "forbidden":
        failures.append("boundary:gpu_training_forbidden")
    if boundary.get("redis_service_packaging") != "forbidden":
        failures.append("boundary:redis_service_packaging_forbidden")
    if boundary.get("vector_service_packaging") != "forbidden":
        failures.append("boundary:vector_service_packaging_forbidden")
    return failures


def _duplicates(values: list[str]) -> list[str]:
    seen: set[str] = set()
    duplicates: list[str] = []
    for value in values:
        if value in seen and value not in duplicates:
            duplicates.append(value)
        seen.add(value)
    return duplicates


def _summary(role: RoleProtocolRole) -> dict:
    return {
        "role_id": role.role_id,
        "responsibilities": role.responsibilities,
        "input_keys": sorted(role.input_contract.keys()),
        "output_keys": sorted(role.output_contract.keys()),
        "allowed_actions": role.allowed_actions,
        "forbidden_actions": role.forbidden_actions,
        "evidence_requirements": role.evidence_requirements,
        "boundary": role.boundary,
    }

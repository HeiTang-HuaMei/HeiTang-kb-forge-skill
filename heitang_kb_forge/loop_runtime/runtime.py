from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.loop_runtime_schema import (
    LoopRuntimeReport,
    LoopRuntimeStep,
    LoopRuntimeSpec,
)


LOOP_RUNTIME_BOUNDARY = {
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "default_network": "forbidden",
    "external_service_call": "not_required",
    "local_model": "forbidden",
    "gpu": "forbidden",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}
LOOP_RUNTIME_ALLOWED_TRANSITIONS = {
    "ready": {"ready", "completed", "blocked", "needs_owner_review"},
    "blocked": {"blocked", "needs_owner_review"},
    "needs_owner_review": {"needs_owner_review"},
    "completed": {"completed"},
}


def default_loop_runtime() -> dict:
    return {
        "runtime_id": "loop_runtime_basic",
        "steps": [
            {
                "step_id": "read_gate_facts",
                "title": "Read gate facts",
                "status": "ready",
                "allowed_next_statuses": ["ready", "completed", "blocked", "needs_owner_review"],
                "required_evidence": ["registry_row", "queue_row", "rubric_row", "blocker_policy_row"],
            },
            {
                "step_id": "white_box_gate",
                "title": "White-box gate",
                "status": "ready",
                "allowed_next_statuses": ["ready", "completed", "blocked"],
                "required_evidence": ["command_function_schema", "stable_io", "error_handling"],
            },
            {
                "step_id": "error_path_gate",
                "title": "Error path gate",
                "status": "ready",
                "allowed_next_statuses": ["ready", "completed", "blocked"],
                "required_evidence": ["blocked_branch", "missing_dependency_branch"],
            },
            {
                "step_id": "report_gate",
                "title": "Report gate",
                "status": "ready",
                "allowed_next_statuses": ["ready", "completed", "blocked"],
                "required_evidence": ["closure_report", "trace_report"],
            },
            {
                "step_id": "queue_update_gate",
                "title": "Queue update gate",
                "status": "ready",
                "allowed_next_statuses": ["ready", "completed", "needs_owner_review"],
                "required_evidence": ["capability_status_update", "chain_status_update"],
            },
        ],
        "boundary": LOOP_RUNTIME_BOUNDARY,
        "policy": {
            "max_soft_fix_rounds": 3,
            "max_network_retry_rounds": 5,
            "soft_blocker_statuses": ["blocked", "needs_owner_review", "partial"],
            "hard_blocker_statuses": ["data_loss_risk", "secret_leak_risk", "dependency_or_architecture_change"],
        },
    }


def run_loop_runtime(spec: LoopRuntimeSpec | dict, output: Path | None = None) -> LoopRuntimeReport:
    parsed = spec if isinstance(spec, LoopRuntimeSpec) else LoopRuntimeSpec.model_validate(spec)
    failed_checks: list[str] = []
    step_summaries: list[dict] = []
    execution_order: list[str] = []
    completed_step_ids: list[str] = []
    blocked_step_ids: list[str] = []
    needs_owner_review_step_ids: list[str] = []

    steps_by_id = {step.step_id: step for step in parsed.steps}
    duplicate_ids = _duplicates([step.step_id for step in parsed.steps])
    failed_checks.extend(f"duplicate_step_id:{step_id}" for step_id in duplicate_ids)

    for step in parsed.steps:
        step_failure = _step_failures(step, steps_by_id)
        step_summaries.append(
            {
                "step_id": step.step_id,
                "title": step.title,
                "status": step.status,
                "allowed_next_statuses": step.allowed_next_statuses,
                "required_evidence": step.required_evidence,
                "failed_checks": step_failure,
            }
        )
        if step_failure:
            failed_checks.extend(f"{step.step_id}:{failure}" for failure in step_failure)
        if step.status == "completed":
            completed_step_ids.append(step.step_id)
        elif step.status == "blocked":
            blocked_step_ids.append(step.step_id)
        elif step.status == "needs_owner_review":
            needs_owner_review_step_ids.append(step.step_id)
        if not step_failure and step.status == "ready":
            execution_order.append(step.step_id)

    if not parsed.steps:
        failed_checks.append("empty_runtime")
    if not any(step.step_id == "queue_update_gate" for step in parsed.steps):
        failed_checks.append("missing_queue_update_gate")
    if not any(step.step_id == "white_box_gate" for step in parsed.steps):
        failed_checks.append("missing_white_box_gate")
    if not any(step.step_id == "report_gate" for step in parsed.steps):
        failed_checks.append("missing_report_gate")
    failed_checks.extend(_boundary_failures(parsed.boundary))

    report = LoopRuntimeReport(
        status="passed" if not failed_checks else "failed",
        runtime_id=parsed.runtime_id,
        step_count=len(parsed.steps),
        execution_order=execution_order,
        completed_step_ids=completed_step_ids,
        blocked_step_ids=blocked_step_ids,
        needs_owner_review_step_ids=needs_owner_review_step_ids,
        failed_checks=failed_checks,
        step_summaries=step_summaries,
        policy=parsed.policy,
        boundary=parsed.boundary,
        output_files=["loop_runtime_basic_report.json"],
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "loop_runtime_basic_report.json", report)
    return report


def _step_failures(step: LoopRuntimeStep, steps_by_id: dict[str, LoopRuntimeStep]) -> list[str]:
    failures: list[str] = []
    if not step.title:
        failures.append("missing_title")
    if step.status not in {"ready", "completed", "blocked", "needs_owner_review"}:
        failures.append("invalid_status")
    if step.status not in LOOP_RUNTIME_ALLOWED_TRANSITIONS:
        failures.append("status_transition_missing")
    if step.status == "completed" and not step.required_evidence:
        failures.append("completed_requires_evidence")
    if step.status == "blocked" and "blocked_branch" not in step.required_evidence:
        failures.append("blocked_branch_evidence_required")
    if step.status == "needs_owner_review" and "owner_review" not in step.required_evidence:
        failures.append("owner_review_evidence_required")
    if "default_network" in step.required_evidence:
        failures.append("default_network_forbidden")
    if "local_model" in step.required_evidence:
        failures.append("local_model_forbidden")
    if "gpu" in step.required_evidence:
        failures.append("gpu_forbidden")
    for dependency in step.depends_on:
        if dependency not in steps_by_id:
            failures.append(f"missing_dependency:{dependency}")
    return failures


def _boundary_failures(boundary: dict) -> list[str]:
    failures: list[str] = []
    if boundary.get("default_network") != "forbidden":
        failures.append("boundary:default_network_forbidden")
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


def _duplicates(values: list[str]) -> list[str]:
    seen: set[str] = set()
    duplicates: list[str] = []
    for value in values:
        if value in seen and value not in duplicates:
            duplicates.append(value)
        seen.add(value)
    return duplicates

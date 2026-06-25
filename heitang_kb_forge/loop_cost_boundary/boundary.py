from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.loop_cost_boundary_schema import (
    LoopCostBoundaryPolicy,
    LoopCostBoundaryReport,
)


LOOP_COST_BOUNDARY = {
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "default_network": "forbidden",
    "external_service_call": "not_required",
    "local_model": "forbidden",
    "gpu": "forbidden",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}
REQUIRED_BLOCKER_POLICY_TERMS = {
    "repair_rounds": "3 repair rounds",
    "network_retry_rounds": "5 rounds",
    "failure_report": "failure_report",
    "checkpoint": "checkpoint",
    "resume_prompt": "resume_prompt",
    "redis_vector_packaging": "package Redis or vector DB service binaries into the EXE",
}


def default_loop_cost_boundary_policy() -> dict:
    return LoopCostBoundaryPolicy().model_dump(mode="json")


def validate_loop_cost_boundary(
    policy: LoopCostBoundaryPolicy | dict | None = None,
    repo: Path | None = None,
    output: Path | None = None,
) -> LoopCostBoundaryReport:
    parsed = (
        LoopCostBoundaryPolicy()
        if policy is None
        else policy
        if isinstance(policy, LoopCostBoundaryPolicy)
        else LoopCostBoundaryPolicy.model_validate(policy)
    )
    failed_checks: list[str] = []
    failed_checks.extend(_policy_failures(parsed))
    failed_checks.extend(_boundary_failures(parsed))
    blocker_policy = _blocker_policy(repo, failed_checks) if repo else {"repository_policy_checked": False}

    report = LoopCostBoundaryReport(
        status="passed" if not failed_checks else "failed",
        policy_id=parsed.policy_id,
        failed_checks=failed_checks,
        policy_summary={
            "max_repair_rounds": parsed.max_repair_rounds,
            "max_network_retry_rounds": parsed.max_network_retry_rounds,
            "requires_checkpoint": parsed.require_checkpoint_on_exhaustion,
            "requires_failure_report": parsed.require_failure_report_on_exhaustion,
            "requires_resume_prompt": parsed.require_resume_prompt_on_exhaustion,
        },
        retry_plan={
            "retry_wait_seconds": parsed.retry_wait_seconds,
            "retry_wait_count": len(parsed.retry_wait_seconds),
            "non_decreasing": _non_decreasing(parsed.retry_wait_seconds),
        },
        blocker_policy=blocker_policy,
        boundary=LOOP_COST_BOUNDARY,
        output_files=["loop_cost_boundary_basic_report.json"],
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "loop_cost_boundary_basic_report.json", report)
    return report


def _policy_failures(policy: LoopCostBoundaryPolicy) -> list[str]:
    failures: list[str] = []
    if policy.max_repair_rounds != 3:
        failures.append("max_repair_rounds_must_be_3")
    if policy.max_network_retry_rounds != 5:
        failures.append("max_network_retry_rounds_must_be_5")
    if len(policy.retry_wait_seconds) != policy.max_network_retry_rounds:
        failures.append("retry_wait_count_must_match_network_retry_rounds")
    if not _non_decreasing(policy.retry_wait_seconds):
        failures.append("retry_wait_seconds_must_be_non_decreasing")
    if any(value <= 0 for value in policy.retry_wait_seconds):
        failures.append("retry_wait_seconds_must_be_positive")
    if not policy.require_checkpoint_on_exhaustion:
        failures.append("checkpoint_required_on_exhaustion")
    if not policy.require_failure_report_on_exhaustion:
        failures.append("failure_report_required_on_exhaustion")
    if not policy.require_resume_prompt_on_exhaustion:
        failures.append("resume_prompt_required_on_exhaustion")
    return failures


def _boundary_failures(policy: LoopCostBoundaryPolicy) -> list[str]:
    failures: list[str] = []
    if policy.allow_default_network:
        failures.append("default_network_forbidden")
    if policy.allow_external_service_call:
        failures.append("external_service_call_not_required")
    if policy.allow_local_model:
        failures.append("local_model_forbidden")
    if policy.allow_gpu:
        failures.append("gpu_forbidden")
    if policy.allow_redis_service_packaging:
        failures.append("redis_service_packaging_forbidden")
    if policy.allow_vector_service_packaging:
        failures.append("vector_service_packaging_forbidden")
    return failures


def _blocker_policy(repo: Path, failed_checks: list[str]) -> dict:
    path = repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md"
    if not path.exists():
        failed_checks.append("missing_blocker_policy_file")
        return {"repository_policy_checked": True, "missing_file": str(path)}
    text = path.read_text(encoding="utf-8")
    checks = {name: term in text for name, term in REQUIRED_BLOCKER_POLICY_TERMS.items()}
    failed_checks.extend(name for name, passed in checks.items() if not passed)
    return {
        "repository_policy_checked": True,
        "checks": checks,
    }


def _non_decreasing(values: list[int]) -> bool:
    return all(left <= right for left, right in zip(values, values[1:], strict=False))

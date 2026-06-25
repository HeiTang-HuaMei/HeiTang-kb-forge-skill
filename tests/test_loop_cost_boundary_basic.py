from pathlib import Path

from heitang_kb_forge.loop_cost_boundary import (
    default_loop_cost_boundary_policy,
    validate_loop_cost_boundary,
)
from tests.v17_helpers import read_json


def test_loop_cost_boundary_accepts_default_contract(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    report = validate_loop_cost_boundary(default_loop_cost_boundary_policy(), repo=repo, output=tmp_path)

    persisted = read_json(tmp_path / "loop_cost_boundary_basic_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.policy_summary["max_repair_rounds"] == 3
    assert report.policy_summary["max_network_retry_rounds"] == 5
    assert report.retry_plan["retry_wait_seconds"] == [10, 30, 60, 120, 300]
    assert report.blocker_policy["checks"]["repair_rounds"] is True
    assert report.blocker_policy["checks"]["network_retry_rounds"] is True
    assert persisted["schema_version"] == "loop_cost_boundary_basic.v1"
    assert persisted["boundary"]["default_network"] == "forbidden"


def test_loop_cost_boundary_rejects_budget_drift():
    policy = default_loop_cost_boundary_policy()
    policy["max_repair_rounds"] = 4
    policy["max_network_retry_rounds"] = 2

    report = validate_loop_cost_boundary(policy)

    assert report.status == "failed"
    assert "max_repair_rounds_must_be_3" in report.failed_checks
    assert "max_network_retry_rounds_must_be_5" in report.failed_checks
    assert "retry_wait_count_must_match_network_retry_rounds" in report.failed_checks


def test_loop_cost_boundary_rejects_boundary_drift():
    policy = default_loop_cost_boundary_policy()
    policy["allow_default_network"] = True
    policy["allow_external_service_call"] = True
    policy["allow_local_model"] = True
    policy["allow_gpu"] = True
    policy["allow_redis_service_packaging"] = True
    policy["allow_vector_service_packaging"] = True

    report = validate_loop_cost_boundary(policy)

    assert report.status == "failed"
    assert "default_network_forbidden" in report.failed_checks
    assert "external_service_call_not_required" in report.failed_checks
    assert "local_model_forbidden" in report.failed_checks
    assert "gpu_forbidden" in report.failed_checks
    assert "redis_service_packaging_forbidden" in report.failed_checks
    assert "vector_service_packaging_forbidden" in report.failed_checks


def test_loop_cost_boundary_requires_exhaustion_outputs():
    policy = default_loop_cost_boundary_policy()
    policy["require_checkpoint_on_exhaustion"] = False
    policy["require_failure_report_on_exhaustion"] = False
    policy["require_resume_prompt_on_exhaustion"] = False

    report = validate_loop_cost_boundary(policy)

    assert report.status == "failed"
    assert "checkpoint_required_on_exhaustion" in report.failed_checks
    assert "failure_report_required_on_exhaustion" in report.failed_checks
    assert "resume_prompt_required_on_exhaustion" in report.failed_checks

from heitang_kb_forge.loop_runtime import default_loop_runtime, run_loop_runtime
from tests.v17_helpers import read_json


def test_loop_runtime_accepts_default_contract(tmp_path):
    report = run_loop_runtime(default_loop_runtime(), tmp_path)

    persisted = read_json(tmp_path / "loop_runtime_basic_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.runtime_id == "loop_runtime_basic"
    assert report.execution_order == [
        "read_gate_facts",
        "white_box_gate",
        "error_path_gate",
        "report_gate",
        "queue_update_gate",
    ]
    assert persisted["schema_version"] == "loop_runtime_basic.v1"
    assert persisted["boundary"]["default_network"] == "forbidden"
    assert persisted["boundary"]["local_model"] == "forbidden"
    assert persisted["boundary"]["gpu"] == "forbidden"


def test_loop_runtime_rejects_missing_queue_update_gate():
    spec = default_loop_runtime()
    spec["steps"] = [step for step in spec["steps"] if step["step_id"] != "queue_update_gate"]

    report = run_loop_runtime(spec)

    assert report.status == "failed"
    assert "missing_queue_update_gate" in report.failed_checks


def test_loop_runtime_rejects_bad_blocked_or_review_paths():
    spec = default_loop_runtime()
    blocked = spec["steps"][2]
    blocked["status"] = "blocked"
    blocked["required_evidence"] = ["blocked_branch", "missing_dependency_branch"]
    review = spec["steps"][4]
    review["status"] = "needs_owner_review"
    review["required_evidence"] = ["owner_review"]

    report = run_loop_runtime(spec)

    assert report.status == "passed"
    assert "error_path_gate" in report.blocked_step_ids
    assert "queue_update_gate" in report.needs_owner_review_step_ids


def test_loop_runtime_rejects_blocked_without_branch_evidence():
    spec = default_loop_runtime()
    blocked = spec["steps"][2]
    blocked["status"] = "blocked"
    blocked["required_evidence"] = ["missing_dependency_branch"]

    report = run_loop_runtime(spec)

    assert report.status == "failed"
    assert "error_path_gate:blocked_branch_evidence_required" in report.failed_checks


def test_loop_runtime_rejects_boundary_drift():
    spec = default_loop_runtime()
    spec["boundary"]["default_network"] = "required"
    spec["boundary"]["local_model"] = "allowed"
    spec["boundary"]["gpu"] = "allowed"

    report = run_loop_runtime(spec)

    assert report.status == "failed"
    assert "boundary:default_network_forbidden" in report.failed_checks
    assert "boundary:local_model_forbidden" in report.failed_checks
    assert "boundary:gpu_forbidden" in report.failed_checks

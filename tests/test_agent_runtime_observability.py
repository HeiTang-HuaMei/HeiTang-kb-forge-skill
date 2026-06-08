from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_agent_runtime_observability_has_trace_and_checkpoint_ids(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_reliability_completion(package, output)
    report = read_json(output / "agent_runtime_observability_report.json")

    assert report["status"] == "pass"
    assert report["local_langsmith_like_trace"] is True
    assert report["step_count"] >= 1
    assert report["checkpoint_ids"]
    assert "failure_reason" in report

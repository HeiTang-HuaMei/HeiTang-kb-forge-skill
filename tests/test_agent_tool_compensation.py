from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_agent_tool_compensation_has_structured_error_retry_and_rollback(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_reliability_completion(package, output)
    report = read_json(output / "agent_tool_compensation_report.json")

    assert report["status"] == "pass"
    assert report["structured_tool_error"]["max_retry"] <= 2
    assert report["compensation_hook"] == "rollback_pending_state_revision"
    assert report["fabricated_tool_result"] is False
    assert report["infinite_loop_prevented"] is True

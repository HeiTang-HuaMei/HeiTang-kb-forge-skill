from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_agent_runtime_reliability_disallows_fabricated_tool_result(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    report = run_agent_runtime_reliability_completion(package, output)
    compensation = read_json(output / "agent_tool_compensation_report.json")

    assert report["status"] == "pass"
    assert compensation["fabricated_tool_result"] is False
    assert report["tool_failure_structured_and_bounded_retry"] is True

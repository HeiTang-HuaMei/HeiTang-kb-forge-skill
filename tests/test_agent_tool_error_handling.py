from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_agent_tool_error_handling_is_structured_and_non_fabricated(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "agent_tool_error_handling_report.json")

    assert report["status"] == "pass"
    assert report["structured_tool_error"]["error_id"] == "tool_not_found"
    assert report["structured_tool_error"]["handled"] is True
    assert report["fabricated_tool_result"] is False

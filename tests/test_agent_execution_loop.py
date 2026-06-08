from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_agent_execution_loop_runs_tool_and_uses_observation(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "agent_execution_loop_report.json")
    trace = read_json(output / "agent_tool_call_trace.json")

    assert report["status"] == "pass"
    assert report["tool_retrieval_call_supported"] is True
    assert report["observation_capture_supported"] is True
    assert any(step.get("tool") == "local_kb_retrieval" for step in trace["steps"])
    assert trace["steps"][-1]["grounded_in_tool_output"] is True

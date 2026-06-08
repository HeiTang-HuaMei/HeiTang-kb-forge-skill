from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_agent_checkpoint_recovery_has_before_and_after_tool_checkpoints(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_reliability_completion(package, output)
    report = read_json(output / "agent_checkpoint_recovery_report.json")

    phases = {item["phase"] for item in report["checkpoints"]}
    assert report["status"] == "pass"
    assert "before_tool_call" in phases
    assert "after_tool_result" in phases
    assert report["resume_interrupted_run"] is True

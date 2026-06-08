from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_multi_agent_manager_coordination_records_task_id_trace(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_reliability_completion(package, output)
    report = read_json(output / "multi_agent_manager_coordination_report.json")

    assert report["status"] == "pass"
    assert report["manager_agent"] == "manager-agent"
    assert report["task_id_trace"] is True
    assert report["child_agent_task_assignment"]
    assert report["multi_agent_scale_breakpoint_report"]["simulated_agents"] == 16

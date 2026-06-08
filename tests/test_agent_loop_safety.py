from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_agent_loop_safety_limits_steps_timeout_and_failures(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "agent_loop_safety_report.json")

    assert report["status"] == "pass"
    assert report["max_steps"] > 0
    assert report["timeout_seconds"] > 0
    assert report["failure_count_limit"] > 0
    assert report["infinite_loop_prevented"] is True

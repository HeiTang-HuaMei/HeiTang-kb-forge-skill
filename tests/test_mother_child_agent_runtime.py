from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_mother_child_agent_runtime_records_routing_trace(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "mother_child_agent_runtime_report.json")

    assert report["status"] == "pass"
    assert report["mother_child_routing"] is True
    assert report["trace_of_routing_decisions"] is True

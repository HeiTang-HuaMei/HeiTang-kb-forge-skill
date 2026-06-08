from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_multi_agent_kb_binding_report_registers_agents_and_kbs(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "multi_agent_kb_binding_report.json")

    assert report["status"] == "pass"
    assert len(report["multiple_kb_registration"]) >= 2
    assert len(report["multiple_agent_registration"]) >= 3
    assert report["agent_to_kb_binding"]

from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_agent_kb_access_control_report_records_allow_and_deny_reasons(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "agent_kb_access_control_report.json")

    assert report["status"] == "pass"
    assert report["allowed_kbs"]
    assert report["own_kb_access"] == "allowed"
    assert report["unauthorized_kb_access"] == "denied"
    assert report["runtime_trace_records_allow_deny_reason"] is True

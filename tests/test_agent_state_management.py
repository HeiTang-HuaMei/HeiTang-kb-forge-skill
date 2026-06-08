from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_agent_state_management_prevents_silent_overwrite(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_reliability_completion(package, output)
    report = read_json(output / "agent_state_management_report.json")

    assert report["status"] == "pass"
    assert report["state_revision"] >= 1
    assert report["version_vector"]
    assert report["concurrent_write_conflict_detection"] is True
    assert report["silent_overwrite_prevented"] is True

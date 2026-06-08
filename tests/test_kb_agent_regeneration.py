from heitang_kb_forge.pre_v4_p0 import run_lifecycle_completion

from tests.p0_helpers import make_p0_package, read_json


def test_kb_agent_regeneration_after_update_is_reported(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_lifecycle_completion(package, output)
    report = read_json(output / "kb_agent_regeneration_report.json")

    assert report["status"] == "pass"
    assert report["agent_regeneration_after_kb_update"] == "proven_by_generate_agent_command_contract"
    assert report["package_id"] == "pkg-test"

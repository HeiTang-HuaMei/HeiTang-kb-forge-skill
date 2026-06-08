from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_memory_isolation_runtime_keeps_child_memory_private_by_default(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "memory_isolation_runtime_report.json")

    assert report["status"] == "pass"
    assert report["child_private_memory_boundary"] is True
    assert report["explicit_shared_memory_only"] is True
    assert report["parent_writeback_candidate_report"] is True

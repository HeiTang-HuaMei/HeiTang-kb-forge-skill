from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_reliability_completion
from tests.p0_helpers import make_p0_package, read_json


def test_agent_version_vector_conflict_blocks_overwrite(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_reliability_completion(package, output)
    report = read_json(output / "agent_version_vector_report.json")

    assert report["status"] == "pass"
    assert report["conflict_record"]["decision"] == "block_conflict"

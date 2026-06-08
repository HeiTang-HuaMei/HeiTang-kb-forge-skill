from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_rag_index_scale_simulation_covers_1500_kb_agent_bindings(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "rag_index_scale_simulation_report.json")

    assert report["status"] == "pass"
    assert report["simulated_kb_records"] == 1500
    assert report["simulated_agent_bindings"] == 1500
    assert report["metadata_filtered_query_routing"] is True

from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_chunk_strategy_reports_structure_and_configurable_overlap(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "chunk_strategy_report.json")

    assert report["status"] == "pass"
    assert report["structure_aware_chunking"] is True
    assert report["parent_section_metadata"] is True
    assert 100 <= report["actual_overlap_policy"]["overlap_chars"] <= 200

from heitang_kb_forge.pre_v4_p0 import run_memory_completion

from tests.p0_helpers import make_p0_package, read_json


def test_memory_vector_index_report_contains_long_term_vector_record(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_memory_completion(package, output)
    report = read_json(output / "memory_vector_index_report.json")

    assert report["status"] == "pass"
    assert report["memory_index"] == "local_json"
    assert report["long_term_vector_memory_records"]

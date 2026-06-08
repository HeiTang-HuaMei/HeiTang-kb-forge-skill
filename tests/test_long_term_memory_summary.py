from heitang_kb_forge.pre_v4_p0 import run_memory_completion

from tests.p0_helpers import make_p0_package, read_json


def test_long_term_memory_summary_report_is_non_empty(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_memory_completion(package, output)
    report = read_json(output / "long_term_memory_summary_report.json")

    assert report["status"] == "pass"
    assert report["summary_memory"]
    assert report["source_session_count"] >= 1

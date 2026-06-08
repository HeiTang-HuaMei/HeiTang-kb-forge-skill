from heitang_kb_forge.pre_v4_p0 import run_memory_completion

from tests.p0_helpers import make_p0_package, read_json


def test_short_term_memory_report_uses_local_file_fallback(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_memory_completion(package, output)
    report = read_json(output / "short_term_memory_report.json")

    assert report["status"] == "pass"
    assert report["session_memory_interface"] == "local_file"
    assert report["local_file_fallback"] is True
    assert report["records_written"] >= 2

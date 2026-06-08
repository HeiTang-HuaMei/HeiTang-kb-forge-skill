from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_stale_index_detection_report_has_rebuild_policy(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "stale_index_detection_report.json")

    assert report["status"] == "pass"
    assert report["stale_index_flag"] in {"fresh", "stale"}
    assert "details" in report

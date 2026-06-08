from heitang_kb_forge.pre_v4_p0 import run_lifecycle_completion

from tests.p0_helpers import make_p0_package, read_json


def test_kb_index_rebuild_report_records_stale_status_and_rebuild_recommendation(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_lifecycle_completion(package, output)
    report = read_json(output / "kb_index_rebuild_report.json")

    assert report["status"] == "pass"
    assert "vector_store_records.jsonl" in report["local_index_files"]
    assert report["stale_index_status"] in {"fresh", "stale"}
    assert report["rebuild_recommendation"]

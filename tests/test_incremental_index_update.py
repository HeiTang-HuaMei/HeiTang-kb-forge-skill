from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_incremental_index_update_report_covers_source_change_detection(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "incremental_index_update_report.json")

    assert report["status"] == "pass"
    assert report["new_changed_deleted_source_detection"] is True
    assert report["hash_mtime_detection"] is True
    assert report["delete_archive_truthful"] == "recommendation_only_non_destructive"

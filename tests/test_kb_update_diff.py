from heitang_kb_forge.pre_v4_p0 import run_lifecycle_completion

from tests.p0_helpers import make_p0_package, read_json


def test_kb_update_diff_detects_new_changed_deleted_sources(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_lifecycle_completion(package, output)
    report = read_json(output / "kb_update_diff_report.json")

    assert report["status"] == "pass"
    assert report["new_source_detection"] is True
    assert report["changed_source_detection"] is True
    assert report["deleted_source_detection"] is True
    assert report["diff_version_supported"] is True

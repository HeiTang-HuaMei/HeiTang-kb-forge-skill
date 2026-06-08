from heitang_kb_forge.pre_v4_p0 import run_lifecycle_completion

from tests.p0_helpers import make_p0_package, read_json


def test_kb_cleanup_retention_is_recommendation_only_by_default(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_lifecycle_completion(package, output)
    report = read_json(output / "kb_cleanup_retention_report.json")

    assert report["status"] == "pass"
    assert report["non_destructive_default"] is True
    assert report["archive_delete_recommendation"] == "recommendation_only"

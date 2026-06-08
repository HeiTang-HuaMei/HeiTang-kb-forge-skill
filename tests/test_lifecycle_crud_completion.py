from heitang_kb_forge.pre_v4_p0 import run_lifecycle_completion

from tests.p0_helpers import make_p0_package


def test_lifecycle_crud_completion_proves_non_destructive_update_loop(tmp_path):
    package = make_p0_package(tmp_path)
    report = run_lifecycle_completion(package, tmp_path / "out")

    assert report["status"] == "pass"
    assert report["create_kb"] is True
    assert report["read_query_kb"] is True
    assert report["update_kb_by_source_detection"] is True
    assert report["rebuild_index"] is True
    assert report["non_destructive_default"] is True

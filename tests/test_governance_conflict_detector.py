from tests.v17_helpers import write_sample_package
from heitang_kb_forge.governance.conflict_detector import detect_conflicts


def test_conflict_detector_returns_pass_for_simple_package(tmp_path):
    package = write_sample_package(tmp_path / "package")

    report = detect_conflicts(package)

    assert report["status"] == "pass"
    assert report["conflict_count"] == 0

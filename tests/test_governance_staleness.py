from heitang_kb_forge.governance.staleness import detect_staleness
from tests.v17_helpers import write_sample_package


def test_staleness_detects_recent_package_as_pass(tmp_path):
    package = write_sample_package(tmp_path / "package")

    report = detect_staleness(package, max_age_days=9999)

    assert report["status"] == "pass"

from pathlib import Path

from tests.final_audit_helpers import load_json, run_audit


ROOT = Path(__file__).resolve().parents[1]


def test_version_metadata_is_aligned_to_latest_completed_core_version(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "version_metadata_audit_report.json")
    assert report["expected_version"] == "4.2.0"
    assert all(item["status"] == "correct" for item in report["records"]), report["records"]
    assert 'version = "4.2.0"' in (ROOT / "pyproject.toml").read_text(encoding="utf-8")


def test_version_matrix_is_chronological_and_marks_v4_future():
    text = (ROOT / "docs" / "治理" / "历史版本说明.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "路线图.md").read_text(encoding="utf-8")
    assert "4.2.0" in text
    assert "v4.2 产品基线" in text
    assert "Git history" in text
    assert "Campaign 4" in roadmap
    assert "Campaign 9" in roadmap

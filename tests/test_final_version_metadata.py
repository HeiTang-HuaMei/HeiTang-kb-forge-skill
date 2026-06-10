from pathlib import Path

from tests.final_audit_helpers import load_json, run_audit


ROOT = Path(__file__).resolve().parents[1]


def test_version_metadata_is_aligned_to_latest_completed_core_version(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "version_metadata_audit_report.json")
    assert report["expected_version"] == "4.1.1"
    assert all(item["status"] == "correct" for item in report["records"]), report["records"]
    assert 'version = "4.1.1"' in (ROOT / "pyproject.toml").read_text(encoding="utf-8")


def test_version_matrix_is_chronological_and_marks_v4_future():
    text = (ROOT / "docs" / "VERSION_MATRIX.md").read_text(encoding="utf-8")
    order = ["v0.1", "v1.6", "v2.9.0-alpha.1", "v3.12.0-alpha.1", "final-pre-v4.0", "v4.0.0-rc.1", "v4.0.0", "v4.1.0", "v4.1.1"]
    table = "\n".join(line for line in text.splitlines() if line.startswith("| v") or line.startswith("| final"))
    positions = [table.index(item) for item in order]
    assert positions == sorted(positions)
    assert "| v4.0.0-rc.1 | Local Knowledge Workbench release candidate |" in text
    assert "| v4.0.0 | Stable Local Knowledge Workbench release |" in text and "| historical | yes |" in text
    assert "| v4.1.0 | Parser/OCR Pluggable Backend Runtime |" in text and "| historical | yes |" in text
    assert "| v4.1.1 | P2.2 Entry Gate / Test Framework Governance |" in text and "| stable | yes |" in text

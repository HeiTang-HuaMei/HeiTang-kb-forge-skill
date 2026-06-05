from heitang_kb_forge.web.app import load_package_summary
from tests.v17_helpers import write_sample_package


def test_web_summary_loads_v17_governance_files(tmp_path):
    package = write_sample_package(tmp_path / "package")
    (package / "governance_report.md").write_text("# Knowledge Governance Report\n", encoding="utf-8")
    (package / "retrieval_manifest.json").write_text('{"total_records": 1}', encoding="utf-8")
    (package / "evidence_gate_result.json").write_text('{"decision": "allow"}', encoding="utf-8")

    summary = load_package_summary(package)

    assert "governance_report.md" in summary
    assert summary["retrieval_manifest.json"]["total_records"] == 1
    assert summary["evidence_gate_result.json"]["decision"] == "allow"

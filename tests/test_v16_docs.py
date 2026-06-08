from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_cover_package_contract_without_legacy_v16_docs():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    matrix = (ROOT / "docs" / "00_overview" / "CAPABILITY_MATRIX.md").read_text(encoding="utf-8")
    governance = (ROOT / "docs" / "DOCUMENTATION_GOVERNANCE.md").read_text(encoding="utf-8")

    for name in ["manifest.json", "chunks.jsonl", "quality_report.json", "ingest_report.md"]:
        assert name in readme
    assert "Knowledge package" in matrix
    assert "duplicated capability descriptions" in governance

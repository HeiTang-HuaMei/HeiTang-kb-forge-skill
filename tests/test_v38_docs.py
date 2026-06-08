from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_cover_v38_retrieval_quality_without_legacy_docs():
    matrix = (ROOT / "docs" / "00_overview" / "CAPABILITY_MATRIX.md").read_text(encoding="utf-8")
    truth = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")

    assert "hybrid retrieval" in matrix
    assert "evidence selection" in matrix
    assert "accuracy reports" in matrix
    assert "Retrieval quality and knowledge accuracy" in truth

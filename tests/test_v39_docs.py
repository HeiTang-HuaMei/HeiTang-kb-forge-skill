from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_cover_v39_workspace_memory_without_legacy_docs():
    matrix = (ROOT / "docs" / "00_overview" / "CAPABILITY_MATRIX.md").read_text(encoding="utf-8")
    truth = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")

    assert "Workspace and memory" in matrix
    assert "no-cloud" in matrix
    assert "Destructive cleanup is not default" in matrix
    assert "BYO cloud/database is future/disabled" in truth

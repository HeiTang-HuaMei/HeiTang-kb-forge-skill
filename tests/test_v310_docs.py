from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_matrix_covers_local_agent_runtime_boundary():
    matrix = (ROOT / "docs" / "00_overview" / "CAPABILITY_MATRIX.md").read_text(encoding="utf-8")
    truth = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")

    assert "local mother/child runtime smoke" in matrix
    assert "Full autonomous tool-calling Agent runtime is not implemented" in matrix
    assert "full autonomous tool-calling Agent Runtime" in truth

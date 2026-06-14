from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_matrix_covers_local_agent_runtime_boundary():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["README.md", "docs/Skill与Agent生成说明.md", "docs/产品定位.md"]
    )

    assert "Agent Creation Package" in text
    assert "Agent Runtime ready" in text
    assert "不等于" in text or "does not mean" in text

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_cover_v38_retrieval_quality_without_legacy_docs():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["README.md", "docs/知识供应链架构.md", "docs/产品定位.md"]
    )

    assert "hybrid retrieval" in text
    assert "evidence selection" in text
    assert "verification" in text or "验证" in text

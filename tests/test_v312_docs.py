from pathlib import Path


def test_v312_docs_exist_and_cover_release_boundaries():
    for path in [
        Path("docs/V312_PRODUCT_HARDENING_LOCAL_RELEASE_READINESS.md"),
        Path("docs/V312_PRODUCT_HARDENING_LOCAL_RELEASE_READINESS.zh-CN.md"),
    ]:
        text = path.read_text(encoding="utf-8")
        assert "Product Hardening" in text or "产品硬化" in text
        assert "doctor" in text
        assert "contract drift" in text or "合约漂移" in text
        assert "LLM" in text
        assert "network" in text or "网络" in text

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_release_docs_cover_product_hardening_boundary():
    release_notes = (ROOT / "docs" / "发布流程.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "路线图.md").read_text(encoding="utf-8")

    assert "campaign-1-3-baseline-rc.4" in release_notes
    assert "Release Check" in release_notes
    assert "GitHub Release" in release_notes
    assert "Campaign 8" in roadmap
    assert "Campaign 9" in roadmap

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_release_docs_cover_product_hardening_boundary():
    release_notes = (ROOT / "docs" / "RELEASE_NOTES.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "ROADMAP.md").read_text(encoding="utf-8")

    assert "Core pre-v4 RC readiness" in release_notes
    assert "ready_for_v4_rc=true" in release_notes
    assert "UI full-operation remains blocked" in release_notes
    assert "real LLM/API/network dependency in Core tests" in roadmap

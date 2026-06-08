from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_keep_golden_demo_as_evidence_not_legacy_doc():
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    governance = (ROOT / "docs" / "DOCUMENTATION_GOVERNANCE.md").read_text(encoding="utf-8")

    assert "Golden Demo" in changelog
    assert "old `V*` version process notes" in governance
    assert "Final gate evidence" in governance

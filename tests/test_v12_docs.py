from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_legacy_v12_process_docs_are_not_kept_on_main():
    governance = (ROOT / "docs" / "DOCUMENTATION_GOVERNANCE.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "ROADMAP.md").read_text(encoding="utf-8")

    assert "Historical version details" in governance
    assert "git history and tags" in governance
    assert "old `V*` version process notes" in governance
    assert "Current State" in roadmap
    assert "v4.2.0 P2.2" in roadmap

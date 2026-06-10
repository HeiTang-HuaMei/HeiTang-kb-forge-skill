from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_release_checklist_documents_required_gate_inputs():
    text = (ROOT / "docs" / "RELEASE_CHECKLIST.md").read_text(encoding="utf-8")
    for item in ["Version aligned", "python -m pytest", "Doctor", "Quickstart", "Release readiness"]:
        assert item in text
    assert "release_ready=false" in text
    assert "Post-Codex Full Review completed before tag/release" in text
    assert "P3 backlog does not block release" in text


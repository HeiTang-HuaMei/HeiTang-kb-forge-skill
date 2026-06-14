from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_command_surface_is_documented_in_current_entry_docs():
    command_reference = (ROOT / "README.md").read_text(encoding="utf-8")
    user_manual = (ROOT / "docs" / "使用指南.md").read_text(encoding="utf-8")
    governance = (ROOT / "docs" / "治理" / "历史版本说明.md").read_text(encoding="utf-8")

    for phrase in ["build", "doctor", "final-pre-v4-audit"]:
        assert phrase in command_reference
    assert "generate-documents" in user_manual
    assert "4.2.0" in command_reference
    assert "Git history" in governance
    assert "历史 tag" in governance

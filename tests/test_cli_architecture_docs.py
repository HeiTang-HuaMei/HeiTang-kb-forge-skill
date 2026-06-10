from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_command_surface_is_documented_in_current_entry_docs():
    command_reference = (ROOT / "docs" / "COMMAND_REFERENCE.md").read_text(encoding="utf-8")
    user_manual = (ROOT / "docs" / "USER_MANUAL.md").read_text(encoding="utf-8")
    governance = (ROOT / "docs" / "DOCUMENTATION_GOVERNANCE.md").read_text(encoding="utf-8")

    for phrase in ["build", "doctor", "final-pre-v4-audit"]:
        assert phrase in command_reference
    assert "4.1.1" in user_manual
    assert "parser-backend-matrix" in command_reference
    assert "old implementation notes" in governance
    assert "git history and tags" in governance

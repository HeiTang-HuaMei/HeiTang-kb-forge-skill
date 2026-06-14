from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_user_manual_has_runnable_command_examples_for_major_paths():
    text = (ROOT / "README.md").read_text(encoding="utf-8") + "\n" + (
        ROOT / "docs" / "使用指南.md"
    ).read_text(encoding="utf-8")
    required = [
        "python -m pip install -e",
        "build --input",
        "check-contract",
        "kb-query",
        "generate-documents",
        "final-pre-v4-audit",
    ]
    for command in required:
        assert command in text


def test_command_reference_covers_major_cli_commands():
    text = (ROOT / "README.md").read_text(encoding="utf-8") + "\n" + (
        ROOT / "docs" / "使用指南.md"
    ).read_text(encoding="utf-8")
    for command in ["doctor", "build", "kb-query", "generate-documents", "final-pre-v4-audit"]:
        assert command in text

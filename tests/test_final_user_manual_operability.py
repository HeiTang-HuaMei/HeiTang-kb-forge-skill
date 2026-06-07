from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_user_manual_has_runnable_command_examples_for_major_paths():
    text = (ROOT / "docs" / "USER_MANUAL.md").read_text(encoding="utf-8")
    required = [
        "python -m pip install -e",
        "build --input",
        "check-contract",
        "kb-query",
        "rewrite-query",
        "plan-retrieval",
        "eval-retrieval",
        "verify-claims",
        "generate-documents",
        "generate-agent",
        "run-local-agent",
        "init-workspace",
        "run-golden-demo-acceptance",
        "product-hardening",
        "final-pre-v4-audit",
    ]
    for command in required:
        assert command in text


def test_command_reference_covers_major_cli_commands():
    text = (ROOT / "docs" / "COMMAND_REFERENCE.md").read_text(encoding="utf-8")
    for command in ["doctor", "build", "kb-answer", "generate-documents", "run-local-agent", "product-hardening", "final-pre-v4-audit"]:
        assert command in text

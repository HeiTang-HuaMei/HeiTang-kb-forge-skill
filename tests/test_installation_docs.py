from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_installation_and_quickstart_are_kept_in_readme_and_user_manual():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    user_manual = (ROOT / "docs" / "USER_MANUAL.md").read_text(encoding="utf-8")

    for text in [readme, user_manual]:
        assert "python -m pip install -e" in text
        assert ".[dev]" in text
    assert "doctor --output" in readme
    assert "build --input" in readme
    assert "final-pre-v4-audit" in readme

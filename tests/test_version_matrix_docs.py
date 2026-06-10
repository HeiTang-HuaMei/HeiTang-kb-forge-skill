from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_version_matrix_covers_release_history_and_planned_versions():
    text = (ROOT / "docs" / "VERSION_MATRIX.md").read_text(encoding="utf-8")
    for version in ["v1.6", "v1.7", "v1.8", "v1.9", "v2.0", "v2.1", "v2.2", "v2.3", "v2.3.1-dev", "v2.4", "v2.4.1-dev", "v2.5.0-dev", "v2.5.1-alpha.1", "v2.6.0-alpha.1", "v2.7.0-alpha.1", "v4.0.0-rc.1", "v4.0.0", "v4.1.0", "runtime compatibility planned", "v2.8 planned", "v2.9 planned", "v3.x planned"]:
        assert version in text
    assert "| v2.6.0-alpha.1 | Implemented |" in text
    assert "| v2.7.0-alpha.1 | Implemented |" in text
    assert "| v4.0.0-rc.1 | Historical |" in text
    assert "| v4.0.0 | Historical |" in text
    assert "| v4.1.0 | Current |" in text
    assert "offline export / mock publish" in text
    assert "local release quality gate" in text

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_changelog_records_real_completed_work_without_future_completion_claims():
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    assert "## v2.9.0-alpha.1" in text
    assert "Knowledge Runtime Loop" in text
    assert "kb-answer" in text
    assert "## v2.8.0-alpha.1" in text
    assert "parser backend" in text
    assert "knowledge reliability" in text
    assert "## v2.7.0-alpha.1" in text
    assert "demo-e2e" in text
    assert "## v2.6.0-alpha.1" in text
    assert "llm-live-smoke" in text
    assert "provider-security-audit" in text
    assert "## v2.5.1-alpha.1" in text
    assert "version alignment" in text
    assert "CLI architecture first split" in text
    assert "runtime compatibility smoke remains not implemented" in text.lower()
    assert "production-ready" not in text

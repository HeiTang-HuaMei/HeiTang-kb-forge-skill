from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_keep_golden_demo_as_evidence_not_legacy_doc():
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    governance = (ROOT / "docs" / "治理" / "历史版本说明.md").read_text(encoding="utf-8")

    assert "Golden Demo" in changelog
    assert "Git history" in governance
    assert "旧 Campaign 中间证据" in governance

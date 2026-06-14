from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_version_matrix_covers_release_history_and_planned_versions():
    text = (ROOT / "docs" / "治理" / "历史版本说明.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "路线图.md").read_text(encoding="utf-8")
    summary = text + "\n" + roadmap
    for version in ["v4.0.0", "v4.1.1", "v4.2"]:
        assert version in summary
    assert "4.2.0" in summary
    assert "Git history" in summary
    assert "历史 tag" in summary
    assert "Campaign 4" in roadmap
    assert "Campaign 9" in roadmap

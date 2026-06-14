from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_legacy_v12_process_docs_are_not_kept_on_main():
    governance = (ROOT / "docs" / "治理" / "历史版本说明.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "路线图.md").read_text(encoding="utf-8")

    assert "历史证据保留方式" in governance
    assert "Git history" in governance
    assert "历史 tag" in governance
    assert "当前 v4.2 基线" in roadmap
    assert "Campaign 4" in roadmap

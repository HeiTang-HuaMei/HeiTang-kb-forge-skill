from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_agent_integration_docs_cover_required_targets_and_boundaries():
    text = (ROOT / "docs" / "Skill与Agent生成说明.md").read_text(encoding="utf-8") + "\n" + (
        ROOT / "docs" / "产品定位.md"
    ).read_text(encoding="utf-8")

    assert "Agent Creation Package" in text
    assert "Agent Runtime" in text
    assert "Agent Package" in text
    assert "runtime ready" in text
    assert "不默认上传用户资料" in text

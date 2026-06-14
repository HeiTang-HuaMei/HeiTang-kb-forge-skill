from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_agent_tool_and_mcp_docs_describe_local_boundaries():
    text = (ROOT / "docs" / "Skill与Agent生成说明.md").read_text(encoding="utf-8") + "\n" + (
        ROOT / "docs" / "路线图.md"
    ).read_text(encoding="utf-8")

    assert "Agent Creation Package" in text
    assert "Agent Runtime" in text
    assert "Campaign 6" in text
    assert "Agent package 不等于 executable runtime" in text
    assert "runtime ready" in text

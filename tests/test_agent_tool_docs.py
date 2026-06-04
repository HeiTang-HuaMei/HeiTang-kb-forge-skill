from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_agent_tool_and_mcp_docs_describe_local_boundaries():
    tool_doc = (ROOT / "docs" / "AGENT_TOOL_INTERFACE_GUIDE.md").read_text(encoding="utf-8")
    mcp_doc = (ROOT / "docs" / "MCP_READINESS_GUIDE.md").read_text(encoding="utf-8")

    assert "retrieve_knowledge" in tool_doc
    assert "tool_registry.yaml" in tool_doc
    assert "No external Agent platform calls" in tool_doc
    assert "mcp_server_config.yaml" in mcp_doc
    assert "does not start an MCP server" in mcp_doc

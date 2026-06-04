from heitang_kb_forge.agent_tools.registry import TOOL_NAMES, get_agent_tool, list_agent_tools


def test_agent_tools_registry_contains_required_tools():
    tools = list_agent_tools()
    names = {tool.name for tool in tools}

    assert set(TOOL_NAMES) <= names
    assert get_agent_tool("retrieve_knowledge").description

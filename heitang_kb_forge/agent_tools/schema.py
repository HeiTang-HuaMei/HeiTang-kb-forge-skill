from heitang_kb_forge.agent_tools.exporter import make_tool_exports


def agent_tool_schema() -> dict:
    _registry, _manifest, schema, _policy = make_tool_exports()
    return schema

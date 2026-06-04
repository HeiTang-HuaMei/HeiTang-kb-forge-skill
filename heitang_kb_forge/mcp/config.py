from heitang_kb_forge.agent_tools.registry import list_agent_tools
from heitang_kb_forge.schemas.mcp_schema import MCPServerConfig


MCP_OUTPUT_FILES = ["mcp_server_config.yaml", "mcp_tools_manifest.json"]


def make_mcp_config() -> tuple[str, dict]:
    config = MCPServerConfig()
    yaml_text = f"""server_name: {config.server_name}
command: {config.command}
description: {config.description}
tools_manifest: {config.tools_manifest}
"""
    tools_manifest = {
        "mcp_tools_manifest_version": "1.6.0",
        "tools": [tool.model_dump(mode="json") for tool in list_agent_tools()],
    }
    return yaml_text, tools_manifest

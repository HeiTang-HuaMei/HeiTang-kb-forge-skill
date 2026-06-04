from pydantic import BaseModel


class MCPServerConfig(BaseModel):
    mcp_version: str = "1.6.0"
    server_name: str = "heitang-kb-forge-skill"
    command: str = "heitang-kb-forge"
    description: str = "Local Agent-callable knowledge supply-chain Skill tools."
    tools_manifest: str = "mcp_tools_manifest.json"

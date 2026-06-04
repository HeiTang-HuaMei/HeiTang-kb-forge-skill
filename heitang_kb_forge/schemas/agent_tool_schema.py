from pydantic import BaseModel, Field


class AgentTool(BaseModel):
    name: str
    description: str
    input_schema: dict = Field(default_factory=dict)
    output_schema: dict = Field(default_factory=dict)
    safety_notes: list[str] = Field(default_factory=list)


class ToolManifest(BaseModel):
    tool_manifest_version: str = "1.6.0"
    tools: list[AgentTool]

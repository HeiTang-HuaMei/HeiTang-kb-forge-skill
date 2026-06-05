from pydantic import BaseModel, Field


class AgentCompatResult(BaseModel):
    status: str
    generated_files: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)

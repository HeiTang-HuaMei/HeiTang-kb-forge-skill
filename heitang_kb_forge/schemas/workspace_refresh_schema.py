from pydantic import BaseModel, Field


class WorkspaceRefreshResult(BaseModel):
    workspace: str
    changed_sources: int = 0
    stale_packages: int = 0
    impacted_packages: list[dict] = Field(default_factory=list)
    impacted_skills: list[dict] = Field(default_factory=list)
    impacted_agents: list[dict] = Field(default_factory=list)

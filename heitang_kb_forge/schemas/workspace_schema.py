from datetime import datetime, timezone

from pydantic import BaseModel, Field


class WorkspaceManifest(BaseModel):
    workspace_id: str
    workspace_version: str = "1.9"
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    root_path: str
    package_count: int = 0
    skill_count: int = 0
    agent_count: int = 0
    provider_count: int = 0
    prompt_profile_count: int = 0
    health_status: str = "not_checked"

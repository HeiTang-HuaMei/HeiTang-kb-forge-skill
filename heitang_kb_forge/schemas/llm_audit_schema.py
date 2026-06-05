from datetime import datetime, timezone

from pydantic import BaseModel, Field


class LLMCallAuditRecord(BaseModel):
    call_id: str
    workspace_id: str
    package_id: str | None = None
    skill_id: str | None = None
    agent_id: str | None = None
    provider_id: str | None = None
    prompt_profile_id: str | None = None
    task: str = "other"
    status: str = "success"
    input_summary: str = ""
    output_summary: str = ""
    review_required: bool = False
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

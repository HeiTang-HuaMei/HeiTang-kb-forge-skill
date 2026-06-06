from datetime import datetime, timezone

from pydantic import BaseModel, Field


class AgentPackageProfile(BaseModel):
    agent_id: str
    agent_name: str
    agent_type: str
    source_skill_id: str
    source_package_id: str
    kb_trust_status: str = "legacy_untracked"
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    evidence_policy: str = "answers must be grounded in the source knowledge package"
    retrieval_policy: str = "use retrieval_index and context_pack before answering"
    safety_policy: str = "refuse unsupported requests"

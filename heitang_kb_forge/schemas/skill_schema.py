from datetime import datetime, timezone

from pydantic import BaseModel, Field


class SkillManifest(BaseModel):
    skill_id: str
    skill_name: str
    skill_version: str = "1.8.0"
    source_package_id: str
    source_contract_version: str | None = None
    kb_trust_status: str = "legacy_untracked"
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    supported_tasks: list[str] = Field(default_factory=list)
    required_assets: list[str] = Field(default_factory=list)
    evidence_policy: str = "cite package evidence for factual answers"
    boundary_policy: str = "refuse or ask for review outside package scope"
    validation_status: str = "not_validated"


class SkillGenerationResult(BaseModel):
    skill_id: str
    skill_name: str
    output_files: list[str]
    generated_by: str
    warnings: list[str] = Field(default_factory=list)

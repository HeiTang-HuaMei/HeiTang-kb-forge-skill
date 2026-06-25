from pydantic import BaseModel, Field


class PolicyGovernanceReport(BaseModel):
    schema_version: str = "policy_governance_basic.v1"
    status: str
    required_files: list[str]
    missing_files: list[str] = Field(default_factory=list)
    failed_checks: list[str] = Field(default_factory=list)
    queue_status: dict = Field(default_factory=dict)
    status_vocabulary: dict = Field(default_factory=dict)
    blocker_policy: dict = Field(default_factory=dict)
    forbidden_claims: dict = Field(default_factory=dict)
    boundary: dict = Field(default_factory=dict)

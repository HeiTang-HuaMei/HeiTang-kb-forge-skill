from pydantic import BaseModel, Field


class RoleProtocolRole(BaseModel):
    role_id: str
    responsibilities: list[str] = Field(default_factory=list)
    input_contract: dict = Field(default_factory=dict)
    output_contract: dict = Field(default_factory=dict)
    allowed_actions: list[str] = Field(default_factory=list)
    forbidden_actions: list[str] = Field(default_factory=list)
    evidence_requirements: list[str] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)


class RoleProtocolSpec(BaseModel):
    protocol_id: str = "thinker_worker_verifier_basic"
    roles: list[RoleProtocolRole]
    handoff_contract: dict = Field(default_factory=dict)
    approval_rules: dict = Field(default_factory=dict)
    boundary: dict = Field(default_factory=dict)


class RoleProtocolReport(BaseModel):
    schema_version: str = "role_protocol_basic.v1"
    status: str
    protocol_id: str
    role_count: int
    required_roles: list[str] = Field(default_factory=list)
    failed_checks: list[str] = Field(default_factory=list)
    role_summaries: list[dict] = Field(default_factory=list)
    handoff_contract: dict = Field(default_factory=dict)
    approval_rules: dict = Field(default_factory=dict)
    output_files: list[str] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)

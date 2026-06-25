from pydantic import BaseModel, Field


class StopHandoffGateReport(BaseModel):
    schema_version: str = "stop_handoff_gate.v1"
    status: str
    current_phase: str | None = None
    current_gate: str | None = None
    next_gate: str | None = None
    required_files: list[str]
    missing_files: list[str] = Field(default_factory=list)
    failed_checks: list[str] = Field(default_factory=list)
    queue_status: dict = Field(default_factory=dict)
    handoff_contract: dict = Field(default_factory=dict)
    registry_status: dict = Field(default_factory=dict)
    blocker_policy: dict = Field(default_factory=dict)
    forbidden_claims: dict = Field(default_factory=dict)
    boundary: dict = Field(default_factory=dict)
    output_files: list[str] = Field(default_factory=list)

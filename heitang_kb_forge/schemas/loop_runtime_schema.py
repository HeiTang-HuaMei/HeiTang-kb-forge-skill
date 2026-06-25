from pydantic import BaseModel, Field


class LoopRuntimeStep(BaseModel):
    step_id: str
    title: str
    status: str = "ready"
    depends_on: list[str] = Field(default_factory=list)
    allowed_next_statuses: list[str] = Field(default_factory=list)
    required_evidence: list[str] = Field(default_factory=list)


class LoopRuntimeSpec(BaseModel):
    runtime_id: str = "loop_runtime_basic"
    steps: list[LoopRuntimeStep] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)
    policy: dict = Field(default_factory=dict)


class LoopRuntimeReport(BaseModel):
    schema_version: str = "loop_runtime_basic.v1"
    status: str
    runtime_id: str
    step_count: int = 0
    execution_order: list[str] = Field(default_factory=list)
    completed_step_ids: list[str] = Field(default_factory=list)
    blocked_step_ids: list[str] = Field(default_factory=list)
    needs_owner_review_step_ids: list[str] = Field(default_factory=list)
    failed_checks: list[str] = Field(default_factory=list)
    step_summaries: list[dict] = Field(default_factory=list)
    policy: dict = Field(default_factory=dict)
    boundary: dict = Field(default_factory=dict)
    output_files: list[str] = Field(default_factory=list)

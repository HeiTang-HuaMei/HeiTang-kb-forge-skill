from pydantic import BaseModel, Field


class LoopCostBoundaryPolicy(BaseModel):
    policy_id: str = "loop_cost_boundary_basic"
    max_repair_rounds: int = 3
    max_network_retry_rounds: int = 5
    retry_wait_seconds: list[int] = Field(default_factory=lambda: [10, 30, 60, 120, 300])
    allow_default_network: bool = False
    allow_external_service_call: bool = False
    allow_local_model: bool = False
    allow_gpu: bool = False
    allow_redis_service_packaging: bool = False
    allow_vector_service_packaging: bool = False
    require_checkpoint_on_exhaustion: bool = True
    require_failure_report_on_exhaustion: bool = True
    require_resume_prompt_on_exhaustion: bool = True


class LoopCostBoundaryReport(BaseModel):
    schema_version: str = "loop_cost_boundary_basic.v1"
    status: str
    policy_id: str
    failed_checks: list[str] = Field(default_factory=list)
    policy_summary: dict = Field(default_factory=dict)
    retry_plan: dict = Field(default_factory=dict)
    blocker_policy: dict = Field(default_factory=dict)
    boundary: dict = Field(default_factory=dict)
    output_files: list[str] = Field(default_factory=list)

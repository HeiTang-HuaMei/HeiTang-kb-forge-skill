from pydantic import BaseModel, Field


class ModelPoolCandidate(BaseModel):
    model_id: str
    provider_id: str = "mock_default"
    provider_type: str = "mock"
    model_name: str = "mock-model"
    capabilities: list[str] = Field(default_factory=list)
    enabled: bool = True
    health_status: str = "ready"
    network_required: bool = False
    priority: int = 100


class ModelPoolRoutingRequest(BaseModel):
    task_type: str
    required_capabilities: list[str] = Field(default_factory=list)
    preferred_provider_id: str | None = None
    allow_network: bool = False


class ModelPoolRoutingReport(BaseModel):
    schema_version: str = "model_pool_router_basic.v1"
    status: str
    selected_model_id: str | None = None
    selected_provider_id: str | None = None
    selected_model_name: str | None = None
    candidate_count: int = 0
    eligible_count: int = 0
    failed_checks: list[str] = Field(default_factory=list)
    routing_trace: list[dict] = Field(default_factory=list)
    output_files: list[str] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)

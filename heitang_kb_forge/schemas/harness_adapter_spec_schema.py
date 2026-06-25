from pydantic import BaseModel, Field


class HarnessAdapterSpec(BaseModel):
    adapter_id: str
    capability_id: str
    execution_mode: str
    input_contract: dict
    output_contract: dict
    boundary: dict
    required_reports: list[str] = Field(default_factory=list)


class HarnessAdapterSpecReport(BaseModel):
    schema_version: str = "harness_adapter_spec.v1"
    status: str
    adapter_count: int
    failed_checks: list[str] = Field(default_factory=list)
    adapter_summaries: list[dict] = Field(default_factory=list)
    allowed_capability_ids: list[str] = Field(default_factory=list)
    allowed_execution_modes: list[str] = Field(default_factory=list)
    required_fields: list[str] = Field(default_factory=list)
    output_files: list[str] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)

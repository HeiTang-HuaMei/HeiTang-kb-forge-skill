from datetime import datetime, timezone

from pydantic import BaseModel, Field


class PipelineStage(BaseModel):
    name: str
    enabled: bool
    status: str
    output_files: list[str] = Field(default_factory=list)


class PipelineManifest(BaseModel):
    pipeline_version: str = "0.8.3"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    config_file: str
    task: str
    input: str
    output: str
    domain: str
    mode: str
    stages: list[PipelineStage]
    final_status: str
    warnings: list[str] = Field(default_factory=list)

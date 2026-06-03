from datetime import datetime, timezone

from pydantic import BaseModel, Field


class DemoManifest(BaseModel):
    demo_version: str = "0.8.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    package_path: str
    domain: str
    mode: str
    source_count: int
    chunk_count: int
    quality_score: int | None
    quality_level: str | None
    rag_export_enabled: bool
    agent_template_enabled: bool
    eval_cases_count: int
    final_status: str
    warnings: list[str] = Field(default_factory=list)


class EvalSummary(BaseModel):
    eval_version: str = "0.8.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    eval_cases_file: str | None = None
    eval_cases_count: int
    required_citation_count: int
    source_path_coverage: float
    chunk_id_coverage: float
    status: str
    warnings: list[str] = Field(default_factory=list)


class DemoResult(BaseModel):
    output_files: list[str]
    demo_report: str
    demo_manifest: DemoManifest
    eval_summary: EvalSummary

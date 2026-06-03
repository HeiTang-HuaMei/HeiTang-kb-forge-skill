from datetime import datetime, timezone

from pydantic import BaseModel, Field


class LLMQualityReport(BaseModel):
    llm_quality_version: str = "0.5.3"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    provider: str
    model: str
    prompt_profile: str | None = None
    prompt_profile_hash: str | None = None
    total_llm_records: int
    asset_type_counts: dict[str, int]
    empty_output_count: int
    missing_citation_count: int
    missing_source_path_count: int
    missing_chunk_id_count: int
    missing_confidence_count: int
    missing_token_usage_count: int
    duplicate_count: int
    schema_warning_count: int
    citation_coverage: float
    source_path_coverage: float
    chunk_id_coverage: float
    confidence_coverage: float
    token_usage_coverage: float
    cache_key_coverage: float
    groundedness_proxy_score: int
    completeness_proxy_score: int
    metadata_coverage_score: int
    llm_quality_score: int
    llm_quality_level: str
    warnings: list[str] = Field(default_factory=list)


class LLMQualityResult(BaseModel):
    output_files: list[str]
    report: LLMQualityReport
    summary: str

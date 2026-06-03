from pydantic import BaseModel, Field


class PackageValidationReport(BaseModel):
    validation_version: str = "1.0.0"
    package_path: str
    standard_files_present: bool
    missing_files: list[str] = Field(default_factory=list)
    citation_coverage: float = 0.0
    source_path_coverage: float = 0.0
    chunk_id_coverage: float = 0.0
    unsupported_asset_count: int = 0
    missing_citation_asset_count: int = 0
    low_confidence_asset_count: int = 0
    ocr_low_confidence_warning_count: int = 0
    table_extraction_warning_count: int = 0
    readiness_for_rag: str = "warning"
    readiness_for_embedding: str = "warning"
    readiness_for_agent_template: str = "warning"
    readiness_for_downstream_export: str = "warning"
    readiness_level: str = "warning"
    hallucination_risk_level: str = "medium"
    warnings: list[str] = Field(default_factory=list)

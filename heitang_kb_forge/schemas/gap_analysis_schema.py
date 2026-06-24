from pydantic import BaseModel, Field


class GapAnalysisInput(BaseModel):
    required_claims: list[str] = Field(default_factory=list)
    evidence_claims: list[str] = Field(default_factory=list)
    required_rules: list[str] = Field(default_factory=list)
    evidence_rules: list[str] = Field(default_factory=list)
    required_sources: list[str] = Field(default_factory=list)
    evidence_sources: list[str] = Field(default_factory=list)


class GapAnalysisReport(BaseModel):
    gap_analysis_version: str = "1.0.0"
    status: str
    missing_claims: list[str] = Field(default_factory=list)
    missing_rules: list[str] = Field(default_factory=list)
    missing_sources: list[str] = Field(default_factory=list)
    covered_claims: list[str] = Field(default_factory=list)
    covered_rules: list[str] = Field(default_factory=list)
    covered_sources: list[str] = Field(default_factory=list)
    gap_count: int = 0
    summary: str

from pydantic import BaseModel, Field


class ReliabilityEvalInput(BaseModel):
    evidence_graph_status: str
    evidence_graph_entity_count: int = 0
    gap_status: str
    gap_count: int = 0
    citation_status: str
    citation_coverage: float = 0.0
    minimum_citation_coverage: float = 0.8


class ReliabilityEvalDimension(BaseModel):
    dimension: str
    status: str
    score: int
    reason: str


class ReliabilityEvalReport(BaseModel):
    reliability_eval_version: str = "1.0.0"
    status: str
    overall_score: int
    available_for_next_gate: bool
    dimensions: list[ReliabilityEvalDimension] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    summary: str

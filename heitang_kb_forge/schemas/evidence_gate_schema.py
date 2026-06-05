from datetime import datetime, timezone

from pydantic import BaseModel, Field


class EvidenceGateResult(BaseModel):
    evidence_gate_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    package: str
    query: str
    decision: str
    reason: str
    evidence_ids: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)


class LLMEvidenceValidation(BaseModel):
    validation_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    provider: str
    model: str
    status: str
    supported: bool
    confidence: float
    reason: str


class LLMBoundaryJudgment(BaseModel):
    boundary_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    provider: str
    model: str
    status: str
    boundary: str
    reason: str


class LLMHallucinationCheck(BaseModel):
    hallucination_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    provider: str
    model: str
    status: str
    risk_level: str
    reason: str

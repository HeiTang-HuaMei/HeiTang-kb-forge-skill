from pydantic import BaseModel, Field


class QualityGateFinding(BaseModel):
    gate: str
    severity: str
    message: str


class QualityGateResult(BaseModel):
    status: str
    release_ready: bool
    overall_score: int
    gates: dict[str, str] = Field(default_factory=dict)
    blockers: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    recommendations: list[str] = Field(default_factory=list)


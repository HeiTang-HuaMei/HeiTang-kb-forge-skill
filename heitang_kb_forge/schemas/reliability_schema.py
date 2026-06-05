from pydantic import BaseModel, Field


class ReliabilityScore(BaseModel):
    overall_score: int
    status: str
    scores: dict[str, int]
    release_ready: bool
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)

from pydantic import BaseModel, Field


class ReleaseReadinessResult(BaseModel):
    status: str
    release_ready: bool
    overall_score: int
    inputs: dict[str, str] = Field(default_factory=dict)
    critical_blockers: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    next_actions: list[str] = Field(default_factory=list)


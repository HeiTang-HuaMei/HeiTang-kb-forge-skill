from pydantic import BaseModel, Field


class ReleaseBlockerFinding(BaseModel):
    blocker_type: str
    severity: str
    message: str
    path: str | None = None


class ReleaseBlockerResult(BaseModel):
    status: str
    release_ready: bool
    blocker_count: int
    critical_count: int
    blockers: list[ReleaseBlockerFinding] = Field(default_factory=list)


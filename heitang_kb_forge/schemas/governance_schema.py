from datetime import datetime, timezone

from pydantic import BaseModel, Field


class PackageDiff(BaseModel):
    diff_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    old_package: str | None = None
    new_package: str
    added: list[str] = Field(default_factory=list)
    removed: list[str] = Field(default_factory=list)
    changed: list[str] = Field(default_factory=list)
    unchanged: list[str] = Field(default_factory=list)


class LifecycleManifest(BaseModel):
    lifecycle_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    package: str
    active_count: int
    review_required_count: int
    stale_count: int


class GovernanceReport(BaseModel):
    governance_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    package: str
    status: str
    warnings: list[str] = Field(default_factory=list)
    output_files: list[str] = Field(default_factory=list)

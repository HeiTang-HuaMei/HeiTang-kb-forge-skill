from datetime import datetime, timezone

from pydantic import BaseModel, Field


class SourceRecord(BaseModel):
    source_id: str
    source_path: str
    relative_path: str
    source_name: str
    extension: str
    size_bytes: int
    modified_at: str
    content_hash: str
    status: str = "present"


class SourceRegistry(BaseModel):
    registry_version: str = "1.3.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    input_path: str
    source_count: int
    sources: list[SourceRecord]


class SourceChangeReport(BaseModel):
    change_report_version: str = "1.3.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    previous_source_count: int
    current_source_count: int
    changed_count: int
    missing_count: int
    new_count: int
    unchanged_count: int
    warnings: list[str] = Field(default_factory=list)

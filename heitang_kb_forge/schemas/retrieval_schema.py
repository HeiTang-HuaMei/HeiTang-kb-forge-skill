from datetime import datetime, timezone

from pydantic import BaseModel, Field


class RetrievalIndexRecord(BaseModel):
    retrieval_id: str
    asset_type: str
    text: str
    source_path: str
    chunk_id: str | None = None
    citation: str | None = None
    keywords: list[str] = Field(default_factory=list)
    confidence: str = "medium"
    review_required: bool = False


class RetrievalManifest(BaseModel):
    retrieval_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    package: str
    total_records: int
    asset_type_counts: dict[str, int]


class RetrievalTrace(BaseModel):
    trace_version: str = "1.7.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    query: str
    route: str
    selected_ids: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)

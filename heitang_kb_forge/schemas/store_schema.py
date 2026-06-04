from datetime import datetime, timezone

from pydantic import BaseModel, Field


class StoreManifest(BaseModel):
    store_version: str = "1.4.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    db_path: str
    package_count: int
    source_count: int
    chunk_count: int


class StorePackageRecord(BaseModel):
    package_id: str
    package_path: str
    package_name: str
    domain: str | None = None
    mode: str | None = None
    source_count: int = 0
    chunk_count: int = 0
    quality_score: int | None = None
    quality_level: str | None = None
    agent_type: str | None = None


class StoreQueryResult(BaseModel):
    query_version: str = "1.4.0"
    filters: dict
    total: int
    packages: list[StorePackageRecord]

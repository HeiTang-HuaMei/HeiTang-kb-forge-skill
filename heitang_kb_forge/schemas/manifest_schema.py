from datetime import datetime, timezone

from pydantic import BaseModel, Field


class Manifest(BaseModel):
    package_version: str = "0.1.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    domain: str
    mode: str
    source_count: int
    chunk_count: int
    card_count: int
    qa_pair_count: int
    glossary_count: int
    files: list[str]
    warnings: list[str] = Field(default_factory=list)

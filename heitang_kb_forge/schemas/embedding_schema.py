from datetime import datetime, timezone

from pydantic import BaseModel, Field


class EmbeddingRecord(BaseModel):
    embedding_id: str
    text_hash: str
    vector: list[float]
    dimensions: int
    provider: str
    model: str
    source_asset_type: str
    source_path: str
    chunk_id: str
    citation: str
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class EmbeddingManifest(BaseModel):
    embedding_version: str = "0.9.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    provider: str
    model: str
    dimensions: int
    total_records: int
    source_file: str = "embedding_input.jsonl"
    output_file: str = "embeddings.jsonl"
    warnings: list[str] = Field(default_factory=list)

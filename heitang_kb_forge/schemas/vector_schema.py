from datetime import datetime, timezone

from pydantic import BaseModel, Field


class VectorStoreRecord(BaseModel):
    vector_record_id: str
    embedding_id: str
    vector: list[float]
    metadata: dict
    store: str
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class VectorStoreManifest(BaseModel):
    vector_store_version: str = "0.9.0"
    generated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    store: str
    total_records: int
    input_file: str = "embeddings.jsonl"
    output_file: str = "vector_store_records.jsonl"
    compatible_targets: list[str] = Field(default_factory=lambda: ["faiss", "chroma", "qdrant", "milvus"])
    warnings: list[str] = Field(default_factory=list)

from pydantic import BaseModel, Field


class EmbeddingInputRecord(BaseModel):
    embedding_id: str
    text: str = Field(min_length=1)
    asset_type: str
    source_path: str
    chunk_id: str
    citation: str
    title: str | None = None
    metadata: dict = Field(default_factory=dict)
    quality_score: int | None = None
    created_at: str


class RetrievalMetadataRecord(BaseModel):
    embedding_id: str
    asset_type: str
    source_path: str
    chunk_id: str
    citation: str
    domain: str
    mode: str
    quality_score: int | None = None
    quality_level: str | None = None
    tags: list[str] = Field(default_factory=list)
    provider: str | None = None
    model: str | None = None
    from_llm: bool = False
    source_file_type: str | None = None

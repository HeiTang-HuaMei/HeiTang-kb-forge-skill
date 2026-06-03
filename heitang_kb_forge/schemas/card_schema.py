from pydantic import BaseModel, Field


class KnowledgeCard(BaseModel):
    card_id: str
    chunk_id: str
    title: str
    summary: str = Field(min_length=1)
    source_path: str
    domain: str
    mode: str
    card_type: str | None = None
    tags: list[str] = Field(default_factory=list)
    citation: str | None = None

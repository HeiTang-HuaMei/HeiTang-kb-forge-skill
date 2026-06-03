from pydantic import BaseModel, Field


class LLMRecord(BaseModel):
    llm_id: str
    extraction_type: str
    source_path: str
    chunk_id: str
    citation: str
    llm_provider: str
    llm_model: str
    confidence: float = Field(ge=0, le=1)
    token_usage: dict[str, int]
    cache_key: str
    generated_at: str

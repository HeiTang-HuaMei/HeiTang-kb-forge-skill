from pydantic import BaseModel, Field


class Chunk(BaseModel):
    chunk_id: str
    source_path: str
    source_type: str
    domain: str
    mode: str
    title: str | None = None
    text: str = Field(min_length=1)
    order: int = Field(ge=0)
    char_count: int = Field(ge=1)
    metadata: dict[str, str | int | float | bool | None] = Field(default_factory=dict)

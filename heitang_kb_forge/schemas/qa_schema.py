from pydantic import BaseModel, Field


class QAPair(BaseModel):
    qa_id: str
    chunk_id: str
    question: str = Field(min_length=1)
    answer: str = Field(min_length=1)
    source_path: str
    domain: str
    mode: str

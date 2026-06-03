from pydantic import BaseModel, Field


class RetrievedRecord(BaseModel):
    record_id: str
    text: str
    score: int
    source_path: str
    chunk_id: str
    citation: str


class AnswerReport(BaseModel):
    runtime_version: str = "1.1.0"
    query: str
    provider: str
    model: str
    answer_file: str = "answer.md"
    retrieval_trace_file: str = "retrieval_trace.json"
    citations: list[str] = Field(default_factory=list)
    insufficient_context: bool = False

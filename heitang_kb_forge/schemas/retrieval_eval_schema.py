from pydantic import BaseModel


class RetrievalEvalRecord(BaseModel):
    question: str
    expected_chunk_id: str
    expected_citation: str
    answer_hint: str
    difficulty: str = "easy"
    source_path: str
    asset_type: str

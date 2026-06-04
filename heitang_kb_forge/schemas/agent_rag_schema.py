from pydantic import BaseModel, Field


class AgentRAGRecord(BaseModel):
    embedding_id: str
    text: str
    asset_type: str
    source_path: str
    chunk_id: str
    citation: str
    score: int = 0
    metadata: dict = Field(default_factory=dict)


class AgentRAGAnswerReport(BaseModel):
    agent_rag_version: str = "1.5.0"
    query: str
    top_k: int
    citation_required: bool = False
    insufficient_context: bool = False
    citation_count: int = 0
    output_files: list[str] = Field(default_factory=list)

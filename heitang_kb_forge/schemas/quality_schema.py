from pydantic import BaseModel


class KnowledgeQualityReport(BaseModel):
    status: str
    overall_score: int

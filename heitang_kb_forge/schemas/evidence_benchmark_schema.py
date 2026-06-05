from pydantic import BaseModel


class EvidenceBenchmarkResult(BaseModel):
    status: str
    case_count: int

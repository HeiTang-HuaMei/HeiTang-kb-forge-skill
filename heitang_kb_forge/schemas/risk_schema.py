from pydantic import BaseModel


class RiskLabelRecord(BaseModel):
    risk_id: str
    label: str
    severity: str
    reason: str
    source_path: str
    chunk_id: str
    citation: str

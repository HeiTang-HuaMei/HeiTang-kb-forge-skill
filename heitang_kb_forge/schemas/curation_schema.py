from pydantic import BaseModel, Field


class GovernanceDecision(BaseModel):
    decision_id: str
    item_id: str
    item_type: str = "chunk"
    decision: str = "accept"
    reason: str = "Included by default curation policy."
    reviewer: str = "system"
    created_at: str
    source_evidence_refs: list[str] = Field(default_factory=list)
    output_item_id: str = ""

from pydantic import BaseModel, Field


class ClassificationCandidate(BaseModel):
    item_id: str
    text: str
    source_id: str = ""
    labels: list[str] = Field(default_factory=list)


class ClassificationDecision(BaseModel):
    item_id: str
    category: str
    confidence: float
    reason_codes: list[str] = Field(default_factory=list)
    matched_terms: list[str] = Field(default_factory=list)
    source_id: str = ""


class ClassificationReasoningInput(BaseModel):
    candidates: list[ClassificationCandidate] = Field(default_factory=list)
    allowed_categories: list[str] = Field(default_factory=list)


class ClassificationReasoningReport(BaseModel):
    classification_reasoning_version: str = "1.0.0"
    status: str
    decision_count: int = 0
    decisions: list[ClassificationDecision] = Field(default_factory=list)
    unresolved_item_ids: list[str] = Field(default_factory=list)
    category_counts: dict[str, int] = Field(default_factory=dict)
    summary: str

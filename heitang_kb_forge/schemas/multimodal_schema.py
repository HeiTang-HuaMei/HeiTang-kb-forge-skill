from pydantic import BaseModel, Field


class MultimodalAsset(BaseModel):
    asset_id: str
    asset_type: str
    source_file: str
    page_number: int | None = None
    slide_number: int | None = None
    bbox: list[float] | None = None
    extracted_text: str = ""
    description: str = ""
    structure: dict = Field(default_factory=dict)
    evidence_refs: list[str] = Field(default_factory=list)
    confidence: str = "low"
    extraction_method: str = "fallback"
    review_required: bool = True
    asset_refs: list[str] = Field(default_factory=list)
    metadata: dict = Field(default_factory=dict)

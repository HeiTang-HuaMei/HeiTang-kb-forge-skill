from pydantic import BaseModel, Field


class RuleExtractionSource(BaseModel):
    source_id: str
    text: str
    source_path: str = ""
    scope_id: str = ""


class ExtractedRule(BaseModel):
    rule_id: str
    rule_type: str
    text: str
    source_id: str
    source_path: str = ""
    scope_id: str = ""
    marker: str


class RuleExtractionInput(BaseModel):
    sources: list[RuleExtractionSource] = Field(default_factory=list)
    allowed_scope_ids: list[str] = Field(default_factory=list)


class RuleExtractionReport(BaseModel):
    rule_extraction_version: str = "1.0.0"
    status: str
    extracted_rule_count: int = 0
    extracted_rules: list[ExtractedRule] = Field(default_factory=list)
    skipped_source_ids: list[str] = Field(default_factory=list)
    source_ids: list[str] = Field(default_factory=list)
    summary: str

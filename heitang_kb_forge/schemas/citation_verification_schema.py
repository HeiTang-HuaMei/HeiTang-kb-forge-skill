from pydantic import BaseModel, Field


class CitationClaim(BaseModel):
    claim_id: str
    text: str
    citation: str = ""
    allowed_scope_ids: list[str] = Field(default_factory=list)


class CitationSourceTraceEntry(BaseModel):
    source_id: str
    source_path: str
    chunk_id: str
    citation: str
    scope_id: str = ""


class CitationVerificationInput(BaseModel):
    claims: list[CitationClaim] = Field(default_factory=list)
    source_trace: list[CitationSourceTraceEntry] = Field(default_factory=list)
    allowed_scope_ids: list[str] = Field(default_factory=list)


class CitationVerificationReport(BaseModel):
    citation_verification_version: str = "1.0.0"
    status: str
    checked_claim_count: int = 0
    cited_claim_count: int = 0
    resolved_claim_count: int = 0
    citation_coverage: float = 0.0
    resolved_claim_ids: list[str] = Field(default_factory=list)
    missing_citation_claim_ids: list[str] = Field(default_factory=list)
    unresolved_citation_claim_ids: list[str] = Field(default_factory=list)
    out_of_scope_claim_ids: list[str] = Field(default_factory=list)
    source_trace_citations: list[str] = Field(default_factory=list)
    summary: str

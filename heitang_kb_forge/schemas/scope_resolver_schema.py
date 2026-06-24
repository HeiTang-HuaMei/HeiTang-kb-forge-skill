from pydantic import BaseModel, Field


class ScopeCandidate(BaseModel):
    scope_id: str
    labels: list[str] = Field(default_factory=list)
    is_default: bool = False


class ScopeResolverInput(BaseModel):
    query: str
    explicit_scope_id: str = ""
    allowed_scope_ids: list[str] = Field(default_factory=list)
    candidates: list[ScopeCandidate] = Field(default_factory=list)


class ScopeResolverReport(BaseModel):
    scope_resolver_version: str = "1.0.0"
    status: str
    selected_scope_id: str = ""
    selection_reason: str
    allowed_scope_ids: list[str] = Field(default_factory=list)
    candidate_scope_ids: list[str] = Field(default_factory=list)
    blocked_reason: str = ""
    summary: str

from pydantic import BaseModel, Field


class EvidenceReference(BaseModel):
    evidence_id: str
    source_path: str
    chunk_id: str
    citation: str
    title: str


class EvidenceWindow(BaseModel):
    window_id: str
    title: str
    text: str
    source_evidence: list[EvidenceReference]
    confidence: float = Field(ge=0, le=1)
    risk_flags: list[str] = Field(default_factory=list)


class EvidenceWindowBundle(BaseModel):
    evidence_window_schema_version: str = "v4.2-p2.2-1"
    source_package_id: str
    window_count: int = Field(ge=1)
    windows: list[EvidenceWindow]
    source_trace_preserved: bool = True
    tests_require_real_llm_api_network: bool = False


class MethodologyItem(BaseModel):
    item_id: str
    statement: str
    source_evidence: list[str] = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    risk_flags: list[str] = Field(default_factory=list)


class MethodologyModule(BaseModel):
    module_id: str
    title: str
    concepts: list[MethodologyItem] = Field(default_factory=list)
    principles: list[MethodologyItem] = Field(default_factory=list)
    decision_rules: list[MethodologyItem] = Field(default_factory=list)
    workflows: list[MethodologyItem] = Field(default_factory=list)
    anti_patterns: list[MethodologyItem] = Field(default_factory=list)
    constraints: list[MethodologyItem] = Field(default_factory=list)
    applicability_boundary: list[MethodologyItem] = Field(default_factory=list)
    failure_modes: list[MethodologyItem] = Field(default_factory=list)
    source_evidence: list[str] = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    risk_flags: list[str] = Field(default_factory=list)


class MethodologyMap(BaseModel):
    methodology_map_version: str = "v4.2-p2.2-1"
    source_package_id: str
    module_count: int = Field(ge=1)
    methodology_modules: list[MethodologyModule]
    concepts: list[MethodologyItem] = Field(default_factory=list)
    principles: list[MethodologyItem] = Field(default_factory=list)
    decision_rules: list[MethodologyItem] = Field(default_factory=list)
    workflows: list[MethodologyItem] = Field(default_factory=list)
    anti_patterns: list[MethodologyItem] = Field(default_factory=list)
    constraints: list[MethodologyItem] = Field(default_factory=list)
    applicability_boundary: list[MethodologyItem] = Field(default_factory=list)
    failure_modes: list[MethodologyItem] = Field(default_factory=list)
    source_evidence: list[str] = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    risk_flags: list[str] = Field(default_factory=list)
    unsupported_claim_detection: dict[str, int | str]
    tests_require_real_llm_api_network: bool = False

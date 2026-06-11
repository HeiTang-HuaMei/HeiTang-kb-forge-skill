from pydantic import BaseModel, Field


class SkillContract(BaseModel):
    purpose: str
    trigger: str
    inputs: list[str] = Field(default_factory=list)
    outputs: list[str] = Field(default_factory=list)
    workflow_steps: list[str] = Field(default_factory=list)
    constraints: list[str] = Field(default_factory=list)
    failure_modes: list[str] = Field(default_factory=list)


class MergeSplitRecommendation(BaseModel):
    action: str
    reason: str


class SkillCandidate(BaseModel):
    candidate_id: str
    title: str
    provisional_skill_type: str
    source_methodology_module: str
    supporting_evidence: list[str] = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    risk_flags: list[str] = Field(default_factory=list)
    status: str
    skill_contract: SkillContract
    merge_split_recommendation: MergeSplitRecommendation
    dependency_draft: list[str] = Field(default_factory=list)


class RejectedClaim(BaseModel):
    claim_id: str
    source_methodology_module: str
    statement: str
    reason: str
    source_evidence: list[str] = Field(default_factory=list)


class SkillCandidatePlan(BaseModel):
    skill_candidate_schema_version: str = "v4.2-p2.2-1"
    source_package_id: str
    source_methodology_version: str
    candidate_count: int = Field(ge=1)
    candidates: list[SkillCandidate]
    rejected_claims: list[RejectedClaim] = Field(default_factory=list)
    unsupported_claim_count: int = Field(ge=0)
    evidence_trace_preserved: bool = True
    anything2skill_integration: dict[str, str | bool]
    tests_require_real_llm_api_network: bool = False

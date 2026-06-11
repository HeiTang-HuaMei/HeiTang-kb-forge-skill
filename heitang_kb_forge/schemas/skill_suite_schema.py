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


class SuiteSkill(BaseModel):
    skill_id: str
    title: str
    skill_type: str
    path: str
    trigger: str
    purpose: str
    depends_on: list[str] = Field(default_factory=list)
    supporting_evidence: list[str] = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    status: str


class DependencyEdge(BaseModel):
    source: str
    target: str
    relationship: str = "depends_on"


class SkillSuiteManifest(BaseModel):
    skill_suite_version: str = "v4.2-p2.2-1"
    suite_id: str
    source_package_id: str
    skill_count: int = Field(ge=1)
    hierarchy_counts: dict[str, int]
    skills: list[SuiteSkill]
    dependency_edges: list[DependencyEdge] = Field(default_factory=list)
    duplicate_skill_groups: list[list[str]] = Field(default_factory=list)
    conflict_skill_pairs: list[list[str]] = Field(default_factory=list)
    status: str
    skillx_integration: dict[str, str | bool]
    tests_require_real_llm_api_network: bool = False


class SkillPackManifest(BaseModel):
    skill_pack_version: str = "v4.2-p2.2-1"
    suite_id: str
    status: str
    manifest_file: str = "skill_pack_manifest.json"
    files: list[str]
    file_hashes: dict[str, str]
    description_trigger_quality_status: str
    allowed_files_boundary_status: str
    suite_validation_status: str
    installability_check_status: str
    suite_governance_status: str
    anthropic_skill_creator_integration: dict[str, str | bool]
    tests_require_real_llm_api_network: bool = False

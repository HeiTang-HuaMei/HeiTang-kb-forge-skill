from pathlib import Path

from pydantic import BaseModel, ConfigDict, Field


class BatchConfig(BaseModel):
    merge_same_sequence: bool = False
    worker_pool: bool = False
    max_workers: int = 4
    memory_guard: bool = False
    max_file_size_mb: int = 500
    timeout_seconds: int = 600
    retry_failed: bool = False
    resume_batch: bool = False
    profile: str = "production"


class LLMConfig(BaseModel):
    enabled: bool = False
    provider: str = "fake"
    model: str = "fake-model"
    base_url: str | None = None
    api_key_env: str | None = None
    cache: bool = True
    strict: bool = False
    call_log: bool = True
    fail_safe: bool = True
    evidence_validation: bool = False
    boundary_check: bool = False
    hallucination_check: bool = False
    prompt_profile: Path | None = None
    quality_report: bool = False


class RAGConfig(BaseModel):
    enabled: bool = False
    profile: str = "basic"
    include_llm: bool = False


class EmbeddingConfig(BaseModel):
    enabled: bool = False
    provider: str = "fake"
    model: str = "fake-embedding-model"


class VectorConfig(BaseModel):
    enabled: bool = False
    store: str = "local_json"


class AgentConfig(BaseModel):
    enabled: bool = False
    type: str = "generic_agent"
    name: str | None = None
    language: str = "zh-CN"


class DemoConfig(BaseModel):
    enabled: bool = False


class ValidationConfig(BaseModel):
    enabled: bool = False


class DownstreamConfig(BaseModel):
    enabled: bool = False


class LiveValidationConfig(BaseModel):
    enabled: bool = False


class VersioningConfig(BaseModel):
    enabled: bool = False


class IncrementalConfig(BaseModel):
    enabled: bool = False
    previous_package: Path | None = None


class LifecycleConfig(BaseModel):
    enabled: bool = False
    update_mode: str = "full"
    previous_package: Path | None = None
    missing_source_policy: str = "mark_stale"
    quality_gate: bool = False
    retry_manifest: Path | None = None


class ChunkConfig(BaseModel):
    profile: str = "default"


class KnowledgeGraphConfig(BaseModel):
    enabled: bool = False


class RetrievalEvalConfig(BaseModel):
    enabled: bool = False
    generate_cases: bool = False
    top_k: int = 5


class RiskLabelsConfig(BaseModel):
    enabled: bool = False


class RuntimeConfig(BaseModel):
    enabled: bool = False
    top_k: int = 5
    provider: str = "fake"
    model: str = "fake-model"


class WebConfig(BaseModel):
    enabled: bool = False


class WorkspaceConfig(BaseModel):
    enabled: bool = False
    path: Path | None = None
    register_outputs: bool = False
    copy_packages: bool = False
    health_check: bool = False


class ProviderRegistryConfig(BaseModel):
    enabled: bool = False
    default_provider: str = "mock_default"
    providers: list[dict] = Field(default_factory=list)


class PromptProfilesConfig(BaseModel):
    enabled: bool = False
    profiles: list[dict] = Field(default_factory=list)


class LLMAuditConfig(BaseModel):
    enabled: bool = False
    import_call_logs: bool = False


class StudioConfig(BaseModel):
    enabled: bool = False
    project_name: str = "demo_project"
    profile: str = "stable"
    workspace: Path | None = None
    release_check: bool = False
    batch_governance_center: bool = False


class ReliabilityConfig(BaseModel):
    enabled: bool = False
    release_threshold: int = 80


class StableCheckConfig(BaseModel):
    enabled: bool = False
    strict: bool = False


class ProviderHealthConfig(BaseModel):
    enabled: bool = False
    allow_network: bool = False


class ReleasePackageConfig(BaseModel):
    enabled: bool = False
    include_demo_outputs: bool = True


class RefreshConfig(BaseModel):
    enabled: bool = False
    stale_days: int = 30


class ReviewConfig(BaseModel):
    enabled: bool = False
    workflow: bool = False
    curation: bool = False


class InputHardeningConfig(BaseModel):
    enabled: bool = False
    html: bool = True
    csv: bool = True
    xlsx: bool = True
    epub: bool = True
    zip: bool = True
    pdf_structure: bool = True
    source_inventory_enhanced: bool = True


class KnowledgeQualityConfig(BaseModel):
    enabled: bool = False
    chunk_quality: bool = True
    evidence_quality: bool = True
    source_quality: bool = True
    multimodal_quality: bool = True


class EvidenceBenchmarkConfig(BaseModel):
    enabled: bool = False
    hallucination_traps: bool = True
    out_of_scope_cases: bool = True


class LLMQualityAssistConfig(BaseModel):
    enabled: bool = False
    provider: str = "mock"
    fail_safe: bool = True


class EvaluationDashboardConfig(BaseModel):
    enabled: bool = False


class PublishConfig(BaseModel):
    enabled: bool = False
    profile: str = "generic_rag"


class PlanningReadinessConfig(BaseModel):
    enabled: bool = False


class StoreConfig(BaseModel):
    enabled: bool = False
    db_path: Path = Path("kb_forge_workspace.db")
    import_package: bool = False
    export_index: bool = False


class AgentRAGConfig(BaseModel):
    enabled: bool = False
    query: str = "Summarize this knowledge package."
    top_k: int = 5
    citation_required: bool = True
    package: Path | None = None
    store: Path | None = None
    scope: dict[str, str] = Field(default_factory=dict)


class SkillConfig(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    enabled: bool = False
    name: str = "Demo Knowledge Skill"
    type: str = "generic"
    validate_skill: bool = Field(False, alias="validate")
    llm_generation: bool = False


class AgentPackageConfig(BaseModel):
    enabled: bool = False
    name: str = "Demo Knowledge Agent"
    type: str = "generic"
    llm_generation: bool = False


class PerformanceConfig(BaseModel):
    profile: str = "production"
    progress: bool = False
    progress_jsonl: bool = False
    progress_log: Path | None = None
    ocr_mode: str = "auto"
    max_ocr_pages: int | None = None
    ocr_pages: str | None = None
    ocr_lang: str = "chi_sim+eng"
    ocr_timeout_per_page: int = 120
    ocr_workers: int = 1
    ocr_cache: bool = False
    ocr_cache_dir: Path | None = None
    resume: bool = False
    ocr_scale: float = 1.5
    skip_empty_pages: bool = True
    skip_low_text_pages: bool = False


class MultimodalConfig(BaseModel):
    enabled: bool = False
    images: bool = True
    charts: bool = True
    slides: bool = True
    formulas: bool = True
    mindmaps: bool = True
    diagrams: bool = True
    report: bool = True
    require_evidence_refs: bool = True
    review_low_confidence: bool = True


class ContractConfig(BaseModel):
    version: str | None = None
    check: bool = False
    strict: bool = False


class GovernanceConfig(BaseModel):
    enabled: bool = False
    previous_package: Path | None = None


class RetrievalIndexConfig(BaseModel):
    enabled: bool = False
    query: str = "Summarize this knowledge package."


class EvidenceGateConfig(BaseModel):
    enabled: bool = False
    query: str = "Summarize this knowledge package."


class PackageLineageConfig(BaseModel):
    enabled: bool = False
    version_graph: bool = True
    dependency_report: bool = True
    workspace: Path | None = None
    output: Path | None = None


class CurationConfig(BaseModel):
    enabled: bool = False
    build_curated_package: bool = False
    require_decision_log: bool = True
    package: Path | None = None
    review_decisions: Path | None = None
    output: Path | None = None


class UpdateImpactConfig(BaseModel):
    enabled: bool = False
    impacted_skills: bool = True
    impacted_agents: bool = True
    workspace: Path | None = None
    package: Path | None = None
    output: Path | None = None


class ForgeConfig(BaseModel):
    task: str
    input: Path
    output: Path
    domain: str = "general"
    mode: str = "reference"
    max_chars: int = 1200
    overlap_chars: int = 120
    batch: BatchConfig = Field(default_factory=BatchConfig)
    llm: LLMConfig = Field(default_factory=LLMConfig)
    rag: RAGConfig = Field(default_factory=RAGConfig)
    embedding: EmbeddingConfig = Field(default_factory=EmbeddingConfig)
    vector: VectorConfig = Field(default_factory=VectorConfig)
    agent: AgentConfig = Field(default_factory=AgentConfig)
    demo: DemoConfig = Field(default_factory=DemoConfig)
    validation: ValidationConfig = Field(default_factory=ValidationConfig)
    downstream: DownstreamConfig = Field(default_factory=DownstreamConfig)
    live_validation: LiveValidationConfig = Field(default_factory=LiveValidationConfig)
    versioning: VersioningConfig = Field(default_factory=VersioningConfig)
    incremental: IncrementalConfig = Field(default_factory=IncrementalConfig)
    lifecycle: LifecycleConfig = Field(default_factory=LifecycleConfig)
    chunk: ChunkConfig = Field(default_factory=ChunkConfig)
    knowledge_graph: KnowledgeGraphConfig = Field(default_factory=KnowledgeGraphConfig)
    retrieval_eval: RetrievalEvalConfig = Field(default_factory=RetrievalEvalConfig)
    risk_labels: RiskLabelsConfig = Field(default_factory=RiskLabelsConfig)
    runtime: RuntimeConfig = Field(default_factory=RuntimeConfig)
    web: WebConfig = Field(default_factory=WebConfig)
    workspace: WorkspaceConfig = Field(default_factory=WorkspaceConfig)
    provider_registry: ProviderRegistryConfig = Field(default_factory=ProviderRegistryConfig)
    prompt_profiles: PromptProfilesConfig = Field(default_factory=PromptProfilesConfig)
    llm_audit: LLMAuditConfig = Field(default_factory=LLMAuditConfig)
    studio: StudioConfig = Field(default_factory=StudioConfig)
    reliability: ReliabilityConfig = Field(default_factory=ReliabilityConfig)
    stable_check: StableCheckConfig = Field(default_factory=StableCheckConfig)
    provider_health: ProviderHealthConfig = Field(default_factory=ProviderHealthConfig)
    release_package: ReleasePackageConfig = Field(default_factory=ReleasePackageConfig)
    refresh: RefreshConfig = Field(default_factory=RefreshConfig)
    review: ReviewConfig = Field(default_factory=ReviewConfig)
    input_hardening: InputHardeningConfig = Field(default_factory=InputHardeningConfig)
    quality: KnowledgeQualityConfig = Field(default_factory=KnowledgeQualityConfig)
    evidence_benchmark: EvidenceBenchmarkConfig = Field(default_factory=EvidenceBenchmarkConfig)
    llm_quality_assist: LLMQualityAssistConfig = Field(default_factory=LLMQualityAssistConfig)
    evaluation_dashboard: EvaluationDashboardConfig = Field(default_factory=EvaluationDashboardConfig)
    publish: PublishConfig = Field(default_factory=PublishConfig)
    planning_readiness: PlanningReadinessConfig = Field(default_factory=PlanningReadinessConfig)
    store: StoreConfig = Field(default_factory=StoreConfig)
    agent_rag: AgentRAGConfig = Field(default_factory=AgentRAGConfig)
    skill: SkillConfig = Field(default_factory=SkillConfig)
    agent_package: AgentPackageConfig = Field(default_factory=AgentPackageConfig)
    performance: PerformanceConfig = Field(default_factory=PerformanceConfig)
    multimodal: MultimodalConfig = Field(default_factory=MultimodalConfig)
    contract: ContractConfig = Field(default_factory=ContractConfig)
    governance: GovernanceConfig = Field(default_factory=GovernanceConfig)
    retrieval: RetrievalIndexConfig = Field(default_factory=RetrievalIndexConfig)
    evidence_gate: EvidenceGateConfig = Field(default_factory=EvidenceGateConfig)
    package_lineage: PackageLineageConfig = Field(default_factory=PackageLineageConfig)
    curation: CurationConfig = Field(default_factory=CurationConfig)
    update_impact: UpdateImpactConfig = Field(default_factory=UpdateImpactConfig)

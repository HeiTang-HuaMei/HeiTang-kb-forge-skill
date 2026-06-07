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
    enhanced_template: bool = False


class AgentPackageConfig(BaseModel):
    enabled: bool = False
    name: str = "Demo Knowledge Agent"
    type: str = "generic"
    llm_generation: bool = False
    compat: bool = False


class KnowledgeBoundFactoryConfig(BaseModel):
    enabled: bool = False
    skill_name: str = "Demo Knowledge Skill"
    agent_name: str = "Demo Knowledge Agent"
    skill_type: str = "generic"
    agent_type: str = "generic"
    allow_untrusted: bool = False


class MultiKBOrchestrationConfig(BaseModel):
    enabled: bool = False
    packages: list[Path] = Field(default_factory=list)
    agents: list[Path] = Field(default_factory=list)
    query: str = ""
    mother_agent: Path | None = None
    workflow_shared_memory: bool = False
    parent_writeback: bool = False


class SkillReverseFusionConfig(BaseModel):
    enabled: bool = False
    skills: list[Path] = Field(default_factory=list)
    fused_name: str = "Fused Knowledge Skill"


class WorkbenchContractsConfig(BaseModel):
    enabled: bool = False
    output: Path | None = None
    project_name: str = "HeiTang Workbench"


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


class QueryRewriteConfig(BaseModel):
    enabled: bool = False
    strategy: str = "hybrid"
    use_conversation_context: bool = True
    conversation_context: str | None = None
    generate_multi_queries: bool = True
    max_rewrites: int = 5
    allow_llm_rewrite: bool = False
    retrieval_purpose: str = "answering"


class KnowledgeRuntimeConfig(BaseModel):
    enabled: bool = False
    query: str = "Summarize this knowledge package."
    top_k: int = 5
    min_score: int = 2
    citation_required: bool = True


class DocumentGenerationConfig(BaseModel):
    enabled: bool = False
    formats: list[str] = Field(default_factory=lambda: ["md"])
    template: str = "default_report"
    grounding_policy: str = "strict_grounded"
    title: str | None = None


class EvidenceGateConfig(BaseModel):
    enabled: bool = False
    query: str = "Summarize this knowledge package."


class ParserBackendTrustPolicyConfig(BaseModel):
    default_status: str = "draft_knowledge_package"
    require_review_for_scanned_pdf: bool = True
    require_review_for_high_risk_chunks: bool = True


class ParserBackendConfig(BaseModel):
    use_for_build: bool = False
    default: str = "builtin"
    enabled: list[str] = Field(default_factory=lambda: ["builtin", "docling", "marker"])
    allow_untrusted: bool = False
    trust_policy: ParserBackendTrustPolicyConfig = Field(default_factory=ParserBackendTrustPolicyConfig)


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


class WorkspaceRefreshConfig(BaseModel):
    enabled: bool = False
    workspace: Path | None = None
    output: Path | None = None


class ProviderReadinessConfig(BaseModel):
    enabled: bool = False
    workspace: Path | None = None
    output: Path | None = None


class PromptProfileVersioningConfig(BaseModel):
    enabled: bool = False
    workspace: Path | None = None
    output: Path | None = None


class PlatformDistributionConfig(BaseModel):
    enabled: bool = False
    platform: str = "generic"
    skill: Path | None = None
    agent: Path | None = None
    output: Path | None = None
    upload_check: bool = True
    mock_publish: bool = True


class QualityGateConfig(BaseModel):
    enabled: bool = False
    strict: bool = False
    release_threshold: int = 80
    output: Path | None = None


class ReleaseBlockersConfig(BaseModel):
    enabled: bool = False
    fail_on_critical: bool = True
    output: Path | None = None


class RegressionConfig(BaseModel):
    enabled: bool = False
    include_versions: list[str] = Field(default_factory=lambda: ["v1.6", "v1.7", "v1.8", "v1.9", "v2.0", "v2.1", "v2.2", "v2.3", "v2.4"])
    output: Path | None = None


class GoldenSamplesConfig(BaseModel):
    enabled: bool = False
    validate_samples: bool = Field(True, alias="validate")
    samples_root: Path = Path("examples/golden_samples")
    output: Path | None = None


class ExportCertificationConfig(BaseModel):
    enabled: bool = False
    platforms: list[str] = Field(default_factory=lambda: ["openclaw", "xhs", "codex", "claude_code", "mcp", "generic", "local_registry"])
    export: Path | None = None
    output: Path | None = None


class CompatibilityMatrixConfig(BaseModel):
    enabled: bool = False
    output: Path | None = None


class LLMQualityGateAssistConfig(BaseModel):
    enabled: bool = False
    provider: str = "mock"
    allow_network: bool = False
    output: Path | None = None


class ReleaseReadinessConfig(BaseModel):
    enabled: bool = False
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
    knowledge_bound_factory: KnowledgeBoundFactoryConfig = Field(default_factory=KnowledgeBoundFactoryConfig)
    multi_kb_orchestration: MultiKBOrchestrationConfig = Field(default_factory=MultiKBOrchestrationConfig)
    skill_reverse_fusion: SkillReverseFusionConfig = Field(default_factory=SkillReverseFusionConfig)
    workbench_contracts: WorkbenchContractsConfig = Field(default_factory=WorkbenchContractsConfig)
    performance: PerformanceConfig = Field(default_factory=PerformanceConfig)
    multimodal: MultimodalConfig = Field(default_factory=MultimodalConfig)
    contract: ContractConfig = Field(default_factory=ContractConfig)
    governance: GovernanceConfig = Field(default_factory=GovernanceConfig)
    retrieval: RetrievalIndexConfig = Field(default_factory=RetrievalIndexConfig)
    query_rewrite: QueryRewriteConfig = Field(default_factory=QueryRewriteConfig)
    knowledge_runtime: KnowledgeRuntimeConfig = Field(default_factory=KnowledgeRuntimeConfig)
    document_generation: DocumentGenerationConfig = Field(default_factory=DocumentGenerationConfig)
    evidence_gate: EvidenceGateConfig = Field(default_factory=EvidenceGateConfig)
    parser_backend: ParserBackendConfig = Field(default_factory=ParserBackendConfig)
    package_lineage: PackageLineageConfig = Field(default_factory=PackageLineageConfig)
    curation: CurationConfig = Field(default_factory=CurationConfig)
    update_impact: UpdateImpactConfig = Field(default_factory=UpdateImpactConfig)
    workspace_refresh: WorkspaceRefreshConfig = Field(default_factory=WorkspaceRefreshConfig)
    provider_readiness: ProviderReadinessConfig = Field(default_factory=ProviderReadinessConfig)
    prompt_profile_versioning: PromptProfileVersioningConfig = Field(default_factory=PromptProfileVersioningConfig)
    platform_distribution: PlatformDistributionConfig = Field(default_factory=PlatformDistributionConfig)
    quality_gate_v25: QualityGateConfig = Field(default_factory=QualityGateConfig)
    quality_gate: QualityGateConfig = Field(default_factory=QualityGateConfig)
    release_blockers: ReleaseBlockersConfig = Field(default_factory=ReleaseBlockersConfig)
    regression: RegressionConfig = Field(default_factory=RegressionConfig)
    golden_samples: GoldenSamplesConfig = Field(default_factory=GoldenSamplesConfig)
    export_certification: ExportCertificationConfig = Field(default_factory=ExportCertificationConfig)
    compatibility_matrix: CompatibilityMatrixConfig = Field(default_factory=CompatibilityMatrixConfig)
    llm_quality_gate_assist: LLMQualityGateAssistConfig = Field(default_factory=LLMQualityGateAssistConfig)
    release_readiness: ReleaseReadinessConfig = Field(default_factory=ReleaseReadinessConfig)

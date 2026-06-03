from pathlib import Path

from pydantic import BaseModel, Field


class BatchConfig(BaseModel):
    merge_same_sequence: bool = False


class LLMConfig(BaseModel):
    enabled: bool = False
    provider: str = "fake"
    model: str = "fake-model"
    cache: bool = True
    strict: bool = False
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


class ChunkConfig(BaseModel):
    profile: str = "default"


class KnowledgeGraphConfig(BaseModel):
    enabled: bool = False


class RetrievalEvalConfig(BaseModel):
    enabled: bool = False


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


class RefreshConfig(BaseModel):
    enabled: bool = False
    stale_days: int = 30


class ReviewConfig(BaseModel):
    enabled: bool = False


class EvaluationDashboardConfig(BaseModel):
    enabled: bool = False


class PublishConfig(BaseModel):
    enabled: bool = False
    profile: str = "generic_rag"


class PlanningReadinessConfig(BaseModel):
    enabled: bool = False


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
    chunk: ChunkConfig = Field(default_factory=ChunkConfig)
    knowledge_graph: KnowledgeGraphConfig = Field(default_factory=KnowledgeGraphConfig)
    retrieval_eval: RetrievalEvalConfig = Field(default_factory=RetrievalEvalConfig)
    risk_labels: RiskLabelsConfig = Field(default_factory=RiskLabelsConfig)
    runtime: RuntimeConfig = Field(default_factory=RuntimeConfig)
    web: WebConfig = Field(default_factory=WebConfig)
    workspace: WorkspaceConfig = Field(default_factory=WorkspaceConfig)
    refresh: RefreshConfig = Field(default_factory=RefreshConfig)
    review: ReviewConfig = Field(default_factory=ReviewConfig)
    evaluation_dashboard: EvaluationDashboardConfig = Field(default_factory=EvaluationDashboardConfig)
    publish: PublishConfig = Field(default_factory=PublishConfig)
    planning_readiness: PlanningReadinessConfig = Field(default_factory=PlanningReadinessConfig)

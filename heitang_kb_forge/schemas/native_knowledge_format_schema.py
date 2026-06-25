from pydantic import BaseModel, Field


class NativeSourceTrace(BaseModel):
    source_id: str
    source_path: str
    chunk_id: str
    citation: str
    scope_id: str = ""


class NativeEntity(BaseModel):
    entity_id: str
    name: str
    entity_type: str = "concept"
    source_path: str
    chunk_id: str
    citation: str


class NativeRelation(BaseModel):
    relation_id: str
    source_entity_id: str
    target_entity_id: str
    relation_type: str
    source_path: str
    chunk_id: str
    citation: str


class NativeCompoundQuestion(BaseModel):
    question_id: str
    question: str
    required_entity_ids: list[str] = Field(default_factory=list)
    source_path: str
    chunk_id: str
    citation: str


class NativeCrossDocSummary(BaseModel):
    summary_id: str
    summary: str
    source_ids: list[str] = Field(default_factory=list)
    citation: str


class NativeMemoryCard(BaseModel):
    memory_card_id: str
    title: str
    summary: str
    entity_ids: list[str] = Field(default_factory=list)
    source_path: str
    chunk_id: str
    citation: str


class NativeKnowledgeFormatPackage(BaseModel):
    schema_version: str = "heitang_native_knowledge_format.v1"
    chunks: list[dict] = Field(default_factory=list)
    source_trace: list[NativeSourceTrace] = Field(default_factory=list)
    entities: list[NativeEntity] = Field(default_factory=list)
    relations: list[NativeRelation] = Field(default_factory=list)
    compound_questions: list[NativeCompoundQuestion] = Field(default_factory=list)
    cross_doc_summaries: list[NativeCrossDocSummary] = Field(default_factory=list)
    memory_cards: list[NativeMemoryCard] = Field(default_factory=list)


class NativeKnowledgeFormatReport(BaseModel):
    schema_version: str = "native_knowledge_format_semantic_schema.v1"
    status: str
    checked_counts: dict = Field(default_factory=dict)
    failed_checks: list[str] = Field(default_factory=list)
    missing_trace_ids: list[str] = Field(default_factory=list)
    missing_entity_ids: list[str] = Field(default_factory=list)
    unresolved_relation_ids: list[str] = Field(default_factory=list)
    unresolved_question_ids: list[str] = Field(default_factory=list)
    unresolved_memory_card_ids: list[str] = Field(default_factory=list)
    unresolved_summary_ids: list[str] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)
    output_files: list[str] = Field(default_factory=list)

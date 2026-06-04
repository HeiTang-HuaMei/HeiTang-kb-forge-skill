REQUIRED_FILES = [
    "manifest.json",
    "chunks.jsonl",
    "evidence_map.json",
    "source_inventory.json",
    "quality_report.md",
]

MULTIMODAL_FILES = [
    "multimodal_assets.jsonl",
    "multimodal_evidence_map.json",
    "multimodal_report.md",
]

RAG_FILES = [
    "rag_manifest.json",
    "embedding_input.jsonl",
    "retrieval_metadata.jsonl",
    "citation_map.json",
]

AGENT_FILES = [
    "agent_profile.yaml",
    "system_prompt.md",
    "retrieval_config.yaml",
    "tools.yaml",
    "eval_cases.jsonl",
]

MANIFEST_FIELDS = [
    "contract_version",
    "package_version",
    "generated_at",
    "source_count",
    "chunk_count",
    "quality_status",
    "review_status",
    "progress_status",
    "ocr_status",
    "multimodal_status",
    "rag_status",
    "agent_template_status",
]

# Output Contract

## Default Standard Package

Every successful default build package contains:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `ingest_report.md`
- `quality_report.json`

## Optional Outputs

LLM:

- `llm_cards.jsonl`
- `llm_qa_pairs.jsonl`
- `llm_glossary.jsonl`
- `frameworks.jsonl`
- `case_cards.jsonl`
- `metrics.jsonl`
- `llm_quality_report.json`
- `llm_quality_summary.md`

RAG:

- `embedding_input.jsonl`
- `retrieval_metadata.jsonl`
- `citation_map.json`
- `rag_manifest.json`

Embedding / vector:

- `embeddings.jsonl`
- `embedding_manifest.json`
- `vector_store_records.jsonl`
- `vector_store_manifest.json`

Agent Template:

- `agent_profile.yaml`
- `system_prompt.md`
- `retrieval_config.yaml`
- `tools.yaml`
- `eval_cases.jsonl`

Validation / downstream:

- `package_validation_report.json`
- `package_readiness_report.md`
- `langchain_documents.jsonl`
- `llamaindex_documents.jsonl`
- `generic_rag_package.json`
- `openai_files_manifest.json`

## Stability

v1.0.0 keeps the default 7-file output unchanged. Optional outputs are generated only when the related opt-in flag or config field is enabled.

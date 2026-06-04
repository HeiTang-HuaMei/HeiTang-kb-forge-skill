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

## v1.3.0 Lifecycle Outputs

When lifecycle mode is enabled, the package may also include:

- `source_registry.json`
- `source_change_report.md`
- `changed_sources.jsonl`
- `missing_sources.jsonl`
- `new_sources.jsonl`
- `incremental_update_report.md`
- `reused_chunks.jsonl`
- `rebuilt_chunks.jsonl`
- `removed_chunks.jsonl`
- `stale_chunks.jsonl`
- `removed_source_impact_report.md`
- `update_quality_gate_report.json`
- `quality_regression_report.md`
- `failed_sources.jsonl`
- `retry_manifest.json`
- `retry_report.md`

These files are optional lifecycle artifacts. The default 7-file package remains unchanged when lifecycle is not enabled.

## v1.4.0 Store Outputs

The local store export can generate:

- `store_manifest.json`
- `store_package_index.jsonl`
- `store_source_index.jsonl`
- `store_chunk_index.jsonl`
- `store_status_report.md`
- `store_query_result.json`

These are index artifacts generated from existing knowledge packages. They do not replace package files.

## v1.5.0 Agent RAG Outputs

Agent RAG runs can generate:

- `retrieval_result.json`
- `retrieval_trace.json`
- `citation_trace.json`
- `answer.md`
- `answer_report.json`
- `agent_rag_config.yaml`

These files are local retrieval and answer artifacts. They do not contain real embeddings and do not imply vector database writes.

## v1.6.0 Agent Tool / MCP Outputs

Tool exports:

- `tool_registry.yaml`
- `tool_manifest.json`
- `agent_tool_schema.json`
- `tool_safety_policy.md`

Tool invocation:

- `tool_execution_trace.json`
- `tool_result.json`
- `tool_error_report.json`

MCP readiness:

- `mcp_server_config.yaml`
- `mcp_tools_manifest.json`

These files are local interface artifacts. They do not deploy Agents or start external tool runtimes.

# Hybrid Retrieval Report

- Status: pass
- Tests require real LLM/API/network: False

```json
{
  "hybrid_retrieval_report_version": "pre-v4-p0-1",
  "status": "pass",
  "keyword_retrieval": true,
  "vector_retrieval": true,
  "merge_dedup": true,
  "metadata_filter": true,
  "rerank": true,
  "evidence_selection": true,
  "selected_rejected_reasons": true,
  "trace": {
    "vector_query_trace_version": "pre-v4-local-vector-1",
    "package": "_local_acceptance_outputs/large_bilingual_run_after_fix/core_package",
    "query": "local privacy optional LLM",
    "mode": "hybrid",
    "top_k": 5,
    "filters": {},
    "records_considered": 25742,
    "records_matched": 25742,
    "records_returned": 5,
    "staleness": {
      "status": "fresh",
      "missing_vector_count": 0,
      "orphan_vector_count": 0,
      "manifest_total_records": 25742,
      "actual_vector_records": 25742,
      "count_mismatch": false,
      "missing_vector_ids": [],
      "orphan_vector_ids": [],
      "rebuild_policy": "rebuild local vector export when embeddings and vector records diverge"
    },
    "tests_require_real_llm_api_network": false
  },
  "filtered_trace": {
    "vector_query_trace_version": "pre-v4-local-vector-1",
    "package": "_local_acceptance_outputs/large_bilingual_run_after_fix/core_package",
    "query": "local privacy optional LLM",
    "mode": "hybrid",
    "top_k": 5,
    "filters": {
      "source_asset_type": "chunk"
    },
    "records_considered": 25742,
    "records_matched": 9599,
    "records_returned": 5,
    "staleness": {
      "status": "fresh",
      "missing_vector_count": 0,
      "orphan_vector_count": 0,
      "manifest_total_records": 25742,
      "actual_vector_records": 25742,
      "count_mismatch": false,
      "missing_vector_ids": [],
      "orphan_vector_ids": [],
      "rebuild_policy": "rebuild local vector export when embeddings and vector records diverge"
    },
    "tests_require_real_llm_api_network": false
  },
  "tests_require_real_llm_api_network": false
}
```

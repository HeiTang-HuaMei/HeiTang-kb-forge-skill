# Vector Db Completion Report

- Status: pass
- Tests require real LLM/API/network: False

```json
{
  "vector_db_completion_report_version": "pre-v4-p0-1",
  "generated_at": "2026-06-08T06:51:06.721172+00:00",
  "status": "pass",
  "provider_statuses": {
    "chroma": "implemented_needs_live_acceptance",
    "qdrant": "implemented_needs_live_acceptance",
    "milvus": "implemented_needs_live_acceptance",
    "pinecone": "implemented_needs_live_acceptance"
  },
  "providers": [
    {
      "provider": "chroma",
      "adapter_class": "ChromaAdapter",
      "status": "implemented_offline_contract_tested",
      "readiness_status": "implemented_needs_live_acceptance",
      "create_collection": {
        "status": "pass",
        "collection": "heitang_contract_chroma"
      },
      "upsert": {
        "status": "pass",
        "upserted": 2,
        "collection": "heitang_contract_chroma"
      },
      "query_returned": 2,
      "metadata_filter_returned": 1,
      "metadata_filter_pass": true,
      "update": {
        "status": "pass",
        "updated": 1,
        "collection": "heitang_contract_chroma"
      },
      "delete": {
        "status": "pass",
        "deleted": 1,
        "collection": "heitang_contract_chroma"
      },
      "stale_before_delete": {
        "status": "fresh",
        "missing_vector_count": 0,
        "orphan_vector_count": 0,
        "missing_vector_ids": [],
        "orphan_vector_ids": [],
        "rebuild_recommendation": ""
      },
      "stale_after_delete": {
        "status": "stale",
        "missing_vector_count": 1,
        "orphan_vector_count": 0,
        "missing_vector_ids": [
          "vec-rag-hybrid"
        ],
        "orphan_vector_ids": [],
        "rebuild_recommendation": "rebuild provider index from current embeddings"
      },
      "supports_create_open_collection": true,
      "supports_upsert": true,
      "supports_query": true,
      "supports_metadata_filter": true,
      "supports_delete_update_by_source_or_package": true,
      "supports_stale_index_detection": true,
      "credential_redaction": "env_names_only_no_values",
      "ready_for_live_acceptance": false,
      "live_verified": false,
      "blocked_reason": "required_env_missing,client_library_missing",
      "tests_require_real_llm_api_network": false
    },
    {
      "provider": "qdrant",
      "adapter_class": "QdrantAdapter",
      "status": "implemented_offline_contract_tested",
      "readiness_status": "implemented_needs_live_acceptance",
      "create_collection": {
        "status": "pass",
        "collection": "heitang_contract_qdrant"
      },
      "upsert": {
        "status": "pass",
        "upserted": 2,
        "collection": "heitang_contract_qdrant"
      },
      "query_returned": 2,
      "metadata_filter_returned": 1,
      "metadata_filter_pass": true,
      "update": {
        "status": "pass",
        "updated": 1,
        "collection": "heitang_contract_qdrant"
      },
      "delete": {
        "status": "pass",
        "deleted": 1,
        "collection": "heitang_contract_qdrant"
      },
      "stale_before_delete": {
        "status": "fresh",
        "missing_vector_count": 0,
        "orphan_vector_count": 0,
        "missing_vector_ids": [],
        "orphan_vector_ids": [],
        "rebuild_recommendation": ""
      },
      "stale_after_delete": {
        "status": "stale",
        "missing_vector_count": 1,
        "orphan_vector_count": 0,
        "missing_vector_ids": [
          "vec-rag-hybrid"
        ],
        "orphan_vector_ids": [],
        "rebuild_recommendation": "rebuild provider index from current embeddings"
      },
      "supports_create_open_collection": true,
      "supports_upsert": true,
      "supports_query": true,
      "supports_metadata_filter": true,
      "supports_delete_update_by_source_or_package": true,
      "supports_stale_index_detection": true,
      "credential_redaction": "env_names_only_no_values",
      "ready_for_live_acceptance": false,
      "live_verified": false,
      "blocked_reason": "required_env_missing,client_library_missing",
      "tests_require_real_llm_api_network": false
    },
    {
      "provider": "milvus",
      "adapter_class": "MilvusAdapter",
      "status": "implemented_offline_contract_tested",
      "readiness_status": "implemented_needs_live_acceptance",
      "create_collection": {
        "status": "pass",
        "collection": "heitang_contract_milvus"
      },
      "upsert": {
        "status": "pass",
        "upserted": 2,
        "collection": "heitang_contract_milvus"
      },
      "query_returned": 2,
      "metadata_filter_returned": 1,
      "metadata_filter_pass": true,
      "update": {
        "status": "pass",
        "updated": 1,
        "collection": "heitang_contract_milvus"
      },
      "delete": {
        "status": "pass",
        "deleted": 1,
        "collection": "heitang_contract_milvus"
      },
      "stale_before_delete": {
        "status": "fresh",
        "missing_vector_count": 0,
        "orphan_vector_count": 0,
        "missing_vector_ids": [],
        "orphan_vector_ids": [],
        "rebuild_recommendation": ""
      },
      "stale_after_delete": {
        "status": "stale",
        "missing_vector_count": 1,
        "orphan_vector_count": 0,
        "missing_vector_ids": [
          "vec-rag-hybrid"
        ],
        "orphan_vector_ids": [],
        "rebuild_recommendation": "rebuild provider index from current embeddings"
      },
      "supports_create_open_collection": true,
      "supports_upsert": true,
      "supports_query": true,
      "supports_metadata_filter": true,
      "supports_delete_update_by_source_or_package": true,
      "supports_stale_index_detection": true,
      "credential_redaction": "env_names_only_no_values",
      "ready_for_live_acceptance": false,
      "live_verified": false,
      "blocked_reason": "required_env_missing,client_library_missing",
      "tests_require_real_llm_api_network": false
    },
    {
      "provider": "pinecone",
      "adapter_class": "PineconeAdapter",

```

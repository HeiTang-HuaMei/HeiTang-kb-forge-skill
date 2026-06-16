# Campaign 5 Workbench Bridge Action Status Matrix

Status: `campaign5_workbench_bridge_production_grade_accepted_ui_bound`

## Status Values

| Status | User meaning | Retry/cancel behavior |
| --- | --- | --- |
| `queued` | Action accepted by the Workbench Bridge queue. | wait or cancel before local process starts |
| `running` | Local Core action is executing inside the allowlisted bridge. | cancel is available for the current task |
| `succeeded` | Core returned exit code 0 and evidence indexes are available. | inspect reports and artifacts |
| `failed` | Core returned a non-zero result or assertion failure. | read sanitized reason, retry if policy allows |
| `cancelled` | User cancelled the running local action. | start again from the same action if needed |
| `blocked` | Action is not allowed by contract, boundary, policy, or path containment. | review blocked reason and stay in read-only mode |
| `degraded` | Local degraded path remains available while external or optional capability is unavailable. | continue local KB/document workflows or retry later |

## Product Enabled Actions

| Action | Page | Command | UI state |
| --- | --- | --- | --- |
| `workspace_inspect` | `workspace` | `workspace-list --workspace <workspace>` | `enabled_real` |
| `workspace_health` | `workspace` | `workspace-health --workspace <workspace>` | `enabled_real` |
| `workspace_storage_usage` | `workspace` | `report-storage --workspace <workspace>` | `enabled_real` |
| `workspace_cleanup_plan` | `workspace` | `plan-cleanup --workspace <workspace>` | `enabled_real` |
| `source_validate` | `import_parsing` | `check-contract --package <package> --output <output>` | `enabled_real` |
| `format_support_matrix` | `import_parsing` | `parser-backend-list` | `enabled_real` |
| `parser_preflight` | `import_parsing` | `parse-quality-gate --input <input> --output <output>` | `enabled_real` |
| `ocr_required_detection` | `import_parsing` | `full-ocr-acceptance --source <source> --output <output>` | `enabled_real` |
| `parse_repair_suggest` | `import_parsing` | `parse-reimport-corrected-text --corrected-text <file> --output <output>` | `enabled_real` |
| `pdf_token_reduction` | `import_parsing` | `report-pdf-token-reduction --source <source> --output <output>` | `enabled_real` |
| `package_build` | `knowledge_package_management` | `build --input <input> --output <output>` | `enabled_real` |
| `package_batch` | `knowledge_package_management` | `batch-run --input <input> --output <output>` | `enabled_real` |
| `package_pipeline` | `knowledge_package_management` | `pipeline --config <config>` | `enabled_real` |
| `package_validation` | `knowledge_package_management` | `check-contract --package <package> --output <output>` | `enabled_real` |
| `package_diff` | `knowledge_package_management` | `lifecycle-check --input <input> --package <package> --output <output>` | `enabled_real` |
| `incremental_update` | `knowledge_package_management` | `refresh-check --workspace <workspace> --output <output>` | `enabled_real` |
| `stale_index_detect` | `knowledge_package_management` | `kb-index --package <package> --output <output>` | `enabled_real` |
| `package_export` | `knowledge_package_management` | `export-platform --skill <skill> --output <output>` | `enabled_real` |
| `query_rewrite` | `retrieval_verification` | `rewrite-query --query <query> --output <output>` | `enabled_real` |
| `retrieval_planning` | `retrieval_verification` | `plan-retrieval --query <query> --output <output>` | `enabled_real` |
| `rag_query` | `retrieval_verification` | `kb-query --package <package> --query <query> --output <output>` | `enabled_real` |
| `hybrid_retrieval` | `retrieval_verification` | `eval-retrieval --package <package> --output <output>` | `enabled_real` |
| `rerank` | `retrieval_verification` | `rerank-results --package <package> --query <query> --output <output>` | `enabled_real` |
| `evidence_selection` | `retrieval_verification` | `select-evidence --package <package> --query <query> --output <output>` | `enabled_real` |
| `claim_verification` | `retrieval_verification` | `verify-claims --package <package> --output <output>` | `enabled_real` |
| `contradiction_detection` | `retrieval_verification` | `check-knowledge-accuracy --package <package> --output <output>` | `enabled_real` |
| `freshness_check` | `retrieval_verification` | `check-knowledge-accuracy --package <package> --output <output>` | `enabled_real` |
| `generate_markdown` | `document_generation` | `generate-md --package <package> --output <output>` | `enabled_real` |
| `generate_docx` | `document_generation` | `generate-docx --package <package> --output <output>` | `enabled_real` |
| `generate_pdf` | `document_generation` | `generate-pdf --package <package> --output <output>` | `enabled_real` |
| `generate_pptx` | `document_generation` | `generate-pptx --package <package> --output <output>` | `enabled_real` |
| `generate_manual_user_guide` | `document_generation` | `generate-documents --package <package> --output <output>` | `enabled_real` |
| `evidence_appendix` | `document_generation` | `select-evidence --package <package> --query <query> --output <output>` | `enabled_real` |
| `openability_check` | `document_generation` | `run-golden-demo-acceptance --package <package> --output <output>` | `enabled_real` |
| `book_to_skill` | `skill_factory` | `book-to-skill --input <input> --output <output> --skill-name <name>` | `enabled_real` |
| `package_to_skill` | `skill_factory` | `generate-skill --package <package> --output <output>` | `enabled_real` |
| `skill_manifest_validate` | `skill_factory` | `validate-skill-package --skill <skill> --output <output>` | `enabled_real` |
| `skill_diff` | `skill_factory` | `diff-skill-package --old-skill <old> --new-skill <new> --output <output>` | `enabled_real` |
| `standalone_agent_generation` | `agent_factory_runtime` | `generate-agent --mode standalone --output <output>` | `enabled_real` |
| `kb_bound_agent_generation` | `agent_factory_runtime` | `generate-agent --mode kb_bound --package <package> --skill <skill> --output <output>` | `enabled_real` |
| `document_owner_inspect` | `governance` | `govern --package <package> --output <output>` | `enabled_real` |
| `stale_document_detect` | `governance` | `govern --package <package> --output <output>` | `enabled_real` |
| `conflict_document_detect` | `governance` | `govern --package <package> --output <output>` | `enabled_real` |
| `product_hardening` | `reports_audit` | `product-hardening --workspace <workspace> --package <package> --output <output>` | `enabled_real` |
| `final_gate` | `reports_audit` | `final-pre-v4-audit --core-repo <repo> --output <output>` | `enabled_real` |
| `artifact_kb_package_inspect` | `artifact_management` | `check-contract --package <package> --output <output>` | `enabled_real` |
| `artifact_vector_index_inspect` | `artifact_management` | `kb-index --package <package> --output <output>` | `enabled_real` |
| `artifact_generated_docs_inspect` | `artifact_management` | `generate-documents --package <package> --output <output>` | `enabled_real` |
| `artifact_skill_package_inspect` | `artifact_management` | `validate-skill-package --skill <skill> --output <output>` | `enabled_real` |
| `artifact_agent_package_inspect` | `artifact_management` | `generate-agent --mode standalone --output <output>` | `enabled_real` |
| `artifact_acceptance_proof_inspect` | `artifact_management` | `run-golden-demo-acceptance --package <package> --output <output>` | `enabled_real` |

## Diagnostic-Only Future Runtime Actions

| Action | Page | Reason | UI state |
| --- | --- | --- | --- |
| `artifact_memory_files_inspect` | `artifact_management` | artifact_management action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |
| `artifact_runtime_trace_inspect` | `artifact_management` | artifact_management action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |
| `memory_cleanup` | `memory_center` | memory_center action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |
| `memory_compression` | `memory_center` | memory_center action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |
| `multi_agent_orchestration` | `agent_factory_runtime` | agent_factory_runtime action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |
| `run_agent` | `agent_factory_runtime` | agent_factory_runtime action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |
| `summary_memory_lifecycle` | `memory_center` | memory_center action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled. | `display_only_diagnostic` |

## Disabled Boundary Actions

| Action | Page | Reason | UI state |
| --- | --- | --- | --- |
| `llm_provider_validate` | `vector_hub_provider_storage` | Excluded from the 57 local execution targets because provider, network, or explicit user config is required. | `disabled_boundary` |
| `vector_db_validate` | `vector_hub_provider_storage` | Excluded from the 57 local execution targets because provider, network, or explicit user config is required. | `disabled_boundary` |
| `vector_upsert_query_smoke` | `vector_hub_provider_storage` | Excluded from the 57 local execution targets because provider, network, or explicit user config is required. | `disabled_boundary` |
| `provider_redaction_check` | `vector_hub_provider_storage` | Excluded from the 57 local execution targets because secret-risk handling must remain blocked. | `disabled_boundary` |
| `offline_fallback_status` | `vector_hub_provider_storage` | Excluded from the 57 local execution targets because provider, network, or explicit user config is required. | `disabled_boundary` |

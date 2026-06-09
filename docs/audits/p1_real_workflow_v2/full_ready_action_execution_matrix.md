# P1-RWF-V2 Full Ready Action Execution Matrix

Status: pass
Ready/core_cli actions: 62
Execution targets: 57
Command surface drift count: 0

| Action | Target | Classification | Command |
| --- | --- | --- | --- |
| workspace_inspect | true | executable_with_generated_workspace | `workspace-list --workspace <workspace>` |
| workspace_health | true | executable_with_generated_workspace | `workspace-health --workspace <workspace>` |
| workspace_storage_usage | true | executable_with_generated_workspace | `report-storage --workspace <workspace>` |
| workspace_cleanup_plan | true | executable_with_generated_workspace | `plan-cleanup --workspace <workspace>` |
| source_validate | true | executable_with_previous_artifact | `check-contract --package <package> --output <output>` |
| format_support_matrix | true | executable_with_demo_input | `parser-backend-list` |
| parser_preflight | true | executable_with_demo_input | `parse-quality-gate --input <input> --output <output>` |
| ocr_required_detection | true | executable_with_demo_input | `full-ocr-acceptance --source <source> --output <output>` |
| parse_repair_suggest | true | executable_with_demo_input | `parse-reimport-corrected-text --corrected-text <file> --output <output>` |
| pdf_token_reduction | true | executable_with_demo_input | `report-pdf-token-reduction --source <source> --output <output>` |
| package_build | true | executable_with_demo_input | `build --input <input> --output <output>` |
| package_batch | true | executable_with_demo_input | `batch-run --input <input> --output <output>` |
| package_pipeline | true | executable_with_demo_input | `pipeline --config <config>` |
| package_validation | true | executable_with_previous_artifact | `check-contract --package <package> --output <output>` |
| package_diff | true | executable_with_previous_artifact | `lifecycle-check --input <input> --package <package> --output <output>` |
| incremental_update | true | executable_with_generated_workspace | `refresh-check --workspace <workspace> --output <output>` |
| stale_index_detect | true | executable_with_previous_artifact | `kb-index --package <package> --output <output>` |
| package_export | true | executable_with_previous_artifact | `export-platform --skill <skill> --output <output>` |
| query_rewrite | true | executable_with_demo_input | `rewrite-query --query <query> --output <output>` |
| retrieval_planning | true | executable_with_demo_input | `plan-retrieval --query <query> --output <output>` |
| rag_query | true | executable_with_previous_artifact | `kb-query --package <package> --query <query> --output <output>` |
| hybrid_retrieval | true | executable_with_previous_artifact | `eval-retrieval --package <package> --output <output>` |
| rerank | true | executable_with_previous_artifact | `rerank-results --package <package> --query <query> --output <output>` |
| evidence_selection | true | executable_with_previous_artifact | `select-evidence --package <package> --query <query> --output <output>` |
| claim_verification | true | executable_with_previous_artifact | `verify-claims --package <package> --output <output>` |
| contradiction_detection | true | executable_with_previous_artifact | `check-knowledge-accuracy --package <package> --output <output>` |
| freshness_check | true | executable_with_previous_artifact | `check-knowledge-accuracy --package <package> --output <output>` |
| llm_provider_validate | false | blocked_provider_required | `provider-readiness --workspace <workspace> --output <output>` |
| vector_db_validate | false | blocked_provider_required | `vector-db-completion --output <output>` |
| vector_upsert_query_smoke | false | blocked_provider_required | `query-vector-index --package <package> --query <query> --output <output>` |
| provider_redaction_check | false | blocked_secret_required | `audit-redaction-check --output <output>` |
| offline_fallback_status | false | blocked_provider_required | `provider-fallback-test --output <output>` |
| generate_markdown | true | executable_with_previous_artifact | `generate-md --package <package> --output <output>` |
| generate_docx | true | executable_with_previous_artifact | `generate-docx --package <package> --output <output>` |
| generate_pdf | true | executable_with_previous_artifact | `generate-pdf --package <package> --output <output>` |
| generate_pptx | true | executable_with_previous_artifact | `generate-pptx --package <package> --output <output>` |
| generate_manual_user_guide | true | executable_with_previous_artifact | `generate-documents --package <package> --output <output>` |
| evidence_appendix | true | executable_with_previous_artifact | `select-evidence --package <package> --query <query> --output <output>` |
| openability_check | true | executable_with_previous_artifact | `run-golden-demo-acceptance --package <package> --output <output>` |
| book_to_skill | true | executable_with_demo_input | `book-to-skill --input <input> --output <output> --skill-name <name>` |
| package_to_skill | true | executable_with_previous_artifact | `generate-skill --package <package> --output <output>` |
| skill_manifest_validate | true | executable_with_previous_artifact | `validate-skill-package --skill <skill> --output <output>` |
| skill_diff | true | executable_with_previous_artifact | `diff-skill-package --old-skill <old> --new-skill <new> --output <output>` |
| standalone_agent_generation | true | executable_with_demo_input | `generate-agent --mode standalone --output <output>` |
| kb_bound_agent_generation | true | executable_with_previous_artifact | `generate-agent --mode kb_bound --package <package> --skill <skill> --output <output>` |
| run_agent | true | executable_with_previous_artifact | `run-local-agent --package <package> --agent <agent> --task <task> --output <output>` |
| multi_agent_orchestration | true | executable_with_previous_artifact | `orchestrate-multi-kb --packages <packages> --output <output>` |
| summary_memory_lifecycle | true | executable_with_demo_input | `plan-memory-lifecycle --output <output>` |
| memory_compression | true | executable_with_demo_input | `estimate-token-budget --output <output>` |
| memory_cleanup | true | executable_with_demo_input | `plan-memory-lifecycle --output <output>` |
| document_owner_inspect | true | executable_with_previous_artifact | `govern --package <package> --output <output>` |
| stale_document_detect | true | executable_with_previous_artifact | `govern --package <package> --output <output>` |
| conflict_document_detect | true | executable_with_previous_artifact | `govern --package <package> --output <output>` |
| product_hardening | true | executable_with_previous_artifact | `product-hardening --workspace <workspace> --package <package> --output <output>` |
| final_gate | true | executable_with_generated_workspace | `final-pre-v4-audit --core-repo <repo> --output <output>` |
| artifact_kb_package_inspect | true | executable_with_previous_artifact | `check-contract --package <package> --output <output>` |
| artifact_vector_index_inspect | true | executable_with_previous_artifact | `kb-index --package <package> --output <output>` |
| artifact_generated_docs_inspect | true | executable_with_previous_artifact | `generate-documents --package <package> --output <output>` |
| artifact_skill_package_inspect | true | executable_with_previous_artifact | `validate-skill-package --skill <skill> --output <output>` |
| artifact_agent_package_inspect | true | executable_with_demo_input | `generate-agent --mode standalone --output <output>` |
| artifact_runtime_trace_inspect | true | executable_with_previous_artifact | `run-local-agent --package <package> --agent <agent> --task <task> --output <output>` |
| artifact_acceptance_proof_inspect | true | executable_with_previous_artifact | `run-golden-demo-acceptance --package <package> --output <output>` |

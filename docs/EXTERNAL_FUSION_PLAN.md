# v3.6 External Fusion Plan

Safe absorption principle: do not blindly import external web results into the KB. Use external sources to validate claims first. Promote new information only after review and trust policy approval. User PDFs should not be uploaded to cloud by default or sent wholesale to an LLM; parse locally into Markdown/JSON first.

## Safe Patterns

- verification_oriented_retrieval_planning -> v3.7
- claim_level_verification_reports -> v3.8
- local_pdf_to_markdown_preprocessing -> v3.9
- ocr_and_complex_parser_backend_benchmark -> parser_hardening_track, v3.9
- retrieval_quality_metrics -> v3.8
- memory_lifecycle_contracts -> v3.9, v3.10
- local_workbench_contract_drift_checks -> v4.0
- knowledge_governance_from_accuracy_status -> v4.3

## Rejected Patterns

- Direct external code, prompt, dataset, or skill text copying.
- Blindly importing external web results into a KB package.
- Treating external retrieval as unrestricted knowledge expansion.
- Uploading user PDFs to cloud document APIs by default.
- Sending raw PDFs wholesale to an LLM when local parsing can produce structured Markdown/JSON first.
- Cloud-required defaults or platform-hosted user data.
- Agent runtime implementation before Core contracts and diagnostics are stable.

See `external_fusion_plan.json` for full details.

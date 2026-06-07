# v3.6 外部模式融合计划

安全吸收原则：不要盲目把外部网页结果导入 KB；先用外部来源验证 claim；只有经过 review / trust policy 后才能提升为新知识。用户 PDF 不默认上传云端，也不默认整包送 LLM，应先本地解析成 Markdown/JSON。

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

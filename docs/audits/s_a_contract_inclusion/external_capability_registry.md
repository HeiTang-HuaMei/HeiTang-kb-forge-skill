# S/A External Capability Registry

This registry preserves contract boundaries while recording completed local capability-fusion, provider-adapter, and workflow-export work. It does not bundle external runtimes or expose UI execution.

## Summary

- S projects: 8
- A projects: 18
- Internal capability anchors: 8
- Optional local parser/OCR runtime adapters: Docling, PaddleOCR, Unstructured
- Planned adapters marked ready: false
- Provider/network/API ready: false
- v4.0 started: false

## Projects

| Project | Rating | Contract status | Blocked reason | Post-v4 target |
| --- | --- | --- | --- | --- |
| LLM Wiki v2 | S | capability_fusion, real_integration, runtime_not_bundled | ui_visibility_only | P2.4 |
| WeKnora | S | capability_fusion, real_integration, runtime_not_bundled | ui_visibility_only | P2.5 |
| n8n | S | workflow_export_adapter, export_validation_passed, runtime_not_bundled | external_runtime_required | P2.2 / P3 |
| andrej-karpathy-skills | S | benchmark_only, capability_anchor | external_project_registry_only | P2.9 |
| PaddleOCR | S | planned_adapter, optional_runtime_adapter | external_project_registry_only | P2.1 |
| MinerU | S | planned_adapter | external_project_registry_only | P2.6 |
| Docling | S | planned_adapter, optional_runtime_adapter | external_project_registry_only | P2.1 |
| AnySearchSkill | A | provider_adapter, real_smoke_passed, needs_strengthening | ui_configuration_pending | P2.3 |
| last30days-skill | A | provider_required, future_adapter | external_project_registry_only | P2.3 / P3 |
| skill-prompt-generator | A | prompt_asset_library_enhancer, real_integration, runtime_not_bundled, license_gate_pending | license_review_required | P2.9 |
| MMSkills | A | schema_package_reference, reference_only, runtime_not_bundled | license_review_required | P2.8 / P3 |
| Jellyfish | A | content_asset_schema_reference, reference_only, runtime_not_bundled | license_review_required | P2.8 / P3 |
| story-flicks | A | aigc_video_pipeline_schema_reference, reference_only, runtime_not_bundled | license_review_required | P2.8 / P3 |
| seedance2-skill | A | verified_video_skill_template_metadata, reference_only, template_reference, provider_not_integrated, runtime_not_bundled | provider_required | P2.8 / P3 |
| RAG-Anything | A | cross_modal_rag_schema_reference, reference_only, runtime_not_bundled | license_review_required | P2.5 / P2.6 |
| mattpocock/skills | A | engineering_governance_rule_pack, real_integration, runtime_not_bundled | license_review_required | P2.2 / governance |
| Sirchmunk | A | bounded_direct_file_search_provider, real_integration, runtime_not_bundled, embedding_free, vector_db_not_required | license_review_required | P2.8 / local retrieval |
| ai-marketing-skills | A | marketing_skill_pattern_library, real_integration, runtime_not_bundled | license_review_required | P2.7 |
| rtk | A | benchmark_only | external_project_registry_only | P3 |
| OpenDataLoader | A | planned_adapter | external_project_registry_only | P2.6 |
| Marker | A | planned_adapter | external_project_registry_only | P2.6 |
| Surya | A | planned_adapter | external_project_registry_only | P2.6 |
| Unstructured | S | planned_adapter, optional_runtime_adapter | external_project_registry_only | P2.1 |
| LlamaIndex | A | benchmark_only | external_project_registry_only | P2.5 |
| RAGAS | A | benchmark_only, future_adapter | external_project_registry_only | P2.5 |
| DeepEval | A | benchmark_only, future_adapter | external_project_registry_only | P2.5 |

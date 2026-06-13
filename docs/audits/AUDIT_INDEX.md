# Audit Index

This index is the human-readable entry point for governed audit evidence. The machine-readable source of truth is `docs/audits/AUDIT_MANIFEST.json`.

## Policy

- Default audit root: `artifacts/audits/`
- `docs/audits/` role: index and promoted summaries only
- Latest retention: newest 3 runs
- Daily retention: 7 days
- Failed debug retention: 3 days unless promoted
- Milestone and release evidence: long-term
- Runtime logs, progress streams, caches, and local dependency environments: not committed by default

## Promoted Runs

| Run | Type | Scope | Status | Retention | Evidence |
| --- | --- | --- | --- | --- | --- |
| `real_mixed_e2e_20260612_102508` | e2e | DU_KB_PACKAGE_QUERY | passed | milestone | `docs/audits/knowledge_supply_chain/real_mixed_e2e_20260612_102508` |
| `office_table_e2e_20260612_105706` | e2e | OFFICE_TABLE_DU_KB_PACKAGE_VERIFY_METHODOLOGY | passed | milestone | `docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706` |
| `report_export_20260612_135600` | report_export | DU_KB_PACKAGE_SKILL_AGENT_VERIFICATION | passed | latest | `artifacts/audits/latest/report_export_20260612_135600` |
| `backend_remediation_acceptance_review` | campaign_acceptance | CAMPAIGN_1_BACKEND_REMEDIATION | accepted | latest | `artifacts/audits/backend_remediation_acceptance_review` |
| `knowledge_supply_chain_acceptance_review` | campaign_acceptance | CAMPAIGN_2_DU_KB_PACKAGE_SEARCH_REPORT | accepted | latest | `artifacts/audits/knowledge_supply_chain_acceptance_review` |
| `llm_wiki_v2_knowledge_lifecycle` | section_5_integration_decision | SECTION_5_ITEM_5_1_LLM_WIKI_V2 | passed | milestone | `artifacts/audits/section_5/llm_wiki_v2_knowledge_lifecycle` |
| `weknora_auto_wiki` | section_5_integration_decision | SECTION_5_ITEM_5_2_WEKNORA | passed | milestone | `artifacts/audits/section_5/weknora_auto_wiki` |
| `anysearchskill_provider_adapter` | section_5_integration_decision | SECTION_5_ITEM_5_3_ANYSEARCHSKILL | passed / needs_strengthening | milestone | `artifacts/audits/section_5/anysearchskill_provider_adapter` |
| `n8n_workflow_export` | section_5_integration_decision | SECTION_5_ITEM_5_4_N8N | passed / real_integration | milestone | `artifacts/audits/section_5/n8n_workflow_export` |
| `mmskills_multimodal_skill_package` | section_5_integration_decision | SECTION_5_ITEM_5_5_MMSKILLS | passed / reference_only | milestone | `artifacts/audits/section_5/mmskills_multimodal_skill_package` |
| `skill_prompt_generator_prompt_asset_library` | section_5_integration_decision | SECTION_5_ITEM_5_6_SKILL_PROMPT_GENERATOR | passed / real_integration | milestone | `artifacts/audits/section_5/skill_prompt_generator_prompt_asset_library` |
| `ai_marketing_skills_pattern_library` | section_5_integration_decision | SECTION_5_ITEM_5_7_AI_MARKETING_SKILLS | passed / real_integration | milestone | `artifacts/audits/section_5/ai_marketing_skills_pattern_library` |
| `ai_money_maker_handbook_business_scenario_library` | section_5_integration_decision | SECTION_5_ITEM_5_8_AI_MONEY_MAKER_HANDBOOK | passed / real_integration / limited_real_integration | milestone | `artifacts/audits/section_5/ai_money_maker_handbook_business_scenario_library` |
| `jellyfish_content_asset_schema` | section_5_integration_decision | SECTION_5_ITEM_5_9_JELLYFISH | passed / reference_only | milestone | `artifacts/audits/section_5/jellyfish_content_asset_schema` |
| `story_flicks_video_pipeline_schema` | section_5_integration_decision | SECTION_5_ITEM_5_10_STORY_FLICKS | passed / reference_only | milestone | `artifacts/audits/section_5/story_flicks_video_pipeline_schema` |
| `campaign_3_0_external_source_memory_plan` | governance_plan_registration | CAMPAIGN_3_SUPPLEMENT_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION | passed / planned_not_active | milestone | `artifacts/audits/governance/campaign_3_0_external_source_memory_plan` |
| `seedance2_skill_template_metadata` | section_5_integration_decision | SECTION_5_ITEM_5_11_SEEDANCE2_SKILL | passed / reference_only | milestone | `artifacts/audits/section_5/seedance2_skill_template_metadata` |
| `rag_anything_cross_modal_rag_schema` | section_5_integration_decision | SECTION_5_ITEM_5_12_RAG_ANYTHING | passed / reference_only | milestone | `artifacts/audits/section_5/rag_anything_cross_modal_rag_schema` |
| `mattpocock_skills_engineering_governance` | section_5_integration_decision | SECTION_5_ITEM_5_13_MATTPOCOCK_SKILLS | passed / real_integration / engineering_governance_rule_pack_only | milestone | `artifacts/audits/section_5/mattpocock_skills_engineering_governance` |
| `sirchmunk_direct_file_search` | section_5_integration_decision | SECTION_5_ITEM_5_14_SIRCHMUNK | passed / real_integration / bounded_direct_file_search_only | milestone | `artifacts/audits/section_5/sirchmunk_direct_file_search` |
| `gbrain_memory_profile_kg_strengthening` | section_5_strengthening_decision | SECTION_5_STRENGTHENING_5_S1_GBRAIN | passed / needs_strengthening / memory_profile_kg_strengthening_record | milestone | `artifacts/audits/section_5/gbrain_memory_profile_kg_strengthening` |
| `horizon_topic_intake_strengthening` | section_5_strengthening_decision | SECTION_5_STRENGTHENING_5_S2_HORIZON | passed / real_integration / topic_intake_pipeline_schema_only | milestone | `artifacts/audits/section_5/horizon_topic_intake_strengthening` |
| `obsidian_vault_strengthening` | section_5_strengthening_decision | SECTION_5_STRENGTHENING_5_S3_OBSIDIAN_COMPATIBLE_VAULT | passed / real_integration / local_vault_adapter_only | milestone | `artifacts/audits/section_5/obsidian_vault_strengthening` |
| `campaign_3_supplement_2_0_closure_gate` | section_5_transition_gate | CAMPAIGN_3_SUPPLEMENT_2_0_CLOSURE_GATE | passed / accepted_for_transition_to_campaign_3_3_0_entry_gate | milestone | `artifacts/audits/section_5/campaign_3_supplement_2_0_closure_gate` |
| `campaign_3_supplement_3_0_entry_gate` | campaign_supplement_entry_gate | CAMPAIGN_3_SUPPLEMENT_3_0_ENTRY_GATE | passed / accepted_for_campaign_3_3_0_p0_framework_start | milestone | `artifacts/audits/section_5/campaign_3_supplement_3_0_entry_gate` |
| `external_source_framework` | section_5_supplement_3_0_p0_framework | CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_FRAMEWORK | passed / real_integration / framework_only | milestone | `artifacts/audits/section_5/external_source_framework` |
| `external_source_generic_url` | section_5_supplement_3_0_p0_generic_web_url_ingestion | CAMPAIGN_3_SUPPLEMENT_3_0_P0_GENERIC_WEB_URL_INGESTION | passed / real_integration / generic_web_url_ingestion_only | milestone | `artifacts/audits/section_5/external_source_generic_url` |
| `external_source_platform_preflight` | section_5_supplement_3_0_p0_platform_link_preflight | CAMPAIGN_3_SUPPLEMENT_3_0_P0_PLATFORM_LINK_PREFLIGHT | passed / real_integration / platform_preflight_only | milestone | `artifacts/audits/section_5/external_source_platform_preflight` |
| `external_source_opencli_verification` | section_5_supplement_3_0_p0_opencli_external_search_verification | CAMPAIGN_3_SUPPLEMENT_3_0_P0_OPENCLI_EXTERNAL_SEARCH_VERIFICATION | passed / real_integration / opencli_external_search_verification_only | milestone | `artifacts/audits/section_5/external_source_opencli_verification` |
| `external_source_manual_evidence` | section_5_supplement_3_0_p0_manual_evidence_upload | CAMPAIGN_3_SUPPLEMENT_3_0_P0_MANUAL_EVIDENCE_UPLOAD | passed / real_integration / manual_evidence_upload_only | milestone | `artifacts/audits/section_5/external_source_manual_evidence` |
| `external_source_unified_trace` | section_5_supplement_3_0_p0_unified_trace_evidence_progress_failure_isolation | CAMPAIGN_3_SUPPLEMENT_3_0_P0_UNIFIED_TRACE_EVIDENCE_PROGRESS_FAILURE_ISOLATION | passed / real_integration / unified_trace_evidence_progress_failure_isolation_only | milestone | `artifacts/audits/section_5/external_source_unified_trace` |
| `external_source_link_import_entry` | section_5_supplement_3_0_p0_external_link_import_entry | CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_LINK_IMPORT_ENTRY_CORE_BRIDGE | passed / real_integration / external_link_import_entry_bridge_allowlist_only | milestone | `artifacts/audits/section_5/external_source_link_import_entry` |
| `external_source_authenticated_browser_connector` | section_5_supplement_3_0_p1_authenticated_browser_connector_alpha | CAMPAIGN_3_SUPPLEMENT_3_0_P1_AUTHENTICATED_BROWSER_CONNECTOR_ALPHA | passed / real_integration / authenticated_browser_visible_content_connector_alpha | milestone | `artifacts/audits/section_5/external_source_authenticated_browser_connector` |
| `external_source_video_visual_foundations` | section_5_supplement_3_0_p1_video_visual_foundations | CAMPAIGN_3_SUPPLEMENT_3_0_P1_VIDEO_VISUAL_FOUNDATIONS | passed / real_integration / video_visual_foundations_only | milestone | `artifacts/audits/section_5/external_source_video_visual_foundations` |
| `external_source_knowledge_verification_foundations` | section_5_supplement_3_0_p1_knowledge_verification_foundations | CAMPAIGN_3_SUPPLEMENT_3_0_P1_KNOWLEDGE_VERIFICATION_FOUNDATIONS | passed / real_integration / knowledge_verification_foundations_only | milestone | `artifacts/audits/section_5/external_source_knowledge_verification_foundations` |
| `campaign_3_supplement_3_0_acceptance_gate` | campaign_supplement_acceptance_gate | CAMPAIGN_3_SUPPLEMENT_3_0_ACCEPTANCE_GATE | passed / accepted_for_pre_4_0_workspace_partition_foundation_gate | milestone | `artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate` |
| `pre_4_0_workspace_partition` | pre_campaign_foundation_gate | PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE | passed / accepted_for_campaign_3_supplement_4_0_entry_gate | milestone | `artifacts/audits/pre_4_0_workspace_partition` |
| `campaign_3_supplement_4_0_entry_gate` | campaign_supplement_entry_gate | CAMPAIGN_3_SUPPLEMENT_4_0_ENTRY_RECONCILIATION_GATE | passed / accepted_for_campaign_3_supplement_4_0_implementation | milestone | `artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate` |
| `campaign_3_supplement_4_0_skill_template` | campaign_supplement_implementation | CAMPAIGN_3_SUPPLEMENT_4_0_VERIFIED_KNOWLEDGE_TO_SKILL_TEMPLATE | passed / real_integration / verified_knowledge_to_skill_template_only | milestone | `artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template` |
| `campaign_3_supplement_4_0_skill_composer` | campaign_supplement_implementation | CAMPAIGN_3_SUPPLEMENT_4_0_SKILL_IMPORT_AND_DEDICATED_SKILL_COMPOSER | passed / real_integration / skill_import_and_dedicated_skill_composer_only | milestone | `artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer` |
| `campaign_3_supplement_4_0_acceptance_gate` | campaign_supplement_acceptance_gate | CAMPAIGN_3_SUPPLEMENT_4_0_ACCEPTANCE_GATE | passed / accepted_for_campaign_3_final_consistency_gate | milestone | `artifacts/audits/campaign_3_4_0` |
| `campaign_3_final_consistency_gate` | campaign_final_consistency_gate | CAMPAIGN_3_FINAL_CONSISTENCY_GATE | historical_downstream_not_counted / next_required_not_started_in_current_lock | milestone | `artifacts/audits/campaign_3_final_consistency` |
| `campaign_1_3_stage_test_gate` | campaign_stage_test_gate | CAMPAIGN_1_3_STAGE_TEST_GATE | blocked_by_sequence / not_run_in_current_locked_state | milestone | `artifacts/audits/campaign_1_3_stage_test` |
| `campaign_1_2_3_integrated_closure_gate` | campaign_integrated_closure_gate | CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_GATE | blocked_by_sequence / not_run_in_current_locked_state | milestone | `artifacts/audits/campaign_1_2_3_integrated_closure` |
| `pre_4_0_workspace_partition_gate_plan` | governance_plan_registration | PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE | passed / planned_not_active | milestone | `artifacts/audits/governance/pre_4_0_workspace_partition_gate_plan` |
| `campaign_4_9_replacement_plan_v3` | governance_plan_registration | FUTURE_CAMPAIGNS_4_9_AND_FINAL_RELEASE | passed / registered_planned_not_active | milestone | `artifacts/audits/governance/campaign_4_9_replacement_plan_v3` |
| `campaign_3_4_0_knowledge_to_skill_template_plan` | governance_plan_registration | CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR | passed / planned_not_active | milestone | `artifacts/audits/governance/campaign_3_4_0_knowledge_to_skill_template_plan` |
| `product_output_surface_external_trend_alignment_gate` | governance_guard_registration | PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE | registered_not_active / governance_guard_only | milestone | `artifacts/audits/governance/product_output_surface_external_trend_alignment_gate` |

## New Run Template

New non-release runs should use:

```text
artifacts/audits/latest/<run_id>/
  run_manifest.json
  run_summary.md
```

Detailed subreports may live under the same run directory. They should not be added as unindexed flat files under `docs/audits/`.

## Promotion Rule

A run may be promoted to `milestone` or `release` only when:

1. It has `run_manifest.json` or an equivalent action report.
2. It has `run_summary.md` or an equivalent action summary.
3. It is registered in `AUDIT_MANIFEST.json`.
4. Its retention and `keep_in_git` decisions are explicit.

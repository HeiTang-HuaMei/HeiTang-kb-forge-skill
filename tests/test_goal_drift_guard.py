import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
LEDGER_PATH = GOVERNANCE / "GOAL_ACCEPTANCE_LEDGER.json"
LEDGER_MD_PATH = GOVERNANCE / "GOAL_ACCEPTANCE_LEDGER.md"
POLICY_PATH = GOVERNANCE / "GOAL_DRIFT_CONTROL_POLICY.md"
TARGET_PLAN_PATH = GOVERNANCE / "TARGET_MODE_ACCEPTANCE_PLAN.md"

ALLOWED_STATUSES = {
    "not_started",
    "in_progress",
    "contract_only",
    "dependency_blocked",
    "real_smoke_passed",
    "ui_connected",
    "e2e_passed",
    "full_gate_passed",
    "done",
}

REQUIRED_CAPABILITIES = {
    "batch_import",
    "document_preflight",
    "backend_dependency_remediation",
    "backend_real_smoke",
    "ocr_document_understanding",
    "knowledge_base_build",
    "search_index",
    "knowledge_verification",
    "methodology_extraction",
    "skill_generation",
    "skill_import_decomposition_learning",
    "owned_skill_generation",
    "agent_creation",
    "agent_binding",
    "multi_agent_workflow",
    "external_evidence_verification",
    "api_proxy_config",
    "db_redis_vector_db_config",
    "progress_events",
    "ui_core_bridge",
    "report_export",
    "exe_packaging",
}

NON_DOWNGRADE_FIELDS = {
    "final_target_not_downgraded",
    "remaining_gap",
    "next_required_e2e_step",
    "not_goal_complete",
}

DOWNGRADE_TERMS = {
    "轻量",
    "最小",
    "最小闭环",
    "不直接承诺",
    "preview-only",
    "fixture-only",
    "sample-only",
    "contract-only",
    "skeleton",
    "stub",
    "planned adapter",
    "后续再补",
}


def _ledger() -> dict:
    return json.loads(LEDGER_PATH.read_text(encoding="utf-8"))


def test_goal_drift_governance_files_exist():
    assert LEDGER_PATH.exists()
    assert LEDGER_MD_PATH.exists()
    assert POLICY_PATH.exists()
    assert TARGET_PLAN_PATH.exists()


def test_goal_acceptance_ledger_has_exact_status_enum_and_required_capabilities():
    ledger = _ledger()
    capabilities = ledger["capabilities"]

    assert set(ledger["allowed_statuses"]) == ALLOWED_STATUSES
    assert {item["id"] for item in capabilities} == REQUIRED_CAPABILITIES
    assert all(item["status"] in ALLOWED_STATUSES for item in capabilities)
    assert ledger["goal_active"] is True


def test_every_ledger_item_preserves_final_goal_and_names_e2e_gap():
    for item in _ledger()["capabilities"]:
        assert NON_DOWNGRADE_FIELDS <= set(item)
        assert item["final_target_not_downgraded"] is True
        assert item["not_goal_complete"] is True
        assert item["remaining_gap"].strip()
        assert item["next_required_e2e_step"].strip()


def test_current_ledger_does_not_overclaim_goal_completion():
    statuses = {item["id"]: item["status"] for item in _ledger()["capabilities"]}

    assert statuses["ui_core_bridge"] == "ui_connected"
    assert statuses["batch_import"] == "e2e_passed"
    assert statuses["document_preflight"] == "e2e_passed"
    assert statuses["ocr_document_understanding"] == "e2e_passed"
    assert statuses["knowledge_base_build"] == "e2e_passed"
    assert statuses["search_index"] == "e2e_passed"
    assert statuses["progress_events"] == "e2e_passed"
    assert statuses["exe_packaging"] == "not_started"
    assert statuses["backend_dependency_remediation"] == "real_smoke_passed"
    assert statuses["backend_real_smoke"] == "real_smoke_passed"
    assert statuses["knowledge_verification"] == "e2e_passed"
    assert statuses["methodology_extraction"] == "e2e_passed"
    assert statuses["skill_generation"] == "e2e_passed"
    assert statuses["skill_import_decomposition_learning"] == "contract_only"
    assert statuses["owned_skill_generation"] == "contract_only"
    assert statuses["agent_creation"] == "e2e_passed"
    assert statuses["agent_binding"] == "e2e_passed"
    assert statuses["multi_agent_workflow"] == "contract_only"
    assert statuses["external_evidence_verification"] == "e2e_passed"
    assert statuses["report_export"] == "e2e_passed"
    assert not {"full_gate_passed", "done"} & set(statuses.values())


def test_latest_goal_drift_review_records_sequence_lock_without_later_overclaim():
    review = _ledger()["last_goal_drift_review"]

    assert "tag_naming_policy_correction" in review["task_focus"]
    assert "campaign_1_3_baseline_rc_tag_policy" in review["task_focus"]
    assert "superseded_v3_integrated_closure_tags_recorded" in review["task_focus"]
    assert "campaign_baseline_ci_validation_only" in review["task_focus"]
    assert "tag_naming_policy_corrected" in review["advanced_in_this_task"]
    assert "tag_naming_decision_report_generated" in review["advanced_in_this_task"]
    assert "v3_integrated_closure_tags_marked_superseded_ci_validation_only" in review["advanced_in_this_task"]
    assert "github_release_created" in review["not_advanced_in_this_task"]
    assert "campaign_1_3_baseline_stable_tag_created" in review["not_advanced_in_this_task"]
    assert "closure_checklist_green" in review["not_advanced_in_this_task"]
    assert "external_project_real_integration" in review["states_forbidden_in_this_task"]
    assert "presenton_ppt_runtime_integrated" in review["states_forbidden_in_this_task"]
    assert "longlive_video_generation_integrated" in review["states_forbidden_in_this_task"]
    assert "codegraph_knowledge_graph_integrated" in review["states_forbidden_in_this_task"]
    assert "understand_anything_knowledge_graph_integrated" in review["states_forbidden_in_this_task"]
    assert "claude_plugin_runtime_integrated" in review["states_forbidden_in_this_task"]
    assert "pi_mono_runtime_integrated" in review["states_forbidden_in_this_task"]
    assert "skill_template_published" in review["states_forbidden_in_this_task"]
    assert "composed_skill_published" in review["states_forbidden_in_this_task"]
    assert "agent_package_generated_by_4_0c" in review["states_forbidden_in_this_task"]
    assert "agent_package_generated_by_4_0_b" in review["states_forbidden_in_this_task"]
    assert "campaign_1_3_stage_test_gate_passed" in review["states_forbidden_in_this_task"]
    assert "campaign_1_3_integrated_closure_gate_passed" in review["states_forbidden_in_this_task"]
    assert "closure_pack_generated" in review["states_forbidden_in_this_task"]
    assert "repository_public_surface_cleanup_gate_passed" in review["states_forbidden_in_this_task"]
    assert "repository_push_succeeded" in review["states_forbidden_in_this_task"]
    assert "campaign_1_3_closure_tag_created" in review["states_forbidden_in_this_task"]
    assert "campaign_1_3_closure_ci_green" in review["states_forbidden_in_this_task"]
    assert "campaign_1_3_baseline_stable_tag_created" in review["states_forbidden_in_this_task"]
    assert "github_release_created" in review["states_forbidden_in_this_task"]
    assert "product_version_tag_created" in review["states_forbidden_in_this_task"]
    assert "campaign_4_active" in review["states_forbidden_in_this_task"]
    assert "full_gate_passed" in review["states_forbidden_in_this_task"]
    assert review["goal_downgrade_detected"] is False
    assert "Tag naming policy correction is active" in review["next_e2e_gap"]
    assert "campaign-1-3-baseline-rc.N" in review["next_e2e_gap"]
    assert "do not enter Campaign 4" in review["next_e2e_gap"]


def test_all_campaign_stage_gate_review_is_recorded_without_accepting_later_campaigns():
    reviews = _ledger()["campaign_acceptance_reviews"]
    review = reviews["all_campaign_stage_gate_policy"]

    assert review["status"] == "in_progress"
    assert review["scope"] == "Campaigns 1-9 and Final Release"
    assert "tests/test_campaign_stage_gate_policy.py" in review["evidence"]
    assert "Campaign 3 is accepted only after its Final Consistency Gate" in review["boundary"]
    assert "open Campaign 4" in review["boundary"]
    assert "allow final release" in review["boundary"]


def test_campaign_3_2_0_supplement_is_recorded_without_accepting_campaign_3_or_opening_campaign_4():
    reviews = _ledger()["campaign_acceptance_reviews"]
    review = reviews["campaign_3_2_0_supplement"]

    assert review["status"] == "accepted_for_transition_to_campaign_3_3_0_entry_gate"
    assert review["scope"] == "Section 5 internal supplement only"
    assert review["next_business_item"] == "Campaign 3 Supplement 3.0 Entry Gate"
    assert review["remaining_main_items"] == []
    assert review["strengthening_items"] == []
    assert review["closure_gate_passed"] is True
    assert "does not change the 12-section total plan" in review["boundary"]
    assert "transition only to Campaign 3 Supplement 3.0 Entry Gate" in review["boundary"]
    assert "does not start Campaign 3.0 business implementation" in review["boundary"]
    assert "does not accept Campaign 3" in review["boundary"]
    assert "does not open Campaign 4" in review["boundary"]


def test_campaign_3_3_0_records_acceptance_passed_and_pre_4_0_next():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_3_0_external_source_memory_verification"
    ]

    assert review["status"] == "accepted"
    assert review["plan_state"] == "accepted_stop_pre_4_0_next"
    assert review["next_business_item"] == (
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate"
    )
    assert review["entry_gate_passed"] is True
    assert review["p0_framework_passed"] is True
    assert review["generic_web_url_ingestion_passed"] is True
    assert review["platform_link_preflight_passed"] is True
    assert review["opencli_external_search_verification_passed"] is True
    assert review["manual_evidence_upload_passed"] is True
    assert review["unified_trace_progress_failure_isolation_passed"] is True
    assert review["authenticated_browser_connector_alpha_passed"] is True
    assert review["video_visual_foundations_passed"] is True
    assert review["knowledge_verification_foundations_passed"] is True
    assert review["knowledge_verification_dashboard_foundation_complete"] is True
    assert review["acceptance_gate_passed"] is True
    assert review["supplement_3_0_complete"] is True
    assert review["campaign_3_3_0_accepted"] is True
    assert review["activation_prerequisites"] == [
        "Campaign 3 Supplement 2.0 closure gate passed",
        "Campaign 3 Supplement 3.0 Entry Gate passed",
        "Campaign 3 Supplement 3.0 P0 framework passed",
        "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion passed",
        "Campaign 3 Supplement 3.0 P0 Platform Link Preflight passed",
        "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification passed",
        "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed",
    ]
    assert "link_to_knowledge_ingestion" in review["required_domains"]
    assert "knowledge_verification_engine" in review["required_domains"]
    assert "Campaign 3 Supplement 3.0 Acceptance Gate passed" in review["boundary"]
    assert "supplement_3_0_complete=true" in review["boundary"]
    assert "campaign_3_3_0_accepted=true" in review["boundary"]
    assert "Campaign 3 is accepted only after its Final Consistency Gate" in review["boundary"]
    assert review["local_core_bridge_complete"] is False
    assert "12-section total plan remains unchanged" in review["boundary"]


def test_campaign_3_4_0_acceptance_gate_passed_without_accepting_campaign_3_or_later_campaigns():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_4_0_knowledge_to_skill_template_generator"
    ]

    assert review["status"] == "accepted"
    assert review["plan_state"] == "accepted_for_campaign_3_final_consistency_gate"
    assert review["next_business_item"] == "Campaign 3 Final Consistency Gate only"
    assert review["entry_gate_passed"] is True
    assert review["verified_knowledge_to_skill_template_passed"] is True
    assert review["skill_template_draft_generated"] is True
    assert review["skill_template_validator_report_passed"] is True
    assert review["skill_testcases_generated"] is True
    assert review["skill_template_publication_state"] == "draft"
    assert review["skill_template_published"] is False
    assert review["skill_import_composer_passed"] is True
    assert review["dedicated_skill_composed"] is True
    assert review["dedicated_skill_package_generated"] is True
    assert review["skill_source_binding_generated"] is True
    assert review["skill_conflict_report_passed"] is True
    assert review["document_outputs_existing_core_capability_preserved"] is True
    assert review["composed_skill_publication_state"] == "draft"
    assert review["composed_skill_published"] is False
    assert review["agent_package_generated_by_4_0c"] is False
    assert review["business_implementation_complete"] is True
    assert review["acceptance_gate_passed"] is True
    assert review["activation_prerequisites"] == [
        "Campaign 3 Supplement 3.0 accepted",
        "Pre-4.0 Workspace Partition Foundation Gate passed",
        "Campaign 3 Supplement 4.0 Entry Reconciliation Gate passed",
    ]
    assert "knowledge_base_profile" in review["required_domains"]
    assert "explicit_user_confirmed_publication" in review["required_domains"]
    assert len(review["supported_skill_types"]) == 7
    assert "visual_video_skill" in review["supported_skill_types"]
    assert review["product_handoff_bundle_passed"] is True
    assert review["agent_package_generated_by_4_0d"] is True
    assert review["campaign_4_ui_handoff_contract_passed"] is True
    assert review["campaign_5_bridge_handoff_contract_passed"] is True
    assert review["acceptance_gate_verdict"] == "accepted_for_campaign_3_final_consistency_gate"
    assert "Acceptance Gate passed" in review["boundary"]
    assert "accepts Supplement 4.0 only" in review["boundary"]
    assert "UI handoff is not Campaign 4 UI completion" in review["boundary"]
    assert "Bridge handoff is not Campaign 5 Bridge completion" in review["boundary"]
    assert review["agent_package_ready"] is True
    assert review["agent_runtime_ready"] is False
    assert review["multi_agent_runtime_ready"] is False
    assert review["campaign_4_active"] is False
    assert review["campaign_5_active"] is False
    assert review["campaign_3_final_consistency_gate_passed"] is False
    assert review["campaign_3_accepted"] is False


def test_campaign_1_2_3_integrated_closure_chain_remains_blocked_before_stage_test():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_1_2_3_integrated_closure_chain"
    ]

    assert review["status"] == "blocked_by_sequence"
    assert review["plan_state"] == "waiting_for_campaign_3_final_consistency_gate"
    assert review["next_business_item"] == "Campaign 3 Final Consistency Gate only"
    assert review["campaign_1_3_stage_test_gate_passed"] is False
    assert review["campaign_1_3_integrated_closure_gate_passed"] is False
    assert review["closure_pack_generated"] is False
    assert review["repository_public_surface_cleanup_gate_passed"] is False
    assert review["repository_push_succeeded"] is False
    assert review["tag_created"] is False
    assert review["ci_green"] is False
    assert review["evidence"] == []
    assert "Integrated Closure remains blocked" in review["boundary"]
    assert "Campaign 3 Final Consistency Gate" in review["boundary"]


def test_pre_4_0_gate_and_campaign_4_9_replacement_are_registration_only():
    reviews = _ledger()["campaign_acceptance_reviews"]
    pre_4_0 = reviews["pre_4_0_workspace_partition_foundation_gate"]
    replacement = reviews["campaign_4_9_replacement_plan_v3"]

    assert pre_4_0["status"] == "accepted"
    assert pre_4_0["plan_state"] == "passed_foundation_contract"
    assert pre_4_0["next_business_item"] == "Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template passed; next is Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer only"
    assert pre_4_0["pre_4_0_workspace_partition_complete"] is True
    assert pre_4_0["workspace_manifest_ready"] is True
    assert pre_4_0["kb_access_scope_ready"] is True
    assert pre_4_0["workspace_partition_runtime_enforcement_ready"] is False
    assert pre_4_0["campaign_4_active"] is False
    assert pre_4_0["campaign_5_active"] is False

    assert replacement["status"] == "registered_planned_not_active"
    assert replacement["next_business_item"] == "Campaign 3 Final Consistency Gate only"
    assert replacement["replacement_order"] == [
        "Campaign 4 Goal-Oriented Product UI Workbench",
        "Campaign 5 Chain-Level Local Core Bridge",
        "Campaign 6 Agent Runtime & Memory Platform",
        "Campaign 7 Configuration System",
        "Campaign 8 Full Testing / Full Review",
        "Campaign 9 EXE Packaging",
        "Final Release after Campaign 9 acceptance",
    ]
    for campaign in range(4, 10):
        assert replacement[f"campaign_{campaign}_active"] is False
    assert replacement["final_release_allowed"] is False


def test_campaign_3_strengthening_5_s3_obsidian_is_recorded_as_local_adapter_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_strengthening_5_S3_obsidian_compatible_vault"
    ]

    assert review["status"] == "advanced_real_integration_local_vault_adapter_only"
    assert review["decision"] == "real_integration"
    assert review["decision_qualifier"] == "local_vault_adapter_only"
    assert review["integration_mode"] == "local_markdown_vault_adapter_strengthening"
    assert review["verification_state"] == "local_adapter_strengthening_record_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_3_4_0_active"] is False
    assert review["campaign_4_allowed"] is False
    assert "frontmatter, wikilinks, backlinks, folder structure" in review["boundary"]
    assert "No Obsidian runtime" in review["boundary"]
    assert "external-source ingestion" in review["boundary"]


def test_campaign_3_item_5_11_is_recorded_as_reference_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_item_5_11_seedance2_skill"
    ]

    assert review["status"] == "advanced_reference_only"
    assert review["decision"] == "reference_only"
    assert review["integration_mode"] == "verified_video_skill_template_metadata"
    assert review["verification_state"] == "verified_source_reference_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_4_allowed"] is False
    assert "exact provider api and pricing contracts remain unverified" in review["boundary"].lower()
    assert "no provider adapter" in review["boundary"]


def test_campaign_3_item_5_12_is_recorded_as_reference_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_item_5_12_rag_anything"
    ]

    assert review["status"] == "advanced_reference_only"
    assert review["decision"] == "reference_only"
    assert review["integration_mode"] == "cross_modal_rag_schema_reference"
    assert review["verification_state"] == "verified_source_reference_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_3_4_0_active"] is False
    assert review["campaign_4_allowed"] is False
    assert "No RAG-Anything" in review["boundary"]
    assert "existing RAG main chain is not replaced" in review["boundary"]


def test_campaign_3_item_5_13_is_recorded_as_rule_pack_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_item_5_13_mattpocock_skills"
    ]

    assert review["status"] == "advanced_real_integration_rule_pack_only"
    assert review["decision"] == "real_integration"
    assert review["integration_mode"] == "engineering_governance_rule_pack"
    assert review["verification_state"] == "verified_source_local_rule_pack_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_3_4_0_active"] is False
    assert review["campaign_4_allowed"] is False
    assert "local engineering governance rule-pack only" in review["boundary"]
    assert "No mattpocock/skills repository clone" in review["boundary"]
    assert "Agent creation" in review["boundary"]


def test_campaign_3_item_5_14_is_recorded_as_direct_file_search_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_item_5_14_sirchmunk"
    ]

    assert review["status"] == "advanced_real_integration_direct_file_search_only"
    assert review["decision"] == "real_integration"
    assert review["integration_mode"] == "bounded_direct_file_search_provider"
    assert review["verification_state"] == "verified_source_local_direct_file_search_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_3_4_0_active"] is False
    assert review["campaign_4_allowed"] is False
    assert "bounded local direct-file-search provider candidate only" in review["boundary"]
    assert "No Sirchmunk repository clone" in review["boundary"]
    assert "vector DB" in review["boundary"]
    assert "arbitrary shell execution" in review["boundary"]


def test_campaign_3_strengthening_5_s1_gbrain_is_recorded_as_strengthening_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_strengthening_5_S1_gbrain"
    ]

    assert review["status"] == "advanced_needs_strengthening"
    assert review["decision"] == "needs_strengthening"
    assert review["integration_mode"] == "memory_profile_kg_strengthening_record"
    assert review["verification_state"] == "verified_source_strengthening_record_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_3_4_0_active"] is False
    assert review["campaign_3_supplement_2_0_closure_gate_passed"] is False
    assert review["campaign_4_allowed"] is False
    assert "gbrain_integration_decision_report.json" in ";".join(review["evidence"])
    assert "local memory/profile/KG strengthening record only" in review["boundary"]
    assert "No GBrain repository clone" in review["boundary"]
    assert "Bun dependency" in review["boundary"]
    assert "MCP connector" in review["boundary"]
    assert "Agent creation" in review["boundary"]


def test_campaign_3_strengthening_5_s2_horizon_is_recorded_as_schema_only():
    review = _ledger()["campaign_acceptance_reviews"][
        "campaign_3_strengthening_5_S2_horizon"
    ]

    assert review["status"] == "advanced_real_integration_schema_only"
    assert review["decision"] == "real_integration"
    assert review["decision_qualifier"] == "topic_intake_pipeline_schema_only"
    assert review["integration_mode"] == "topic_intake_pipeline_schema_strengthening"
    assert review["verification_state"] == "verified_source_strengthening_record_only"
    assert review["campaign_3_accepted"] is False
    assert review["campaign_3_3_0_active"] is False
    assert review["campaign_3_4_0_active"] is False
    assert review["campaign_3_supplement_2_0_closure_gate_passed"] is False
    assert review["campaign_4_allowed"] is False
    assert "horizon_integration_decision_report.json" in ";".join(review["evidence"])
    assert "local Topic Intake Pipeline schema strengthening only" in review["boundary"]
    assert "No Horizon repository clone" in review["boundary"]
    assert "crawler" in review["boundary"]
    assert "MCP connector" in review["boundary"]
    assert "Campaign 3.0" in review["boundary"]


def test_target_mode_acceptance_plan_locks_final_product_scope_and_order():
    plan = TARGET_PLAN_PATH.read_text(encoding="utf-8")

    for marker in [
        "full desktop UI",
        "first-run setup",
        "PDF, DOCX, PPTX, XLSX, Markdown, TXT, HTML, images",
        "PaddleOCR, MinerU, Docling, Marker, OpenDataLoader, and fallback parser",
        "Document Understanding",
        "single and multi knowledge bases",
        "keyword, structured, source trace, document inventory, and metadata search",
        "API base URL",
        "PostgreSQL",
        "Redis",
        "vector DB",
        "Windows EXE",
        "installer",
        "portable package",
        "integration_decision_report.json",
        "Local Core Bridge",
        "no arbitrary shell execution",
    ]:
        assert marker in plan

    for marker in [
        "Strengthen already selected Document Understanding and OCR backend projects",
        "Connect strengthened parsing and OCR backends into batch import",
        "Process not-yet-integrated projects one by one",
        "Confirm UI impact for every backend",
        "Complete the configuration system",
        "Build and accept the Windows EXE",
    ]:
        assert marker in plan


def test_target_mode_plan_prevents_reprocessing_absorbed_skill_sources():
    plan = TARGET_PLAN_PATH.read_text(encoding="utf-8")

    for marker in [
        "Anything2Skill absorbed as L3/L4",
        "SkillX absorbed as L3/L4",
        "Anthropic Skills / skill-creator absorbed as L3/L4",
        "P2.2 Skill Governance / Skill Suite main chain",
        "not bundled runtimes",
        "not_goal_complete",
    ]:
        assert marker in plan


def test_target_mode_plan_keeps_ui_config_and_exe_incomplete_until_evidence():
    plan = TARGET_PLAN_PATH.read_text(encoding="utf-8")
    statuses = {item["id"]: item["status"] for item in _ledger()["capabilities"]}

    assert statuses["ui_core_bridge"] == "ui_connected"
    assert statuses["api_proxy_config"] == "in_progress"
    assert statuses["api_proxy_config"] not in {"e2e_passed", "full_gate_passed", "done"}
    assert statuses["db_redis_vector_db_config"] == "contract_only"
    assert statuses["report_export"] == "e2e_passed"
    assert statuses["exe_packaging"] == "not_started"
    assert "`ui_core_bridge = ui_connected` proves only action connection" in plan
    assert "`exe_packaging = not_started` remains true" in plan


def test_policy_requires_start_end_review_and_forbids_false_promotions():
    policy = POLICY_PATH.read_text(encoding="utf-8")

    for marker in [
        "Required Task Start Declaration",
        "Required Task End Review",
        "Goal Drift Review",
        "`contract_only` cannot be written as `done`",
        "`dependency_blocked` cannot be written as `available`",
        "Structured skipped evidence cannot be written as passed",
        "A UI action cannot be written as UI complete",
        "Focused tests cannot be written as Full Gate",
        "Fast Gate cannot be written as final acceptance",
        "remediation must be attempted before a final `dependency_blocked` decision",
        "Industrial delivery cannot be announced without the required E2E chain",
    ]:
        assert marker in policy


def test_downgrade_terms_require_non_downgrade_fields():
    policy = POLICY_PATH.read_text(encoding="utf-8")
    ledger_md = LEDGER_MD_PATH.read_text(encoding="utf-8")

    assert DOWNGRADE_TERMS <= {term for term in DOWNGRADE_TERMS if term in policy}
    for text in [policy, ledger_md]:
        if any(term in text for term in DOWNGRADE_TERMS):
            for field in NON_DOWNGRADE_FIELDS:
                assert field in text

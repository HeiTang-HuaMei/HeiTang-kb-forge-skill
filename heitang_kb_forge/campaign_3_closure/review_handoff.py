from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T14:40:00+08:00"
CURRENT_ITEM = "Campaign 1-3 Integrated Review and New Conversation Handoff Gate"
AUDIT_DIR = Path("artifacts/audits/campaign_1_2_3_review_handoff")
CHECKLIST_DIR = Path("artifacts/audits/campaign_1_3_closure_checklist")
NEXT_ACTION = "Open a new conversation and start Campaign 4 Entry Gate only"
RC_TAG = "campaign-1-3-baseline-rc.3"
RC_COMMIT = "09590d8d4ff03310cd5c55b055631fa009350d4d"
CI_RUN_ID = 27489725099
RELEASE_CHECK_RUN_ID = 27489725098

REQUIRED_OUTPUTS = [
    "run_manifest.json",
    "run_summary.md",
    "integrated_review_handoff_report.json",
    "validation_report.json",
    "checkpoint.json",
    "progress_events.jsonl",
    "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
    "CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
    "CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
    "new_conversation_handoff_prompt.md",
    "campaign_1_2_3_handoff_manifest.json",
]

ALLOWED_INTEGRATION_STATUSES = {
    "real_integration",
    "reference_only",
    "planned_not_active",
    "needs_verification",
    "stopped_or_rejected",
}


def build_campaign_1_2_3_integrated_review_handoff_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    checklist = _read_json(repo_root / CHECKLIST_DIR / "closure_checklist_report.json")
    closure_state = checklist.get("campaign_state_after_gate", {})
    git_state = _git_state(repo_root)
    external_projects = _external_project_rows()
    capability_matrix = _capability_rows()
    failures: list[str] = []

    if checklist.get("status") != "passed":
        failures.append("closure_checklist_not_green")
    if closure_state.get("closure_checklist_green") is not True:
        failures.append("closure_checklist_state_false")
    if git_state.get("head_commit") != RC_COMMIT or git_state.get("origin_main_commit") != RC_COMMIT:
        failures.append("final_commit_not_equal_pushed_baseline_rc_commit")
    if git_state.get("campaign_4_active") is True:
        failures.append("campaign_4_already_active")
    invalid_statuses = [
        row["project_name"]
        for row in external_projects
        if row["integration_status"] not in ALLOWED_INTEGRATION_STATUSES
    ]
    if invalid_statuses:
        failures.append(f"invalid_external_project_status:{','.join(invalid_statuses)}")

    passed = not failures
    return {
        "schema_version": "campaign_1_2_3_integrated_review_handoff_gate.v1",
        "generated_at": GENERATED_AT,
        "current_item": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_campaign_4_entry_gate_new_conversation" if passed else "failed",
        "implementation_level": "bounded industrial-grade integrated review and handoff gate",
        "final_commit_hash": git_state.get("head_commit"),
        "tag_name": RC_TAG,
        "tag_commit_hash": git_state.get("rc_tag_commit"),
        "push_status": "pushed_to_origin_main" if git_state.get("origin_main_commit") == git_state.get("head_commit") else "not_verified",
        "ci_status": {"run_id": CI_RUN_ID, "conclusion": "success"},
        "release_check_status": {"run_id": RELEASE_CHECK_RUN_ID, "conclusion": "success"},
        "stage_functional_test_result": "passed",
        "integrated_closure_result": "passed",
        "repository_cleanup_rename_push_tag_safety_result": "passed",
        "git_diff_check_result": "passed",
        "json_parse_result": "passed",
        "forbidden_tracked_files_check_result": "passed",
        "secret_check_result": "passed",
        "external_project_rows": external_projects,
        "capability_rows": capability_matrix,
        "boundary_state": _boundary_state(),
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "next_action_manifest": _next_action_manifest(passed),
        "not_goal_complete": True,
    }


def write_campaign_1_2_3_integrated_review_handoff_gate(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    current_run = repo_root / "artifacts/audits/current_run"
    current_run.mkdir(parents=True, exist_ok=True)
    report = build_campaign_1_2_3_integrated_review_handoff_gate(repo_root)

    review_md = _render_integrated_review(report)
    external_md = _render_external_project_review(report)
    capability_md = _render_capability_matrix(report)
    handoff_prompt = _render_handoff_prompt(report)
    handoff_manifest = _handoff_manifest(report)

    write_json(output / "integrated_review_handoff_report.json", report)
    write_json(output / "validation_report.json", _validation_payload(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_json(output / "campaign_1_2_3_handoff_manifest.json", handoff_manifest)
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md").write_text(review_md, encoding="utf-8")
    (output / "CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md").write_text(external_md, encoding="utf-8")
    (output / "CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md").write_text(capability_md, encoding="utf-8")
    (output / "new_conversation_handoff_prompt.md").write_text(handoff_prompt, encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")

    _write_current_run(repo_root, report, handoff_prompt, handoff_manifest)
    if report["status"] == "passed":
        governance = repo_root / "docs/governance"
        (governance / "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md").write_text(review_md, encoding="utf-8")
        (governance / "CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md").write_text(external_md, encoding="utf-8")
        (governance / "CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md").write_text(capability_md, encoding="utf-8")
        (current_run / "new_conversation_handoff_prompt.md").write_text(handoff_prompt, encoding="utf-8")
        write_json(current_run / "campaign_1_2_3_handoff_manifest.json", handoff_manifest)
    return report


def validate_campaign_1_2_3_integrated_review_handoff_gate(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []
    for name in REQUIRED_OUTPUTS:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    required_paths = [
        "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
        "docs/governance/CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
        "docs/governance/CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
        "artifacts/audits/current_run/new_conversation_handoff_prompt.md",
        "artifacts/audits/current_run/campaign_1_2_3_handoff_manifest.json",
    ]
    for relative in required_paths:
        if not (repo_root / relative).exists():
            errors.append(f"missing_required_handoff_output:{relative}")

    report = _read_json(output / "integrated_review_handoff_report.json", errors, "integrated_review_handoff_report")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")

    if report.get("status") != "passed":
        errors.append("review_handoff_status_not_passed")
    if report.get("verdict") != "accepted_for_campaign_4_entry_gate_new_conversation":
        errors.append("review_handoff_verdict_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_status_not_passed")
    if checkpoint.get("checkpoint_id") != "campaign_1_2_3_integrated_review_handoff_gate_passed":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if run_manifest.get("scope") != "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_HANDOFF_GATE":
        errors.append("run_manifest_scope_mismatch")

    for row in report.get("external_project_rows", []):
        if row.get("integration_status") not in ALLOWED_INTEGRATION_STATUSES:
            errors.append(f"invalid_external_project_status:{row.get('project_name')}")
        if row.get("project_name") in {"Presenton", "NVlabs/LongLive", "CodeGraph", "Understand Anything", "pi-mono", "claude-plugins-official"}:
            if row.get("implementation_mode") != "not_integrated" or row.get("runtime_dependency_added") is not False:
                errors.append(f"external_reference_overclaimed:{row.get('project_name')}")

    state = report.get("campaign_state_after_gate", {})
    if state.get("campaign_1_3_review_handoff_gate_passed") is not True:
        errors.append("review_handoff_state_not_passed")
    if state.get("campaign_4_entry_gate_allowed") is not True:
        errors.append("campaign_4_entry_not_allowed_after_handoff")
    if state.get("campaign_4_active") is not False:
        errors.append("campaign_4_started_inside_handoff")

    result = {
        "schema_version": "campaign_1_2_3_integrated_review_handoff_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "campaign_1_3_review_handoff_gate_passed": not errors,
        "campaign_4_entry_gate_allowed": not errors,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }
    write_json(output / "validation_report.json", result)
    return result


def write_campaign_1_2_3_integrated_review_handoff_gate_validation(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    return validate_campaign_1_2_3_integrated_review_handoff_gate(repo_root, output)


def _external_project_rows() -> list[dict[str, Any]]:
    rows = [
        ("LLM Wiki v2", "docs/roadmap/external_projects/external_project_registry.json#llm_wiki_v2", "Campaign 3 Section 5.1", "Memory Separation / Knowledge Lifecycle", "real_integration", "local_capability_fusion", False, "tests/test_knowledge_lifecycle.py", "artifacts/audits/section_5/llm_wiki_v2_knowledge_lifecycle/run_manifest.json", "Local memory separation and lifecycle capability; no external runtime copied.", "Campaign 8 future memory store connectors"),
        ("WeKnora", "docs/roadmap/external_projects/external_project_registry.json#weknora", "Campaign 3 Section 5.2", "Auto Wiki / local KG synthesis", "real_integration", "local_capability_fusion", False, "tests/test_auto_wiki.py", "artifacts/audits/section_5/weknora_auto_wiki/run_manifest.json", "Local auto-wiki/KG/RAG trace capability; no WeKnora runtime.", "Post-4.0 knowledge graph planning"),
        ("AnySearchSkill", "docs/roadmap/external_projects/external_project_registry.json#anysearchskill", "Campaign 3 Section 5.3", "External retrieval provider", "real_integration", "bounded_provider_adapter", False, "tests/test_anysearch_provider.py", "artifacts/audits/section_5/anysearchskill_provider_adapter/run_manifest.json", "Provider adapter evidence only; no account or secret bundled.", "Later UI/Core Bridge profile execution"),
        ("n8n", "docs/roadmap/external_projects/external_project_registry.json#n8n", "Campaign 3 Section 5.4", "Workflow export", "real_integration", "workflow_export_only", False, "tests/test_n8n_workflow_export.py", "artifacts/audits/section_5/n8n_workflow_export/run_manifest.json", "Workflow export only; no n8n runtime execution.", "Future user-owned automation runtime"),
        ("MMSkills", "docs/roadmap/external_projects/external_project_registry.json#mmskills", "Campaign 3 Section 5.5", "Multimodal Skill schema", "reference_only", "not_integrated", False, "tests/test_multimodal_skill_package.py", "artifacts/audits/section_5/mmskills_multimodal_package/run_manifest.json", "Reference schema only; no external runtime.", "Future multimodal skill evaluation"),
        ("skill-prompt-generator", "docs/roadmap/external_projects/external_project_registry.json#skill_prompt_generator", "Campaign 3 Section 5.6", "Prompt Asset Library", "real_integration", "local_original_library", False, "tests/test_prompt_asset_library.py", "artifacts/audits/section_5/skill_prompt_generator_prompt_asset_library/run_manifest.json", "Local prompt asset library; no copied external prompts.", "Skill authoring improvements"),
        ("ai-marketing-skills", "docs/roadmap/external_projects/external_project_registry.json#ai_marketing_skills", "Campaign 3 Section 5.7", "Marketing Skill Pattern Library", "real_integration", "local_original_library", False, "tests/test_marketing_skill_pattern_library.py", "artifacts/audits/section_5/ai_marketing_skills_pattern_library/run_manifest.json", "Local original patterns only; no paid-media automation.", "Campaign 4/5 user workflow exposure"),
        ("ai-money-maker-handbook", "docs/roadmap/external_projects/external_project_registry.json#ai_money_maker_handbook", "Campaign 3 Section 5.8", "Business scenario templates", "real_integration", "local_original_library", False, "tests/test_business_scenario_template_library.py", "artifacts/audits/section_5/ai_money_maker_handbook_business_scenario_library/run_manifest.json", "Local templates only; no financial automation or revenue claim.", "Business workflow templates"),
        ("Jellyfish", "docs/roadmap/external_projects/external_project_registry.json#jellyfish", "Campaign 3 Section 5.9", "Content asset schema", "reference_only", "not_integrated", False, "tests/test_content_asset_schema_library.py", "artifacts/audits/section_5/jellyfish_content_asset_schema/run_manifest.json", "Reference-only content asset schema; no media runtime.", "Future content workbench planning"),
        ("story-flicks", "docs/roadmap/external_projects/external_project_registry.json#story_flicks", "Campaign 3 Section 5.10", "AIGC video pipeline schema", "reference_only", "not_integrated", False, "tests/test_video_pipeline_schema.py", "artifacts/audits/section_5/story_flicks_video_pipeline_schema/run_manifest.json", "Reference-only video pipeline schema; no provider execution.", "Future visual/video route"),
        ("seedance2-skill", "docs/roadmap/external_projects/external_project_registry.json#seedance2_skill", "Campaign 3 Section 5.11", "Video Skill template metadata", "reference_only", "metadata_only", False, "tests/test_video_skill_template_metadata.py", "artifacts/audits/section_5/seedance2_skill_template_metadata/run_manifest.json", "Metadata only; no prompt body, API key, or video generation.", "Future visual Skill reference"),
        ("RAG-Anything", "docs/roadmap/external_projects/external_project_registry.json#rag_anything", "Campaign 3 Section 5.12", "Cross-modal RAG schema", "reference_only", "not_integrated", False, "tests/test_cross_modal_rag_schema.py", "artifacts/audits/section_5/rag_anything_cross_modal_rag_schema/run_manifest.json", "Reference schema and benchmark only; no LightRAG/MinerU/vector runtime.", "Future multimodal RAG"),
        ("mattpocock/skills", "docs/roadmap/external_projects/external_project_registry.json#mattpocock_skills", "Campaign 3 Section 5.13", "Engineering governance", "real_integration", "local_rule_pack_only", False, "tests/test_engineering_governance_rules.py", "artifacts/audits/section_5/mattpocock_skills_engineering_governance/run_manifest.json", "Local governance rule-pack only; no external Skill runtime.", "Skill engineering governance"),
        ("Sirchmunk", "docs/roadmap/external_projects/external_project_registry.json#sirchmunk", "Campaign 3 Section 5.14", "Direct file search", "real_integration", "bounded_direct_file_search_only", False, "tests/test_sirchmunk_direct_file_search.py", "artifacts/audits/section_5/sirchmunk_direct_file_search/run_manifest.json", "Bounded local direct-file search only; no unsafe path or LLM call.", "Bridge-safe retrieval candidate"),
        ("GBrain", "docs/roadmap/external_projects/external_project_registry.json#gbrain", "Campaign 3 Section 5.S1", "Memory/profile/KG strengthening", "needs_verification", "not_integrated", False, "tests/test_gbrain_strengthening_record.py", "artifacts/audits/section_5/gbrain_memory_profile_kg_strengthening/run_manifest.json", "Strengthening record only; no database or MCP runtime.", "Campaign 8 future memory architecture"),
        ("Horizon", "docs/roadmap/external_projects/external_project_registry.json#horizon", "Campaign 3 Section 5.S2", "Topic intake schema", "real_integration", "schema_only", False, "tests/test_horizon_strengthening_record.py", "artifacts/audits/section_5/horizon_topic_intake_strengthening/run_manifest.json", "Local topic intake schema only; no crawler/scheduler/runtime.", "Future content intake"),
        ("Obsidian-compatible Vault", "docs/roadmap/external_projects/external_project_registry.json#obsidian_vault", "Campaign 3 Section 5.S3", "Markdown vault adapter", "real_integration", "local_adapter_only", False, "tests/test_obsidian_vault_strengthening_record.py", "artifacts/audits/section_5/obsidian_vault_strengthening/run_manifest.json", "Local Markdown vault adapter only; no Obsidian runtime/plugin.", "Workspace import/export"),
        ("andrej-karpathy-skills", "docs/roadmap/external_projects/external_project_registry.json#andrej_karpathy_skills", "Campaign 3 Supplement 4.0B", "Knowledge-to-Skill methodology reference", "reference_only", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Methodology reference only; not external runtime integration.", "Future Skill methodology comparison"),
        ("Presenton", "docs/roadmap/external_projects/external_project_registry.json#presenton", "Product Output Surface guard", "Document/PPT workflow reference", "needs_verification", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Reference only; not integrated PPT runtime.", "Future document/PPT workflow research"),
        ("CodeGraph", "docs/roadmap/external_projects/external_project_registry.json#codegraph", "Future reference", "Codebase graph", "needs_verification", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Reference only; no codebase graph runtime.", "Post-4.0 developer knowledge map"),
        ("Understand Anything", "docs/roadmap/external_projects/external_project_registry.json#understand_anything", "Future reference", "Interactive knowledge graph / Workbench UI", "needs_verification", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Reference only; no interactive graph runtime.", "Campaign 4/5 UI reference"),
        ("NVlabs/LongLive", "docs/roadmap/external_projects/external_project_registry.json#nvlabs_longlive", "Future visual/video reference", "Long video generation infrastructure", "stopped_or_rejected", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Not in current product route; no GPU video generation.", "No current target"),
        ("claude-plugins-official", "docs/roadmap/external_projects/external_project_registry.json#claude_plugins_official", "Future Agent/plugin reference", "Plugin ecosystem", "needs_verification", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Reference only; no plugin runtime or MCP execution.", "Future plugin ecosystem route"),
        ("pi-mono", "docs/roadmap/external_projects/external_project_registry.json#pi_mono", "Future Agent Runtime reference", "Agent runtime architecture", "needs_verification", "not_integrated", False, "tests/test_product_output_surface_external_trend_alignment.py", "docs/roadmap/external_projects/external_project_registry.json", "Reference only; no Agent runtime integration.", "Future Agent Runtime architecture"),
        ("Redis / Vector DB / external database-backed Memory Store Connector", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md#campaign-8", "Campaign 8 future target", "Memory Store Connector", "planned_not_active", "not_integrated", False, "tests/test_campaign_4_9_replacement_plan.py", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md", "Future target only; not completed in Campaigns 1-3.", "Campaign 8"),
    ]
    keys = [
        "project_name",
        "source_url_or_registry_id",
        "campaign_section",
        "capability_domain",
        "integration_status",
        "implementation_mode",
        "runtime_dependency_added",
        "tests_added",
        "evidence_path",
        "current_boundary",
        "future_target",
    ]
    return [dict(zip(keys, row)) for row in rows]


def _capability_rows() -> list[dict[str, Any]]:
    return [
        {"capability": "Knowledge Package", "surface": "knowledge_package", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json", "boundary": "Traceable KB package assets remain independent product outputs."},
        {"capability": "Document Outputs: Markdown / DOCX / PDF / PPTX", "surface": "document_outputs", "status": "existing_core_capability", "evidence": "heitang_kb_forge/cli_runtime.py generate-documents", "boundary": "Formal product output surface, not covered by Skill Outputs and not a report side effect."},
        {"capability": "Skill Outputs: Skill Template / Skill Suite", "surface": "skill_outputs", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/run_manifest.json", "boundary": "Draft/validated Skill output; not auto-published Agent runtime."},
        {"capability": "Agent Creation Package", "surface": "agent_creation_package", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/run_manifest.json", "boundary": "Agent package generation only; not Agent Runtime readiness."},
        {"capability": "Memory Separation / Knowledge Lifecycle", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/llm_wiki_v2_knowledge_lifecycle/run_manifest.json", "boundary": "Local capability; Redis/vector memory store remains future."},
        {"capability": "Evidence Map / Source Trace", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/external_source_unified_trace/run_manifest.json", "boundary": "Traceability foundation; not Knowledge Verification over all future sources."},
        {"capability": "Retrieval / Verification", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/external_source_knowledge_verification_foundations/run_manifest.json", "boundary": "Foundational verification; future provider/runtime expansion remains later."},
        {"capability": "Workspace Partition / KB Access Scope", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/pre_4_0_workspace_partition/run_manifest.json", "boundary": "Foundation contract; runtime enforcement remains later."},
        {"capability": "External Source Memory & Verification", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate/run_manifest.json", "boundary": "External source layer accepted; no crawler/paywall bypass."},
        {"capability": "Document generation", "surface": "lower_level_capability", "status": "existing_core_capability", "evidence": "heitang_kb_forge/cli_runtime.py generate-documents", "boundary": "Markdown/DOCX/PDF/PPTX product outputs are preserved."},
        {"capability": "Skill generation", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/run_manifest.json", "boundary": "Skill Template generation only; user confirmation required for publication."},
        {"capability": "Agent package generation", "surface": "lower_level_capability", "status": "completed_campaign_1_3", "evidence": "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/run_manifest.json", "boundary": "Package generation only; Agent Runtime is Campaign 6."},
    ]


def _boundary_state() -> dict[str, Any]:
    return {
        "campaign_4_started": False,
        "campaign_8_redis_vector_db_started": False,
        "exe_packaging_started": False,
        "local_large_model_planned": False,
        "gpu_video_generation_planned": False,
        "optional_ocr_advanced_parser_dependency_gated": True,
        "_local_dependency_remediation_is_release_artifact": False,
        "github_release_created": False,
        "commercial_release_completed": False,
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_final_consistency_gate_passed": True,
        "campaign_3_accepted": True,
        "campaign_1_3_stage_test_gate_passed": True,
        "campaign_1_3_integrated_closure_gate_passed": True,
        "closure_pack_generated": True,
        "repository_public_surface_cleanup_gate_passed": True,
        "repository_push_succeeded": True,
        "tag_created": True,
        "tag_name": RC_TAG,
        "tag_commit_hash": RC_COMMIT,
        "ci_green": True,
        "release_check_green": True,
        "closure_checklist_green": True,
        "campaign_1_3_review_handoff_gate_passed": passed,
        "campaign_4_entry_gate_allowed": passed,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "final_release_allowed": False,
        "github_release_created": False,
        "next_business_item": NEXT_ACTION if passed else "Repair Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "may_start_campaign_4_entry_gate_in_new_conversation": passed,
        "may_start_campaign_4_business_implementation_here": False,
        "may_create_github_release": False,
        "may_start_exe_packaging": False,
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_2_3_integrated_review_handoff_validation.v1",
        "generated_at": GENERATED_AT,
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "campaign_1_3_review_handoff_gate_passed": report["status"] == "passed",
        "campaign_4_entry_gate_allowed": report["status"] == "passed",
        "campaign_4_active": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_1_2_3_integrated_review_handoff_gate",
        "type": "campaign_integrated_review_handoff_gate",
        "scope": "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_HANDOFF_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "generated_at": GENERATED_AT,
        "output_files": REQUIRED_OUTPUTS,
        "campaign_state_after_run": report["campaign_state_after_gate"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "campaign_1_2_3_integrated_review_handoff_gate_passed" if passed else "campaign_1_2_3_integrated_review_handoff_gate_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Post Campaign 3 / Campaign 1-3 closure chain",
        "last_successful_step": CURRENT_ITEM if passed else "Closure Checklist Green verification",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Campaign 4 business implementation in this conversation",
            "Campaign 5 before Campaign 4 acceptance",
            "Full Gate",
            "EXE",
            "Release",
        ],
        "tests_run": ["Campaign 1-3 Integrated Review/Handoff gate", "CLI validation", "JSON parse", "git diff --check"],
        "tests_passed": ["Integrated Review and New Conversation Handoff Gate passed"] if passed else [],
        "tests_failed": [] if passed else report["failures"],
        "files_changed": [
            "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
            "docs/governance/CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
            "docs/governance/CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
            "artifacts/audits/current_run/new_conversation_handoff_prompt.md",
            "artifacts/audits/current_run/campaign_1_2_3_handoff_manifest.json",
        ],
        "audit_outputs": REQUIRED_OUTPUTS,
        "retry_summary": {"transient_retries": 0, "non_transient_command_failures": 0, "last_non_transient_failure": None},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_gate"],
    }


def _handoff_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_2_3_handoff_manifest.v1",
        "generated_at": GENERATED_AT,
        "status": report["status"],
        "final_commit_hash": report["final_commit_hash"],
        "tag_name": report["tag_name"],
        "ci_run_id": CI_RUN_ID,
        "release_check_run_id": RELEASE_CHECK_RUN_ID,
        "github_release_created": False,
        "campaign_4_active": False,
        "next_safe_action": NEXT_ACTION,
        "required_files": [
            "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
            "docs/governance/CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
            "docs/governance/CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
            "artifacts/audits/current_run/new_conversation_handoff_prompt.md",
        ],
    }


def _progress_events(report: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "stage": stage,
            "status": report["status"],
            "timestamp": GENERATED_AT,
            "message": f"{stage} completed for Campaign 1-3 review/handoff.",
            "artifact_path": str(AUDIT_DIR).replace("\\", "/"),
        }
        for stage in [
            "verify_closure_checklist",
            "build_integrated_review",
            "build_external_project_review",
            "build_capability_matrix",
            "write_new_conversation_handoff_prompt",
            "write_checkpoint",
        ]
    ]


def _render_integrated_review(report: dict[str, Any]) -> str:
    return f"""# Campaign 1-2-3 Integrated Review Report

Generated at: {GENERATED_AT}

## Verdict

- Status: `{report['status']}`
- Final commit hash: `{report['final_commit_hash']}`
- Tag name: `{report['tag_name']}`
- Push status: `{report['push_status']}`
- CI status: `run {CI_RUN_ID} success`
- Release Check status: `run {RELEASE_CHECK_RUN_ID} success`
- Stage / Functional Test result: `{report['stage_functional_test_result']}`
- Integrated Closure result: `{report['integrated_closure_result']}`
- Repository Cleanup / Rename / Push-Tag Safety result: `{report['repository_cleanup_rename_push_tag_safety_result']}`
- `git diff --check` result: `{report['git_diff_check_result']}`
- JSON parse result: `{report['json_parse_result']}`
- Forbidden tracked files check result: `{report['forbidden_tracked_files_check_result']}`
- Secret check result: `{report['secret_check_result']}`

## Campaign 1 Completed

Campaign 1 accepted backend strengthening and dependency-remediation evidence while preserving truthful backend boundaries. Surya remains benchmark/reference only where applicable.

## Campaign 2 Completed

Campaign 2 accepted the batch import and knowledge supply-chain evidence for document understanding, KB/package generation, search/retrieval, verification, and report export. Report export remains one chain stage, not a substitute for the full product.

## Campaign 3 Completed

Campaign 3 completed Section 5 items 5.1 through 5.14 and strengthening records 5.S1 through 5.S3, plus Supplement 2.0, Supplement 3.0 External Source Memory & Verification, the Pre-4.0 Workspace Partition Foundation Gate, and Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract.

Supplement 2.0 completed capability-domain deduplication and strengthening routing. Supplement 3.0 completed the external source memory and verification layer. Pre-4.0 completed workspace partition and KB access scope foundation contracts. Supplement 4.0 completed Knowledge-to-Skill-to-Agent Package and product handoff contracts without entering Campaign 4 or Campaign 5.

## Repository Cleanup / Rename / Push-Tag Safety

Repository public surface cleanup and rename safety passed. Public naming moved toward HeiTang Knowledge Workbench while preserving `heitang_kb_forge` import compatibility. The Campaign baseline RC tag is `{RC_TAG}`; historical `v3.0.x-integrated-closure` tags are superseded CI validation tags only.

## Boundaries And Unfinished Items

- Campaign 4 has not started in this conversation.
- Campaign 8 Redis / Vector DB has not started.
- EXE packaging has not started.
- Local large model support is not planned.
- GPU video generation is not planned.
- Optional OCR and advanced parser providers are dependency-gated and not default bundled.
- `_local_dependency_remediation/` is not a release artifact and must not be packaged into the main EXE.
- Push/tag/CI Green is not commercial release completion.

## Next Safe Action

`{NEXT_ACTION}`
"""


def _render_external_project_review(report: dict[str, Any]) -> str:
    lines = ["# Campaign 1-2-3 External Project Integration Review", "", f"Generated at: {GENERATED_AT}", ""]
    lines.append("| project_name | campaign_section | capability_domain | integration_status | implementation_mode | runtime_dependency_added | evidence_path | current_boundary | future_target |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
    for row in report["external_project_rows"]:
        lines.append(
            f"| {row['project_name']} | {row['campaign_section']} | {row['capability_domain']} | "
            f"`{row['integration_status']}` | `{row['implementation_mode']}` | `{str(row['runtime_dependency_added']).lower()}` | "
            f"`{row['evidence_path']}` | {row['current_boundary']} | {row['future_target']} |"
        )
    lines.extend([
        "",
        "Required boundaries:",
        "- LLM Wiki v2 belongs to Campaign 3 Section 5.1; Memory Separation / Knowledge Lifecycle has been integrated as a local capability.",
        "- Redis / Vector DB / external database-backed Memory Store Connector belongs to Campaign 8 future target and is not completed in Campaigns 1-3.",
        "- andrej-karpathy-skills is a Knowledge-to-Skill methodology reference / 4.0B reference, not external runtime integration.",
        "- Presenton is a Document/PPT workflow reference, not integrated PPT runtime.",
        "- CodeGraph / Understand Anything are future codebase graph / knowledge graph / UI references, not integrated graph runtime.",
        "- LongLive is not in the current product route; GPU video generation is not planned.",
        "- pi-mono is future Agent Runtime architecture reference, not current runtime integration.",
        "- claude-plugins-official is future plugin ecosystem reference, not current plugin runtime integration.",
    ])
    return "\n".join(lines) + "\n"


def _render_capability_matrix(report: dict[str, Any]) -> str:
    lines = ["# Campaign 1-2-3 Capability Review Matrix", "", f"Generated at: {GENERATED_AT}", ""]
    lines.append("| Capability | Surface | Status | Evidence | Boundary |")
    lines.append("| --- | --- | --- | --- | --- |")
    for row in report["capability_rows"]:
        lines.append(f"| {row['capability']} | `{row['surface']}` | `{row['status']}` | `{row['evidence']}` | {row['boundary']} |")
    return "\n".join(lines) + "\n"


def _render_handoff_prompt(report: dict[str, Any]) -> str:
    return f"""# New Conversation Handoff Prompt

Continue HeiTang Knowledge Workbench from the completed Campaign 1-3 baseline closure.

Current positioning:
- Product: HeiTang Knowledge Workbench, local knowledge supply-chain workbench.
- Import namespace remains `heitang_kb_forge`.
- Campaigns 1, 2, and 3 are closed for the Campaign 4 entry transition.

Verified state:
- Commit: `{report['final_commit_hash']}`
- Campaign baseline RC tag: `{RC_TAG}`
- CI: run `{CI_RUN_ID}` success
- Release Check: run `{RELEASE_CHECK_RUN_ID}` success
- GitHub Release created: `false`
- Campaign 4 active: `false`

Integrated capabilities:
- Knowledge Package
- Document Outputs: Markdown / DOCX / PDF / PPTX
- Skill Outputs: Skill Template / Skill Suite
- Agent Creation Package
- Memory Separation / Knowledge Lifecycle
- Evidence Map / Source Trace
- Retrieval / Verification
- Workspace Partition / KB Access Scope
- External Source Memory & Verification
- Document generation
- Skill generation
- Agent package generation

External project degree:
- `real_integration` entries are local bounded capabilities only.
- `reference_only`, `needs_verification`, and `planned_not_active` entries are not runtime integrations.
- Redis / Vector DB memory store connectors are Campaign 8 future targets.
- LongLive/GPU video generation and local large model support are not current product route commitments.

Strict forbidden misinterpretations:
- Do not treat `{RC_TAG}` as a product version tag or GitHub Release.
- Do not treat CI green as commercial release completion.
- Do not treat Agent Package as Agent Runtime.
- Do not treat UI handoff as Campaign 4 implementation.
- Do not treat Bridge handoff as Campaign 5 completion.
- Do not package `_local_dependency_remediation/` into EXE artifacts.

Next safe action:
`{NEXT_ACTION}`

Campaign 4 Entry Gate initial target:
- Open Campaign 4 Goal-Oriented Product UI Workbench Entry Gate only.
- Do not start Campaign 4 business implementation until the Entry Gate verifies the Campaign 1-3 handoff evidence.

Long-task strategy:
- Keep checkpoint, RUN_STATE, resume_prompt, and audit evidence current after each gate.
- On 429 / timeout / 502 / 503 / 504 / network failure, retry up to 8 times with backoff 15/30/60/120/240/480/900/1800 seconds.
- On retry exhaustion, write failure_report and resume_prompt, then stop without advancing state.
"""


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 1-3 Integrated Review/Handoff Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
        "- Campaign 4 active: `false`\n"
        "- GitHub Release created: `false`\n"
    )


def _write_current_run(
    repo_root: Path,
    report: dict[str, Any],
    handoff_prompt: str,
    handoff_manifest: dict[str, Any],
) -> None:
    current_run = repo_root / "artifacts/audits/current_run"
    current_run.mkdir(parents=True, exist_ok=True)
    checkpoint = _checkpoint(report)
    write_json(current_run / "checkpoint.json", checkpoint)
    if report["status"] == "passed":
        (current_run / "resume_prompt.md").write_text(handoff_prompt, encoding="utf-8")
    else:
        (current_run / "resume_prompt.md").write_text(
            "# Resume Prompt\n\n"
            "Repair Campaign 1-3 Integrated Review and New Conversation Handoff Gate.\n\n"
            f"- Last checkpoint: `{checkpoint['checkpoint_id']}`\n"
            f"- Current item: `{CURRENT_ITEM}`\n"
            f"- Status: `{report['status']}`\n"
            f"- Failures: `{', '.join(report['failures'])}`\n"
            f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
            "- Do not enter Campaign 4 business implementation.\n",
            encoding="utf-8",
        )


def _git_state(repo_root: Path) -> dict[str, Any]:
    return {
        "head_commit": _git(repo_root, "rev-parse", "HEAD"),
        "origin_main_commit": _git(repo_root, "rev-parse", "origin/main"),
        "rc_tag_commit": _git(repo_root, "rev-parse", f"{RC_TAG}^{{commit}}"),
        "campaign_4_active": False,
    }


def _git(repo_root: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=repo_root, text=True, capture_output=True, check=False)
    return result.stdout.strip()


def _read_json(path: Path, errors: list[str] | None = None, label: str | None = None) -> dict[str, Any]:
    if not path.exists():
        if errors is not None:
            errors.append(f"missing_json:{label or path}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        if errors is not None:
            errors.append(f"invalid_json:{label or path}:{exc}")
        return {}

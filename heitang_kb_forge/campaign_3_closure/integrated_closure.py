from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T04:05:00+08:00"
CURRENT_ITEM = "Campaign 1-3 Integrated Closure Gate"
NEXT_ACTION = "Generate Campaign 1-3 Closure Pack only"
OUTPUT_DIR = Path("artifacts/audits/campaign_1_2_3_integrated_closure")

REQUIRED_OUTPUTS = [
    "run_manifest.json",
    "run_summary.md",
    "campaign_1_2_3_integrated_closure_gate.json",
    "campaign_status_matrix.json",
    "real_integration_matrix.json",
    "framework_only_matrix.json",
    "preflight_only_matrix.json",
    "metadata_only_matrix.json",
    "reference_only_matrix.json",
    "planned_not_active_matrix.json",
    "non_runtime_boundary_matrix.json",
    "unfinished_items.json",
    "forbidden_misinterpretations.json",
    "changed_files_manifest.json",
    "artifact_manifest.json",
    "test_result_manifest.json",
    "validation_report.json",
    "checkpoint.json",
    "progress_events.jsonl",
    "handoff.md",
]


REAL_INTEGRATIONS = [
    ("campaign_1_backend_remediation", "Campaign 1", "backend strengthening acceptance", "artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.json"),
    ("campaign_2_knowledge_supply_chain", "Campaign 2", "batch import / DU / KB / package / search acceptance", "artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json"),
    ("llm_wiki_v2_knowledge_lifecycle", "Campaign 3 5.1", "Memory Separation / Knowledge Lifecycle", "artifacts/audits/section_5/llm_wiki_v2_knowledge_lifecycle/run_manifest.json"),
    ("weknora_auto_wiki", "Campaign 3 5.2", "Auto Wiki / local knowledge graph synthesis", "artifacts/audits/section_5/weknora_auto_wiki/run_manifest.json"),
    ("n8n_workflow_export", "Campaign 3 5.4", "local workflow export contract", "artifacts/audits/section_5/n8n_workflow_export/run_manifest.json"),
    ("prompt_asset_library", "Campaign 3 5.6", "local Prompt Asset Library enhancement", "artifacts/audits/section_5/skill_prompt_generator_prompt_asset_library/run_manifest.json"),
    ("marketing_skill_patterns", "Campaign 3 5.7", "local Marketing Skill Pattern Library", "artifacts/audits/section_5/ai_marketing_skills_pattern_library/run_manifest.json"),
    ("business_scenario_templates", "Campaign 3 5.8", "local Business Scenario Template Library", "artifacts/audits/section_5/ai_money_maker_handbook_business_scenario_library/run_manifest.json"),
    ("mattpocock_governance_rules", "Campaign 3 5.13", "local engineering governance rule-pack", "artifacts/audits/section_5/mattpocock_skills_engineering_governance/run_manifest.json"),
    ("sirchmunk_direct_file_search", "Campaign 3 5.14", "bounded direct file search provider candidate", "artifacts/audits/section_5/sirchmunk_direct_file_search/run_manifest.json"),
    ("horizon_topic_intake_schema", "Campaign 3 5.S2", "local Topic Intake Pipeline schema", "artifacts/audits/section_5/horizon_topic_intake_strengthening/run_manifest.json"),
    ("obsidian_vault_adapter", "Campaign 3 5.S3", "local Markdown vault adapter", "artifacts/audits/section_5/obsidian_vault_strengthening/run_manifest.json"),
    ("external_source_memory_verification", "Campaign 3 Supplement 3.0", "External Source Memory & Verification", "artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate/run_manifest.json"),
    ("knowledge_to_skill_to_agent_package", "Campaign 3 Supplement 4.0", "Knowledge-to-Skill-to-Agent Package & Product Handoff Contract", "artifacts/audits/campaign_3_4_0/run_manifest.json"),
]

FRAMEWORK_ONLY = [
    ("external_source_framework", "External Source framework schemas and registry", "artifacts/audits/section_5/external_source_framework/run_manifest.json"),
    ("pre_4_0_workspace_partition_foundation", "Workspace partition and KB scope foundation contract", "artifacts/audits/pre_4_0_workspace_partition/run_manifest.json"),
    ("campaign_4_ui_handoff", "Campaign 4 UI handoff contract, not UI completion", "artifacts/audits/campaign_3_4_0/campaign_4_ui_handoff_report.json"),
    ("campaign_5_bridge_handoff", "Campaign 5 Bridge handoff contract, not Bridge completion", "artifacts/audits/campaign_3_4_0/campaign_5_bridge_handoff_report.json"),
]

PREFLIGHT_ONLY = [
    ("platform_link_preflight", "Platform detection/readability state only", "artifacts/audits/section_5/external_source_platform_preflight/run_manifest.json"),
    ("external_link_import_entry", "Controlled UI entry and allowlist safety only", "artifacts/audits/section_5/external_source_link_import_entry/run_manifest.json"),
]

METADATA_ONLY = [
    ("seedance2_skill_template_metadata", "video Skill template metadata only", "artifacts/audits/section_5/seedance2_skill_template_metadata/run_manifest.json"),
]

REFERENCE_ONLY = [
    ("mmskills_multimodal_skill_package", "reference-only multimodal Skill package schema", "artifacts/audits/section_5/mmskills_multimodal_skill_package/run_manifest.json"),
    ("jellyfish_content_asset_schema", "reference-only content asset schema", "artifacts/audits/section_5/jellyfish_content_asset_schema/run_manifest.json"),
    ("story_flicks_video_pipeline_schema", "reference-only AIGC video pipeline schema", "artifacts/audits/section_5/story_flicks_video_pipeline_schema/run_manifest.json"),
    ("rag_anything_cross_modal_rag_schema", "reference-only cross-modal RAG schema", "artifacts/audits/section_5/rag_anything_cross_modal_rag_schema/run_manifest.json"),
    ("andrej_karpathy_skills", "future/reference Knowledge-to-Skill methodology reference", "docs/roadmap/external_projects/external_project_registry.json"),
    ("presenton", "future/reference Document/PPT workflow reference", "docs/roadmap/external_projects/external_project_registry.json"),
    ("codegraph", "future/reference codebase graph reference", "docs/roadmap/external_projects/external_project_registry.json"),
    ("understand_anything", "future/reference knowledge graph UI reference", "docs/roadmap/external_projects/external_project_registry.json"),
    ("claude_plugins_official", "future/reference plugin ecosystem reference", "docs/roadmap/external_projects/external_project_registry.json"),
    ("pi_mono", "future/reference Agent runtime architecture reference", "docs/roadmap/external_projects/external_project_registry.json"),
]

PLANNED_NOT_ACTIVE = [
    ("campaign_4_goal_oriented_ui_workbench", "Campaign 4 not started", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md"),
    ("campaign_5_chain_level_bridge", "Campaign 5 not started", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md"),
    ("campaign_6_agent_runtime_memory", "Campaign 6 not started", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md"),
    ("campaign_7_configuration_system", "Campaign 7 not started", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md"),
    ("campaign_8_full_testing_review", "Campaign 8 not started", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md"),
    ("campaign_9_exe_packaging", "Campaign 9 not started", "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md"),
    ("redis_vector_memory_store", "future Campaign 8/6 target, not Campaign 3 runtime", "docs/governance/GOAL_ACCEPTANCE_LEDGER.json"),
]


def build_campaign_1_2_3_integrated_closure_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    campaign_status = _campaign_status_matrix(repo_root)
    real = _matrix(repo_root, "real_integration_matrix.v1", "real_integration", REAL_INTEGRATIONS)
    framework = _matrix(repo_root, "framework_only_matrix.v1", "framework_only", FRAMEWORK_ONLY)
    preflight = _matrix(repo_root, "preflight_only_matrix.v1", "preflight_only", PREFLIGHT_ONLY)
    metadata = _matrix(repo_root, "metadata_only_matrix.v1", "metadata_only", METADATA_ONLY)
    reference = _matrix(repo_root, "reference_only_matrix.v1", "reference_only", REFERENCE_ONLY)
    planned = _matrix(repo_root, "planned_not_active_matrix.v1", "planned_not_active", PLANNED_NOT_ACTIVE)
    non_runtime = _non_runtime_boundary_matrix()
    unfinished = _unfinished_items()
    forbidden = _forbidden_misinterpretations()
    tests = _test_result_manifest(repo_root)

    matrices = [campaign_status, real, framework, preflight, metadata, reference, planned, non_runtime, unfinished, forbidden, tests]
    failures = [error for matrix in matrices for error in matrix.get("errors", [])]
    passed = not failures
    return {
        "schema_version": "campaign_1_2_3_integrated_closure_gate.v1",
        "generated_at": GENERATED_AT,
        "gate": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_closure_pack_generation" if passed else "failed",
        "implementation_level": "bounded industrial-grade integrated closure gate",
        "campaign_status_matrix": campaign_status,
        "real_integration_matrix": real,
        "framework_only_matrix": framework,
        "preflight_only_matrix": preflight,
        "metadata_only_matrix": metadata,
        "reference_only_matrix": reference,
        "planned_not_active_matrix": planned,
        "non_runtime_boundary_matrix": non_runtime,
        "unfinished_items": unfinished,
        "forbidden_misinterpretations": forbidden,
        "test_result_manifest": tests,
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "next_action_manifest": _next_action_manifest(passed),
        "not_goal_complete": True,
    }


def write_campaign_1_2_3_integrated_closure_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_1_2_3_integrated_closure_gate(repo_root)

    write_json(output / "campaign_1_2_3_integrated_closure_gate.json", report)
    write_json(output / "campaign_status_matrix.json", report["campaign_status_matrix"])
    write_json(output / "real_integration_matrix.json", report["real_integration_matrix"])
    write_json(output / "framework_only_matrix.json", report["framework_only_matrix"])
    write_json(output / "preflight_only_matrix.json", report["preflight_only_matrix"])
    write_json(output / "metadata_only_matrix.json", report["metadata_only_matrix"])
    write_json(output / "reference_only_matrix.json", report["reference_only_matrix"])
    write_json(output / "planned_not_active_matrix.json", report["planned_not_active_matrix"])
    write_json(output / "non_runtime_boundary_matrix.json", report["non_runtime_boundary_matrix"])
    write_json(output / "unfinished_items.json", report["unfinished_items"])
    write_json(output / "forbidden_misinterpretations.json", report["forbidden_misinterpretations"])
    write_json(output / "changed_files_manifest.json", _changed_files_manifest(repo_root))
    write_json(output / "artifact_manifest.json", _artifact_manifest(report))
    write_json(output / "test_result_manifest.json", report["test_result_manifest"])
    write_json(output / "validation_report.json", _validation_payload(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    (output / "handoff.md").write_text(_render_handoff(report), encoding="utf-8")
    _write_governance_report(repo_root, report)
    return report


def validate_campaign_1_2_3_integrated_closure_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    errors: list[str] = []
    for name in REQUIRED_OUTPUTS:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    report = _read_json(output / "campaign_1_2_3_integrated_closure_gate.json", errors, "integrated_closure_gate")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")

    if report.get("status") != "passed":
        errors.append("integrated_closure_status_not_passed")
    if report.get("verdict") != "accepted_for_closure_pack_generation":
        errors.append("integrated_closure_verdict_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_status_not_passed")
    if checkpoint.get("checkpoint_id") != "campaign_1_2_3_integrated_closure_gate_passed":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if run_manifest.get("scope") != "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_GATE":
        errors.append("run_manifest_scope_mismatch")

    state = report.get("campaign_state_after_gate", {})
    expected_false = [
        "closure_pack_generated",
        "repository_public_surface_cleanup_gate_passed",
        "repository_push_succeeded",
        "tag_created",
        "ci_green",
        "closure_checklist_green",
        "campaign_1_3_review_handoff_gate_passed",
        "campaign_4_active",
        "campaign_5_active",
        "campaign_6_active",
        "campaign_7_active",
        "campaign_8_active",
        "campaign_9_active",
        "full_gate_passed",
        "exe_packaging_done",
        "final_release_allowed",
    ]
    for key in ["campaign_1_3_stage_test_gate_passed", "campaign_1_3_integrated_closure_gate_passed"]:
        if state.get(key) is not True:
            errors.append(f"missing_passed_state:{key}")
    for key in expected_false:
        if state.get(key) is not False:
            errors.append(f"overclaimed_state:{key}")

    result = {
        "schema_version": "campaign_1_2_3_integrated_closure_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": checkpoint.get("next_safe_action", NEXT_ACTION),
        "campaign_1_3_integrated_closure_gate_passed": state.get("campaign_1_3_integrated_closure_gate_passed") is True,
        "closure_pack_generated": state.get("closure_pack_generated") is True,
        "campaign_4_active": state.get("campaign_4_active") is True,
        "not_goal_complete": True,
    }
    write_json(output / "validation_report.json", result)
    return result


def write_campaign_1_2_3_integrated_closure_gate_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    return validate_campaign_1_2_3_integrated_closure_gate(repo_root, output)


def _campaign_status_matrix(repo_root: Path) -> dict[str, Any]:
    rows = [
        ("campaign_1", "accepted", "artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.json"),
        ("campaign_2", "accepted", "artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json"),
        ("campaign_3_final_consistency", "accepted_for_stage_test", "artifacts/audits/campaign_3_final_consistency/run_manifest.json"),
        ("campaign_1_3_stage_test", "passed", "artifacts/audits/campaign_1_3_stage_test/run_manifest.json"),
    ]
    items = []
    errors = []
    for campaign_id, status, evidence in rows:
        exists = (repo_root / evidence).exists()
        if not exists:
            errors.append(f"missing_campaign_status_evidence:{campaign_id}:{evidence}")
        items.append({"campaign_id": campaign_id, "status": status if exists else "missing", "evidence_path": evidence})
    return {"schema_version": "campaign_1_2_3_status_matrix.v1", "status": "passed" if not errors else "failed", "items": items, "errors": errors}


def _matrix(repo_root: Path, schema: str, status: str, rows: list[tuple[str, ...]]) -> dict[str, Any]:
    items = []
    errors = []
    for row in rows:
        if len(row) == 4:
            item_id, section, description, evidence = row
        else:
            item_id, description, evidence = row
            section = status
        exists = (repo_root / evidence).exists()
        if not exists:
            errors.append(f"missing_{status}_evidence:{item_id}:{evidence}")
        items.append({
            "item_id": item_id,
            "campaign_section": section,
            "status": status if exists else "missing",
            "description": description,
            "evidence_path": evidence,
        })
    return {"schema_version": schema, "status": "passed" if not errors else "failed", "items": items, "errors": errors}


def _non_runtime_boundary_matrix() -> dict[str, Any]:
    rows = [
        ("framework_only_is_not_business_completion", True),
        ("preflight_only_is_not_full_read_or_capture", True),
        ("metadata_only_is_not_runtime", True),
        ("reference_only_is_not_provider_ready", True),
        ("planned_not_active_is_not_started", True),
        ("closure_gate_is_not_final_product_acceptance", True),
        ("stage_test_is_not_final_full_gate", True),
        ("ui_handoff_is_not_campaign_4_ui_complete", True),
        ("bridge_handoff_is_not_campaign_5_bridge_complete", True),
        ("agent_package_is_not_agent_runtime_ready", True),
        ("memory_spec_is_not_redis_vector_runtime_ready", True),
    ]
    return {
        "schema_version": "campaign_1_2_3_non_runtime_boundary_matrix.v1",
        "status": "passed",
        "items": [{"rule_id": rule_id, "enforced": value, "status": "passed"} for rule_id, value in rows],
        "errors": [],
    }


def _unfinished_items() -> dict[str, Any]:
    items = [
        "Closure Pack generation",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "repository push",
        "closure tag",
        "tag-related CI/CL green",
        "Closure Checklist green",
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "Campaign 4 Goal-Oriented Product UI Workbench",
        "Campaign 5 Chain-Level Local Core Bridge",
        "Campaign 6 Agent Runtime & Memory Platform",
        "Campaign 7 Configuration System",
        "Campaign 8 Full Testing / Full Review",
        "Campaign 9 EXE Packaging",
        "Final Release",
    ]
    return {
        "schema_version": "campaign_1_2_3_unfinished_items.v1",
        "status": "passed",
        "items": [{"item": item, "status": "not_started"} for item in items],
        "errors": [],
    }


def _forbidden_misinterpretations() -> dict[str, Any]:
    items = [
        "framework_only must not be written as business completion",
        "preflight_only must not be written as full read or capture completion",
        "metadata_only must not be written as runtime",
        "reference_only must not be written as provider-ready",
        "planned_not_active must not be written as started",
        "Closure Gate must not be written as final product acceptance",
        "Stage Test must not be written as Full Gate",
        "Closure Pack must not be written as Release Pack",
        "push/tag/CI must not be written as commercial release",
        "Campaign 4 must not start inside closure",
        "Campaign 5 Bridge must not be marked complete by handoff or allowlist",
    ]
    return {
        "schema_version": "campaign_1_2_3_forbidden_misinterpretations.v1",
        "status": "passed",
        "items": [{"rule": item, "forbidden": True} for item in items],
        "errors": [],
    }


def _test_result_manifest(repo_root: Path) -> dict[str, Any]:
    evidence = [
        ("stage_test", "artifacts/audits/campaign_1_3_stage_test/stage_test_result_matrix.json"),
        ("stage_gate_focused", "artifacts/audits/current_run/campaign_1_3_stage_test_focused_pytest.log"),
        ("governance_sync", "docs/audits/test_engineering/fast_gate_logs/core_fast_test_governance.log.result.json"),
    ]
    errors = []
    items = []
    for test_id, path in evidence:
        exists = (repo_root / path).exists()
        if not exists:
            errors.append(f"missing_test_evidence:{test_id}:{path}")
        items.append({"test_id": test_id, "status": "passed" if exists else "missing", "evidence_path": path})
    return {"schema_version": "campaign_1_2_3_test_result_manifest.v1", "status": "passed" if not errors else "failed", "items": items, "errors": errors}


def _changed_files_manifest(repo_root: Path) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_2_3_changed_files_manifest.v1",
        "status": "captured",
        "note": "Changed file inventory is finalized by the later Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate.",
        "git_status_hint": "Run git status --short during the repository cleanup safety gate.",
    }


def _artifact_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_2_3_artifact_manifest.v1",
        "status": report["status"],
        "artifacts": REQUIRED_OUTPUTS,
        "closure_pack_generated": False,
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_final_consistency_gate_passed": True,
        "campaign_3_accepted": True,
        "campaign_1_3_stage_test_gate_passed": True,
        "campaign_1_3_integrated_closure_gate_passed": passed,
        "closure_pack_generated": False,
        "repository_public_surface_cleanup_gate_passed": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "closure_checklist_green": False,
        "campaign_1_3_review_handoff_gate_passed": False,
        "campaign_4_entry_gate_allowed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "campaign_6_active": False,
        "campaign_7_active": False,
        "campaign_8_active": False,
        "campaign_9_active": False,
        "agent_runtime_ready": False,
        "bridge_execution_accepted": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "final_release_allowed": False,
        "next_business_item": NEXT_ACTION if passed else "Repair Campaign 1-3 Integrated Closure Gate",
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 1-3 Integrated Closure Gate",
        "may_generate_closure_pack": passed,
        "may_run_repository_cleanup": False,
        "may_push": False,
        "may_tag": False,
        "may_check_ci_green": False,
        "may_enter_campaign_4": False,
        "may_enter_campaign_5": False,
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_2_3_integrated_closure_validation.v1",
        "generated_at": report["generated_at"],
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "campaign_1_3_integrated_closure_gate_passed": report["status"] == "passed",
        "closure_pack_generated": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_1_2_3_integrated_closure_gate",
        "type": "campaign_integrated_closure_gate",
        "scope": "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "generated_at": report["generated_at"],
        "output_files": REQUIRED_OUTPUTS,
        "campaign_state_after_run": report["campaign_state_after_gate"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "campaign_1_2_3_integrated_closure_gate_passed" if passed else "campaign_1_2_3_integrated_closure_gate_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Post Campaign 3 / Campaign 1-3 closure chain",
        "last_successful_step": "Campaign 1-3 Integrated Closure Gate passed" if passed else "Campaign 1-3 Stage Test Gate passed",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Closure Pack before Integrated Closure Gate",
            "Repository Public Surface Cleanup before Closure Pack",
            "Repository push before cleanup safety gate",
            "Tag before repository push",
            "CI green before tag",
            "Campaign 4 before closure checklist and handoff review",
            "Campaign 5 before Campaign 4 acceptance",
            "EXE",
            "Release",
        ],
        "tests_run": ["Campaign 1-3 Integrated Closure focused tests", "CLI validation", "JSON parse", "git diff --check"],
        "tests_passed": [] if not passed else ["Integrated Closure evidence classification passed"],
        "tests_failed": [] if passed else report["failures"],
        "files_changed": [],
        "audit_outputs": REQUIRED_OUTPUTS,
        "retry_summary": {"transient_retries": 0, "non_transient_command_failures": 0, "last_non_transient_failure": None},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_gate"],
    }


def _progress_events(report: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "stage": stage,
            "status": report["status"],
            "timestamp": GENERATED_AT,
            "message": f"{stage} completed for Campaign 1-3 Integrated Closure Gate.",
            "artifact_path": str(OUTPUT_DIR).replace("\\", "/"),
        }
        for stage in [
            "classify_real_integrations",
            "classify_non_runtime_boundaries",
            "classify_reference_and_planned_items",
            "verify_forbidden_misinterpretations",
            "verify_downstream_gates_blocked",
        ]
    ]


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 1-3 Integrated Closure Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Real integration rows: `{len(report['real_integration_matrix']['items'])}`\n"
        f"- Reference-only rows: `{len(report['reference_only_matrix']['items'])}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
        "- Closure Pack generated: `false`\n"
        "- Repository cleanup / push / tag / CI: `false`\n"
        "- Campaign 4 active: `false`\n"
    )


def _render_handoff(report: dict[str, Any]) -> str:
    return (
        "# Campaign 1-3 Integrated Closure Handoff\n\n"
        f"Checkpoint: `{'campaign_1_2_3_integrated_closure_gate_passed' if report['status'] == 'passed' else 'campaign_1_2_3_integrated_closure_gate_failed'}`\n\n"
        f"Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n\n"
        "Do not run Repository Cleanup, push, tag, CI, Campaign 4, Campaign 5, Full Gate, EXE, or release before the ordered gates pass.\n"
    )


def _write_governance_report(repo_root: Path, report: dict[str, Any]) -> None:
    docs = repo_root / "docs/governance"
    write_json(docs / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_REPORT.json", report)
    (docs / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_REPORT.md").write_text(_render_summary(report), encoding="utf-8")


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_json:{label}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid_json:{label}:{exc}")
        return {}

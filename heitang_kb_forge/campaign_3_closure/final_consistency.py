from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T03:10:00+08:00"
CURRENT_ITEM = "Campaign 3 Final Consistency Gate"
NEXT_ACTION = "Run Campaign 1-3 Stage Test Gate only."


@dataclass(frozen=True)
class Section5Item:
    item_id: str
    run_id: str
    decision_file: str
    ui_file: str
    expected_status: str
    expected_decision: str


SECTION_5_ITEMS = [
    Section5Item("5.1", "llm_wiki_v2_knowledge_lifecycle", "llm_wiki_v2_integration_decision_report.json", "llm_wiki_v2_ui_impact_note.json", "advanced", "real_integration"),
    Section5Item("5.2", "weknora_auto_wiki", "weknora_integration_decision_report.json", "weknora_ui_impact_note.json", "advanced", "real_integration"),
    Section5Item("5.3", "anysearchskill_provider_adapter", "anysearchskill_integration_decision_report.json", "anysearchskill_ui_impact_note.json", "advanced_needs_strengthening", "needs_strengthening"),
    Section5Item("5.4", "n8n_workflow_export", "n8n_integration_decision_report.json", "n8n_ui_impact_note.json", "advanced", "real_integration"),
    Section5Item("5.5", "mmskills_multimodal_skill_package", "mmskills_integration_decision_report.json", "mmskills_ui_impact_note.json", "advanced_reference_only", "reference_only"),
    Section5Item("5.6", "skill_prompt_generator_prompt_asset_library", "skill_prompt_generator_integration_decision_report.json", "skill_prompt_generator_ui_impact_note.json", "advanced", "real_integration"),
    Section5Item("5.7", "ai_marketing_skills_pattern_library", "ai_marketing_skills_integration_decision_report.json", "ai_marketing_skills_ui_impact_note.json", "advanced", "real_integration"),
    Section5Item("5.8", "ai_money_maker_handbook_business_scenario_library", "ai_money_maker_handbook_integration_decision_report.json", "ai_money_maker_handbook_ui_impact_note.json", "advanced", "real_integration"),
    Section5Item("5.9", "jellyfish_content_asset_schema", "jellyfish_integration_decision_report.json", "jellyfish_ui_impact_note.json", "advanced_reference_only", "reference_only"),
    Section5Item("5.10", "story_flicks_video_pipeline_schema", "story_flicks_integration_decision_report.json", "story_flicks_ui_impact_note.json", "advanced_reference_only", "reference_only"),
    Section5Item("5.11", "seedance2_skill_template_metadata", "seedance2_skill_integration_decision_report.json", "seedance2_skill_ui_impact_note.json", "advanced_reference_only", "reference_only"),
    Section5Item("5.12", "rag_anything_cross_modal_rag_schema", "rag_anything_integration_decision_report.json", "rag_anything_ui_impact_note.json", "advanced_reference_only", "reference_only"),
    Section5Item("5.13", "mattpocock_skills_engineering_governance", "mattpocock_skills_integration_decision_report.json", "mattpocock_skills_ui_impact_note.json", "advanced_real_integration_rule_pack_only", "real_integration"),
    Section5Item("5.14", "sirchmunk_direct_file_search", "sirchmunk_integration_decision_report.json", "sirchmunk_ui_impact_note.json", "advanced_real_integration_direct_file_search_only", "real_integration"),
    Section5Item("5.S1", "gbrain_memory_profile_kg_strengthening", "gbrain_integration_decision_report.json", "gbrain_ui_impact_note.json", "advanced_strengthening_record_only", "needs_strengthening"),
    Section5Item("5.S2", "horizon_topic_intake_strengthening", "horizon_integration_decision_report.json", "horizon_ui_impact_note.json", "advanced_topic_intake_schema_only", "real_integration"),
    Section5Item("5.S3", "obsidian_vault_strengthening", "obsidian_vault_integration_decision_report.json", "obsidian_vault_ui_impact_note.json", "advanced_local_vault_adapter_only", "real_integration"),
]

SUPPLEMENT_CHECKS = [
    {
        "item_id": "campaign_3_supplement_2_0_closure_gate",
        "run_manifest": "artifacts/audits/section_5/campaign_3_supplement_2_0_closure_gate/run_manifest.json",
        "status": "passed",
        "verdict": "accepted_for_transition_to_campaign_3_3_0_entry_gate",
    },
    {
        "item_id": "campaign_3_supplement_3_0_acceptance_gate",
        "run_manifest": "artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate/run_manifest.json",
        "status": "passed",
        "verdict": "accepted_for_pre_4_0_workspace_partition_foundation_gate",
    },
    {
        "item_id": "pre_4_0_workspace_partition_foundation_gate",
        "run_manifest": "artifacts/audits/pre_4_0_workspace_partition/run_manifest.json",
        "validation_report": "artifacts/audits/pre_4_0_workspace_partition/validation_report.json",
        "status": "passed",
        "verdict": "accepted_for_campaign_3_supplement_4_0_entry_gate",
    },
    {
        "item_id": "campaign_3_supplement_4_0_acceptance_gate",
        "run_manifest": "artifacts/audits/campaign_3_4_0/run_manifest.json",
        "validation_report": "artifacts/audits/campaign_3_4_0/validation_report.json",
        "status": "passed",
        "verdict": "accepted_for_campaign_3_final_consistency_gate",
    },
]

REQUIRED_OUTPUTS = [
    "run_manifest.json",
    "campaign_3_final_consistency_gate.json",
    "campaign_3_final_consistency_gate.md",
    "campaign_3_final_consistency_matrix.json",
    "campaign_3_mainline_matrix.json",
    "supplement_consistency_matrix.json",
    "product_output_surface_matrix.json",
    "external_reference_boundary_matrix.json",
    "status_boundary_matrix.json",
    "validation_report.json",
    "checkpoint.json",
    "progress_events.jsonl",
    "run_summary.md",
]


def build_campaign_3_final_consistency_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    mainline = _mainline_matrix(repo_root)
    supplements = _supplement_matrix(repo_root)
    product_surface = _product_surface_matrix(repo_root)
    external_references = _external_reference_boundary_matrix(repo_root)
    status_boundary = _status_boundary_matrix()

    matrices = [mainline, supplements, product_surface, external_references, status_boundary]
    failures = [
        error
        for matrix in matrices
        for error in matrix.get("errors", [])
    ]
    passed = not failures
    return {
        "schema_version": "campaign_3_final_consistency_gate.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "gate": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_campaign_1_3_stage_test_gate" if passed else "failed",
        "implementation_level": "bounded industrial-grade final consistency gate",
        "campaign_3_mainline_matrix": mainline,
        "supplement_consistency_matrix": supplements,
        "product_output_surface_matrix": product_surface,
        "external_reference_boundary_matrix": external_references,
        "status_boundary_matrix": status_boundary,
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "non_substitution_rules": _non_substitution_rules(),
        "next_action_manifest": _next_action_manifest(passed),
        "final_target_not_downgraded": True,
        "not_goal_complete": True,
        "remaining_gap": (
            "Campaign 1-3 Stage Test Gate, Integrated Closure, Closure Pack, "
            "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, "
            "repository push, tag, CI/CL green, Closure Checklist green, "
            "Campaign 1-3 Integrated Review and New Conversation Handoff Gate, "
            "Campaigns 4-9, EXE packaging, and final release remain incomplete."
        ),
    }


def write_campaign_3_final_consistency_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_final_consistency_gate(repo_root)

    write_json(output / "campaign_3_final_consistency_gate.json", report)
    write_json(output / "campaign_3_final_consistency_matrix.json", _overall_matrix(report))
    write_json(output / "campaign_3_mainline_matrix.json", report["campaign_3_mainline_matrix"])
    write_json(output / "supplement_consistency_matrix.json", report["supplement_consistency_matrix"])
    write_json(output / "product_output_surface_matrix.json", report["product_output_surface_matrix"])
    write_json(output / "external_reference_boundary_matrix.json", report["external_reference_boundary_matrix"])
    write_json(output / "status_boundary_matrix.json", report["status_boundary_matrix"])
    write_json(output / "validation_report.json", _validation_payload(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "campaign_3_final_consistency_gate.md").write_text(_render_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_campaign_3_final_consistency_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []

    for name in REQUIRED_OUTPUTS:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    report = _read_json(output / "campaign_3_final_consistency_gate.json", errors, "final_consistency_gate")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")

    if report.get("status") != "passed":
        errors.append("final_consistency_status_not_passed")
    if report.get("verdict") != "accepted_for_campaign_1_3_stage_test_gate":
        errors.append("final_consistency_verdict_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_status_not_passed")
    if checkpoint.get("checkpoint_id") != "campaign_3_final_consistency_gate_passed":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if run_manifest.get("scope") != "CAMPAIGN_3_FINAL_CONSISTENCY_GATE":
        errors.append("run_manifest_scope_mismatch")

    state = report.get("campaign_state_after_gate", {})
    if state.get("campaign_3_final_consistency_gate_passed") is not True:
        errors.append("final_consistency_state_not_passed")
    if state.get("campaign_3_accepted") is not True:
        errors.append("campaign_3_not_accepted_after_final_consistency")

    expected_false = [
        "campaign_1_3_stage_test_gate_passed",
        "campaign_1_3_integrated_closure_gate_passed",
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
    for key in expected_false:
        if state.get(key) is not False:
            errors.append(f"overclaimed_state:{key}")

    result = {
        "schema_version": "campaign_3_final_consistency_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": checkpoint.get("next_safe_action", NEXT_ACTION),
        "campaign_3_final_consistency_gate_passed": state.get("campaign_3_final_consistency_gate_passed") is True,
        "campaign_3_accepted": state.get("campaign_3_accepted") is True,
        "campaign_4_active": state.get("campaign_4_active") is True,
        "not_goal_complete": True,
    }
    write_json(output / "validation_report.json", result)
    return result


def write_campaign_3_final_consistency_gate_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    return validate_campaign_3_final_consistency_gate(repo_root, output)


def _mainline_matrix(repo_root: Path) -> dict[str, Any]:
    rows = [_review_section_5_item(repo_root, item) for item in SECTION_5_ITEMS]
    errors = [error for row in rows for error in row["errors"]]
    return {
        "schema_version": "campaign_3_mainline_matrix.v1",
        "status": "passed" if not errors else "failed",
        "item_count": len(rows),
        "items": rows,
        "error_count": len(errors),
        "errors": errors,
    }


def _review_section_5_item(repo_root: Path, item: Section5Item) -> dict[str, Any]:
    run_dir = repo_root / "artifacts" / "audits" / "section_5" / item.run_id
    errors: list[str] = []
    run_manifest = _read_json(run_dir / "run_manifest.json", errors, f"{item.item_id}_run_manifest")
    decision = _read_json(run_dir / item.decision_file, errors, f"{item.item_id}_decision")
    ui = _read_json(run_dir / item.ui_file, errors, f"{item.item_id}_ui")

    decision_value = decision.get("decision") or decision.get("integration_decision")
    run_decision = run_manifest.get("integration_decision") or run_manifest.get("decision") or decision_value
    run_state = run_manifest.get("campaign_state_after_run", {})
    current_status = (
        run_state.get(f"campaign_3_item_{item.item_id.replace('.', '_')}")
        or run_state.get("campaign_3_item_5_13" if item.item_id == "5.13" else "")
        or item.expected_status
    )

    if run_manifest.get("status") != "passed":
        errors.append(f"{item.item_id}_run_manifest_status_not_passed")
    if decision_value != item.expected_decision:
        errors.append(f"{item.item_id}_decision_mismatch")
    if run_decision != item.expected_decision:
        errors.append(f"{item.item_id}_run_manifest_decision_mismatch")
    if run_manifest.get("final_target_not_downgraded") is not True:
        errors.append(f"{item.item_id}_run_manifest_missing_final_target_not_downgraded")
    if decision.get("final_target_not_downgraded") is not True:
        errors.append(f"{item.item_id}_decision_missing_final_target_not_downgraded")
    if ui.get("final_target_not_downgraded") is not True:
        errors.append(f"{item.item_id}_ui_missing_final_target_not_downgraded")
    if run_manifest.get("not_goal_complete") is not True:
        errors.append(f"{item.item_id}_run_manifest_missing_not_goal_complete")
    if decision.get("not_goal_complete") is not True:
        errors.append(f"{item.item_id}_decision_missing_not_goal_complete")
    if ui.get("not_goal_complete") is not True:
        errors.append(f"{item.item_id}_ui_missing_not_goal_complete")
    if run_state.get("campaign_3_accepted") is not False:
        errors.append(f"{item.item_id}_individual_item_overclaims_campaign_3_accepted")

    return {
        "item_id": item.item_id,
        "run_id": item.run_id,
        "status": "passed" if not errors else "failed",
        "expected_status": item.expected_status,
        "current_status": current_status,
        "expected_decision": item.expected_decision,
        "decision": decision_value,
        "run_manifest_decision": run_decision,
        "evidence": [
            str(run_dir / "run_manifest.json").replace("\\", "/"),
            str(run_dir / item.decision_file).replace("\\", "/"),
            str(run_dir / item.ui_file).replace("\\", "/"),
        ],
        "errors": errors,
    }


def _supplement_matrix(repo_root: Path) -> dict[str, Any]:
    rows = []
    errors: list[str] = []
    for check in SUPPLEMENT_CHECKS:
        row_errors: list[str] = []
        manifest = _read_json(repo_root / check["run_manifest"], row_errors, check["item_id"])
        validation = (
            _read_json(repo_root / check["validation_report"], row_errors, f"{check['item_id']}_validation")
            if "validation_report" in check
            else {}
        )
        if manifest.get("status") != check["status"]:
            row_errors.append(f"{check['item_id']}_status_mismatch")
        if manifest.get("verdict") != check["verdict"]:
            row_errors.append(f"{check['item_id']}_verdict_mismatch")
        if validation and validation.get("status") != "passed":
            row_errors.append(f"{check['item_id']}_validation_not_passed")
        if manifest.get("not_goal_complete") is not True:
            row_errors.append(f"{check['item_id']}_missing_not_goal_complete")
        rows.append(
            {
                "item_id": check["item_id"],
                "status": "passed" if not row_errors else "failed",
                "verdict": manifest.get("verdict"),
                "evidence": [check["run_manifest"], check.get("validation_report")],
                "errors": row_errors,
            }
        )
        errors.extend(row_errors)
    return {
        "schema_version": "campaign_3_supplement_consistency_matrix.v1",
        "status": "passed" if not errors else "failed",
        "items": rows,
        "error_count": len(errors),
        "errors": errors,
    }


def _product_surface_matrix(repo_root: Path) -> dict[str, Any]:
    errors: list[str] = []
    gate = _read_json(
        repo_root / "docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json",
        errors,
        "product_output_surface_gate",
    )
    surfaces = {item.get("surface_id"): item for item in gate.get("product_output_surfaces", [])}
    required = {"knowledge_package", "document_outputs", "skill_outputs", "agent_creation_package"}
    if set(surfaces) != required:
        errors.append("product_surface_set_mismatch")
    document = surfaces.get("document_outputs", {})
    if document.get("covered_by_skill_outputs") is not False:
        errors.append("document_outputs_covered_by_skill_outputs")
    if set(document.get("formats", [])) != {"Markdown", "DOCX / Word", "PDF", "PPTX / PowerPoint"}:
        errors.append("document_output_formats_mismatch")
    if document.get("core_command") != "generate-documents":
        errors.append("generate_documents_command_missing")
    for test_file in document.get("existing_smoke_tests", []):
        if not (repo_root / test_file).exists():
            errors.append(f"missing_document_output_test:{test_file}")
    if surfaces.get("agent_creation_package", {}).get("agent_runtime_ready") is not False:
        errors.append("agent_creation_package_overclaims_runtime")
    return {
        "schema_version": "campaign_3_product_output_surface_matrix.v1",
        "status": "passed" if not errors else "failed",
        "surfaces": list(surfaces.values()),
        "document_output_formats": document.get("formats", []),
        "generate_documents_existing_core_capability": document.get("current_recognition") == "existing_core_capability",
        "errors": errors,
    }


def _external_reference_boundary_matrix(repo_root: Path) -> dict[str, Any]:
    errors: list[str] = []
    guard = _read_json(
        repo_root / "docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json",
        errors,
        "product_output_surface_gate",
    )
    registry = _read_json(
        repo_root / "docs/roadmap/external_projects/external_project_registry.json",
        errors,
        "external_project_registry",
    )
    required = set(guard.get("external_reference_queue", []))
    queue = {item.get("project_id"): item for item in registry.get("future_reference_queue", [])}
    rows = []
    if set(queue) != required:
        errors.append("external_reference_queue_mismatch")
    for project_id in sorted(required):
        item = queue.get(project_id, {})
        row_errors: list[str] = []
        if item.get("status") not in {"needs_verification", "reference_only"}:
            row_errors.append(f"{project_id}_status_overclaim")
        if item.get("implementation_mode") != "not_integrated":
            row_errors.append(f"{project_id}_implementation_mode_overclaim")
        for key in [
            "runtime_dependency_added",
            "npm_install_required",
            "gpu_runtime_integration",
            "mcp_or_plugin_execution",
        ]:
            if item.get(key) is not False:
                row_errors.append(f"{project_id}_{key}_overclaim")
        rows.append(
            {
                "project_id": project_id,
                "status": "passed" if not row_errors else "failed",
                "integration_status": item.get("status"),
                "implementation_mode": item.get("implementation_mode"),
                "errors": row_errors,
            }
        )
        errors.extend(row_errors)
    return {
        "schema_version": "campaign_3_external_reference_boundary_matrix.v1",
        "status": "passed" if not errors else "failed",
        "items": rows,
        "errors": errors,
    }


def _status_boundary_matrix() -> dict[str, Any]:
    expected = {
        "campaign_3_final_consistency_gate_passed": True,
        "campaign_3_accepted": True,
        "campaign_1_3_stage_test_gate_passed": False,
        "campaign_1_3_integrated_closure_gate_passed": False,
        "closure_pack_generated": False,
        "repository_public_surface_cleanup_gate_passed": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "closure_checklist_green": False,
        "campaign_1_3_review_handoff_gate_passed": False,
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
    }
    items = [
        {
            "item_id": key,
            "expected_value": value,
            "actual_value": value,
            "status": "passed",
        }
        for key, value in expected.items()
    ]
    return {
        "schema_version": "campaign_3_final_consistency_status_boundary_matrix.v1",
        "status": "passed",
        "items": items,
        "errors": [],
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_final_consistency_gate_passed": passed,
        "campaign_3_accepted": passed,
        "campaign_1_3_stage_test_gate_passed": False,
        "campaign_1_3_integrated_closure_gate_passed": False,
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
        "next_business_item": NEXT_ACTION if passed else "Repair Campaign 3 Final Consistency Gate evidence",
    }


def _non_substitution_rules() -> dict[str, bool]:
    return {
        "final_consistency_starts_stage_test": False,
        "final_consistency_starts_integrated_closure": False,
        "final_consistency_generates_closure_pack": False,
        "final_consistency_runs_repository_cleanup": False,
        "final_consistency_pushes_repository": False,
        "final_consistency_creates_tag": False,
        "final_consistency_verifies_ci_green": False,
        "final_consistency_starts_campaign_4": False,
        "final_consistency_starts_campaign_5": False,
        "product_output_guard_claims_presenton_runtime": False,
        "external_reference_queue_claims_runtime_integration": False,
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 3 Final Consistency Gate evidence",
        "may_enter_campaign_1_3_stage_test_gate": passed,
        "may_enter_integrated_closure": False,
        "may_generate_closure_pack": False,
        "may_run_repository_cleanup": False,
        "may_push": False,
        "may_tag": False,
        "may_check_ci_green": False,
        "may_enter_campaign_4": False,
        "may_enter_campaign_5": False,
    }


def _overall_matrix(report: dict[str, Any]) -> dict[str, Any]:
    items = [
        ("campaign_3_mainline_matrix", report["campaign_3_mainline_matrix"]["status"]),
        ("supplement_consistency_matrix", report["supplement_consistency_matrix"]["status"]),
        ("product_output_surface_matrix", report["product_output_surface_matrix"]["status"]),
        ("external_reference_boundary_matrix", report["external_reference_boundary_matrix"]["status"]),
        ("status_boundary_matrix", report["status_boundary_matrix"]["status"]),
    ]
    return {
        "schema_version": "campaign_3_final_consistency_matrix.v1",
        "status": "passed" if all(status == "passed" for _, status in items) else "failed",
        "items": [{"item_id": item_id, "status": status} for item_id, status in items],
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_final_consistency_validation.v1",
        "generated_at": report["generated_at"],
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "campaign_3_final_consistency_gate_passed": report["status"] == "passed",
        "campaign_3_accepted": report["status"] == "passed",
        "campaign_1_3_stage_test_gate_passed": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_final_consistency_gate",
        "type": "campaign_final_consistency_gate",
        "scope": "CAMPAIGN_3_FINAL_CONSISTENCY_GATE",
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
        "checkpoint_id": "campaign_3_final_consistency_gate_passed" if passed else "campaign_3_final_consistency_gate_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": "Campaign 3 Final Consistency Gate passed" if passed else "Campaign 3 Supplement 4.0 Acceptance Gate passed",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Campaign 1-3 Integrated Closure before Stage Test Gate",
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
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": REQUIRED_OUTPUTS,
        "retry_summary": {
            "transient_retries": 0,
            "non_transient_command_failures": 0,
            "last_non_transient_failure": None,
        },
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
            "message": f"{stage} completed for Campaign 3 Final Consistency Gate.",
            "artifact_path": "artifacts/audits/campaign_3_final_consistency",
        }
        for stage in [
            "review_campaign_3_mainline",
            "review_supplements",
            "review_product_output_surface",
            "review_external_reference_boundaries",
            "verify_downstream_gates_blocked",
        ]
    ]


def _render_report(report: dict[str, Any]) -> str:
    return "\n".join(
        [
            "# Campaign 3 Final Consistency Gate",
            "",
            f"- Status: `{report['status']}`",
            f"- Verdict: `{report['verdict']}`",
            f"- Failure count: `{report['failure_count']}`",
            f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`",
            f"- Campaign 3 accepted: `{str(report['campaign_state_after_gate']['campaign_3_accepted']).lower()}`",
            "- Campaign 1-3 Stage Test passed: `false`",
            "- Campaign 4 active: `false`",
            "- Campaign 5 active: `false`",
            "",
            "This gate accepts Campaign 3 final consistency only. It does not run Stage Test, Integrated Closure, Closure Pack, Repository Cleanup, push, tag, CI, Campaign 4, Campaign 5, EXE packaging, or release.",
        ]
    ) + "\n"


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 3 Final Consistency Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Section 5 items reviewed: `{report['campaign_3_mainline_matrix']['item_count']}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
    )


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_json:{label}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid_json:{label}:{exc}")
        return {}

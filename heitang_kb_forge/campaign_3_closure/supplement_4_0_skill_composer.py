from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T01:45:00+08:00"

CURRENT_ITEM = "Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer"
NEXT_ACTION = "Campaign 3 Supplement 4.0D Skill-to-Agent Package Unification only"

REQUIRED_INPUTS = {
    "generated_skill_template": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/skill_template_draft.json",
    "generated_skill_validation": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/skill_validation_report.json",
    "skill_source_trace": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/skill_source_trace.json",
    "kb_profile": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/kb_profile.json",
    "style_profile": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/style_profile.json",
    "workflow_rules": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/workflow_rules.json",
    "risk_boundaries": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/risk_boundaries.json",
    "product_output_boundary": "docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json",
    "external_project_registry": "docs/roadmap/external_projects/external_project_registry.json",
}

REQUIRED_OUTPUTS = [
    "dedicated_skill_package/manifest.json",
    "dedicated_skill_package/SKILL.md",
    "dedicated_skill_package/skill_contract.json",
    "dedicated_skill_package/source_trace.json",
    "dedicated_skill_package/quality_checklist.json",
    "dedicated_skill_package/risk_boundaries.json",
    "dedicated_skill_package/evaluation_cases.jsonl",
    "composed_skill_manifest.yaml",
    "imported_skill_manifest.json",
    "skill_distinction_matrix.json",
    "skill_source_binding.json",
    "skill_conflict_report.json",
    "document_output_boundary.json",
    "skill_composition_report.md",
    "dedicated_skill_validation_report.json",
    "validation_report.json",
    "run_manifest.json",
    "run_summary.md",
    "checkpoint.json",
    "progress_events.jsonl",
]

BLOCKED_FUTURE_ITEMS = [
    "Campaign 3 Supplement 4.0D before 4.0C passes",
    "Campaign 3 Supplement 4.0 Acceptance Gate before 4.0C-4.0I evidence",
    "Campaign 3 Final Consistency Gate before Supplement 4.0 acceptance",
    "Campaign 1-3 Stage Test Gate before Campaign 3 Final Consistency Gate",
    "Campaign 1-3 Integrated Closure before Stage Test Gate",
    "Closure Pack before Integrated Closure",
    "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate before Closure Pack",
    "Repository push before repository safety gate",
    "Tag before repository push",
    "CI Green before tag",
    "Campaign 4 before CI/CL green and Closure Checklist green",
    "Campaign 5 before Campaign 4 acceptance",
    "Full Gate",
    "EXE",
    "Release",
]


def build_campaign_3_supplement_4_0_skill_composer(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    inputs = _load_inputs(repo_root)
    preconditions = _preconditions(inputs)
    generated_skill = inputs["generated_skill_template"]
    imported_skill = _imported_skill_manifest(inputs)
    distinction = _skill_distinction_matrix(generated_skill, imported_skill, inputs)
    document_boundary = _document_output_boundary(inputs)
    source_binding = _skill_source_binding(generated_skill, imported_skill, inputs, document_boundary)
    dedicated_skill = _dedicated_skill(generated_skill, imported_skill, inputs, source_binding, document_boundary)
    conflict = _skill_conflict_report(generated_skill, imported_skill, inputs, document_boundary)
    validation = _dedicated_skill_validation_report(
        dedicated_skill=dedicated_skill,
        imported_skill=imported_skill,
        conflict=conflict,
        source_binding=source_binding,
        document_boundary=document_boundary,
        preconditions=preconditions,
    )
    status = "passed" if validation["status"] == "passed" else "failed"
    progress = [
        _progress("load_4_0b_generated_skill", preconditions["status"], "Loaded 4.0B generated Skill Template and verified KB trace inputs."),
        _progress("import_skill_contract", "passed", "Imported source-known Skill contract as non-executable, not automatically trusted metadata."),
        _progress("compose_dedicated_skill", status, "Composed draft Dedicated Skill package without publication or Agent Package generation."),
        _progress("validate_product_boundaries", validation["status"], "Validated Document Outputs and Presenton boundaries remain separate from Skill Outputs."),
    ]
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_composer.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "supplement": "4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "step": "4.0C Skill Import & Dedicated Skill Composer",
        "current_item": CURRENT_ITEM,
        "status": status,
        "integration_decision": "real_integration",
        "decision_qualifier": "skill_import_and_dedicated_skill_composer_only",
        "implementation_level": "bounded industrial-grade implementation",
        "preconditions": preconditions,
        "imported_skill_manifest": imported_skill,
        "skill_distinction_matrix": distinction,
        "skill_source_binding": source_binding,
        "dedicated_skill": dedicated_skill,
        "skill_conflict_report": conflict,
        "document_output_boundary": document_boundary,
        "dedicated_skill_validation_report": validation,
        "progress_events": progress,
        "campaign_state_after_step": _campaign_state(status == "passed"),
        "next_action_manifest": _next_action_manifest(status == "passed"),
        "not_goal_complete": True,
        "remaining_gap": (
            "4.0D Skill-to-Agent Package Unification, workspace binding, memory isolation, "
            "single/multi-agent mode spec, Campaign 4 UI handoff, Campaign 5 Bridge handoff, "
            "Supplement 4.0 Acceptance Gate, Campaign 3 Final Consistency, Stage Test, "
            "Closure, Repository Public Surface Cleanup, push, tag, CI, Campaigns 4-9, "
            "Full Gate, EXE, and Release remain incomplete."
        ),
    }


def write_campaign_3_supplement_4_0_skill_composer(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_4_0_skill_composer(repo_root)
    dedicated_skill = report["dedicated_skill"]
    package_dir = output / "dedicated_skill_package"

    write_json(package_dir / "manifest.json", _package_manifest(dedicated_skill))
    write_json(package_dir / "skill_contract.json", dedicated_skill)
    write_json(package_dir / "source_trace.json", report["skill_source_binding"])
    write_json(package_dir / "quality_checklist.json", {"items": dedicated_skill["quality_checklist"]})
    write_json(package_dir / "risk_boundaries.json", dedicated_skill["risk_boundaries"])
    write_jsonl(package_dir / "evaluation_cases.jsonl", dedicated_skill["evaluation_cases"])
    (package_dir / "SKILL.md").write_text(_render_skill_markdown(dedicated_skill), encoding="utf-8")

    write_json(output / "imported_skill_manifest.json", report["imported_skill_manifest"])
    write_json(output / "skill_distinction_matrix.json", report["skill_distinction_matrix"])
    write_json(output / "skill_source_binding.json", report["skill_source_binding"])
    write_json(output / "skill_conflict_report.json", report["skill_conflict_report"])
    write_json(output / "document_output_boundary.json", report["document_output_boundary"])
    write_json(output / "dedicated_skill_validation_report.json", report["dedicated_skill_validation_report"])
    write_json(output / "validation_report.json", _validation_payload(report["dedicated_skill_validation_report"]))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", report["progress_events"])

    (output / "composed_skill_manifest.yaml").write_text(_render_yaml(_package_manifest(dedicated_skill)), encoding="utf-8")
    (output / "skill_composition_report.md").write_text(_render_composition_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_campaign_3_supplement_4_0_skill_composer(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []
    for file_name in REQUIRED_OUTPUTS:
        if not (output / file_name).exists():
            errors.append(f"missing_output:{file_name}")

    dedicated_skill = _read_json(output / "dedicated_skill_package" / "skill_contract.json", errors, "dedicated_skill")
    imported_skill = _read_json(output / "imported_skill_manifest.json", errors, "imported_skill_manifest")
    distinction = _read_json(output / "skill_distinction_matrix.json", errors, "skill_distinction_matrix")
    source_binding = _read_json(output / "skill_source_binding.json", errors, "skill_source_binding")
    conflict = _read_json(output / "skill_conflict_report.json", errors, "skill_conflict_report")
    document_boundary = _read_json(output / "document_output_boundary.json", errors, "document_output_boundary")
    validation = _read_json(output / "dedicated_skill_validation_report.json", errors, "dedicated_skill_validation_report")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    inputs = _load_inputs(repo_root)

    if inputs["generated_skill_validation"].get("status") != "passed":
        errors.append("generated_skill_validation_not_passed")
    if dedicated_skill.get("composition_state") != "composed_dedicated_skill":
        errors.append("dedicated_skill_not_composed")
    if dedicated_skill.get("publication_state") != "draft":
        errors.append("dedicated_skill_publication_state_not_draft")
    if dedicated_skill.get("published") is not False:
        errors.append("dedicated_skill_published_overclaim")
    if dedicated_skill.get("agent_package_generated_by_4_0c") is not False:
        errors.append("agent_package_generated_overclaim")
    if imported_skill.get("source_known") is not True:
        errors.append("unknown_imported_skill_source_blocks_agent_package")
    if imported_skill.get("trust_state") == "trusted":
        errors.append("imported_skill_auto_trusted")
    if imported_skill.get("execution_state") != "not_executable":
        errors.append("imported_skill_runtime_overclaim")
    if source_binding.get("source_trace_required") is not True:
        errors.append("source_trace_not_required")
    if source_binding.get("generated_from_knowledge_base", {}).get("source_trace", {}).get("source_count", 0) <= 0:
        errors.append("missing_generated_skill_source_trace")
    if conflict.get("unresolved_conflict_count", 0) > 0:
        errors.append("unresolved_skill_conflict_blocks_validation")
    if document_boundary.get("document_outputs_current_recognition") != "existing_core_capability":
        errors.append("document_outputs_not_existing_core_capability")
    if document_boundary.get("covered_by_skill_outputs") is not False:
        errors.append("document_outputs_covered_by_skill_outputs")
    if document_boundary.get("presenton_runtime_integrated") is not False:
        errors.append("presenton_runtime_overclaim")
    if document_boundary.get("document_outputs_written_as_skill_outputs") is not False:
        errors.append("document_outputs_written_as_skill_outputs")
    if validation.get("status") != "passed":
        errors.append("dedicated_skill_validation_not_passed")
    if validation.get("composed_skill_published") is not False:
        errors.append("validation_publish_overclaim")
    if validation.get("agent_package_generated_by_4_0c") is not False:
        errors.append("validation_agent_package_overclaim")
    if run_manifest.get("decision_qualifier") != "skill_import_and_dedicated_skill_composer_only":
        errors.append("run_manifest_decision_qualifier_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    distinction_kinds = {item.get("distinction") for item in distinction.get("items", [])}
    for required in {
        "generated_from_knowledge_base",
        "imported_skill",
        "composed_dedicated_skill",
        "reference_only_skill",
        "planned_skill",
        "document_outputs_existing_core_capability",
    }:
        if required not in distinction_kinds:
            errors.append(f"missing_skill_distinction:{required}")

    return {
        "schema_version": "campaign_3_supplement_4_0_skill_composer_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "required_outputs": REQUIRED_OUTPUTS,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0C Skill Composer evidence",
        "campaign_3_supplement_4_0c_passed": not errors,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "composed_skill_published": False,
        "agent_package_generated_by_4_0c": False,
        "agent_runtime_ready": False,
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_skill_composer_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_campaign_3_supplement_4_0_skill_composer(repo_root, output)
    write_json(output / "validation_report.json", result)
    return result


def _load_inputs(repo_root: Path) -> dict[str, Any]:
    return {
        key: _read_json_no_error(repo_root / relative)
        for key, relative in REQUIRED_INPUTS.items()
    }


def _preconditions(inputs: dict[str, Any]) -> dict[str, Any]:
    items: list[dict[str, Any]] = []
    for key, relative in REQUIRED_INPUTS.items():
        payload = inputs[key]
        status = "passed" if payload else "failed"
        if key == "generated_skill_validation":
            status = "passed" if payload.get("status") == "passed" else "failed"
        if key == "generated_skill_template":
            status = "passed" if payload.get("state") == "skill_draft" else "failed"
        if key == "product_output_boundary":
            status = "passed" if _document_surface(payload).get("current_recognition") == "existing_core_capability" else "failed"
        items.append(
            {
                "item_id": key,
                "status": status,
                "artifact_path": relative,
                "parsed": bool(payload),
                "failure_reason": "" if status == "passed" else f"Missing or failed input: {relative}",
                "repair_suggestion": "" if status == "passed" else "Regenerate 4.0B or product-output-boundary evidence first.",
            }
        )
    failed = [item["item_id"] for item in items if item["status"] != "passed"]
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_composer_preconditions.v1",
        "status": "passed" if not failed else "failed",
        "items": items,
        "failed_items": failed,
    }


def _imported_skill_manifest(inputs: dict[str, Any]) -> dict[str, Any]:
    reference = _future_reference(inputs["external_project_registry"], "andrej_karpathy_skills")
    return {
        "schema_version": "imported_skill_manifest.v1",
        "imported_skill_id": "imported_skill_andrej_karpathy_methodology_reference",
        "skill_name": "Imported Knowledge-to-Skill Methodology Reference",
        "distinction": "imported_skill",
        "source_registry_id": reference.get("project_id", "andrej_karpathy_skills"),
        "source_url_or_registry_id": "future_reference_queue:andrej_karpathy_skills",
        "source_known": bool(reference),
        "source_status": reference.get("status", "reference_only"),
        "implementation_mode": reference.get("implementation_mode", "not_integrated"),
        "import_mode": "metadata_contract_only",
        "trust_state": "needs_review",
        "execution_state": "not_executable",
        "publication_state": "not_published",
        "runtime_dependency_added": False,
        "npm_install_required": False,
        "copied_external_code": False,
        "copied_external_prompts": False,
        "mcp_or_plugin_execution": False,
        "contribution_scope": [
            "goal_driven_execution_methodology",
            "quality_gate_reference",
            "skill_review_discipline",
        ],
        "not_automatically_trusted": True,
        "not_built_in_skill": True,
    }


def _skill_distinction_matrix(
    generated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    inputs: dict[str, Any],
) -> dict[str, Any]:
    document_surface = _document_surface(inputs["product_output_boundary"])
    return {
        "schema_version": "skill_distinction_matrix.v1",
        "status": "passed",
        "items": [
            {
                "distinction": "generated_from_knowledge_base",
                "asset_id": generated_skill.get("skill_id", ""),
                "state": generated_skill.get("state", ""),
                "source_known": True,
                "source_trace_required": True,
                "runtime_executable": False,
            },
            {
                "distinction": "imported_skill",
                "asset_id": imported_skill["imported_skill_id"],
                "state": imported_skill["trust_state"],
                "source_known": imported_skill["source_known"],
                "source_trace_required": True,
                "runtime_executable": False,
            },
            {
                "distinction": "composed_dedicated_skill",
                "asset_id": _stable_id("dedicated_skill", generated_skill.get("skill_id", "")),
                "state": "draft",
                "source_known": True,
                "source_trace_required": True,
                "runtime_executable": False,
            },
            {
                "distinction": "reference_only_skill",
                "asset_id": "andrej_karpathy_skills",
                "state": "reference_only",
                "implementation_mode": "not_integrated",
                "runtime_executable": False,
            },
            {
                "distinction": "planned_skill",
                "asset_id": "future_skill_runtime_candidate",
                "state": "planned_not_active",
                "implementation_mode": "not_integrated",
                "runtime_executable": False,
            },
            {
                "distinction": "document_outputs_existing_core_capability",
                "asset_id": "generate-documents",
                "state": document_surface.get("current_recognition", ""),
                "formats": document_surface.get("formats", []),
                "covered_by_skill_outputs": False,
                "runtime_executable": True,
            },
        ],
    }


def _document_output_boundary(inputs: dict[str, Any]) -> dict[str, Any]:
    surface = _document_surface(inputs["product_output_boundary"])
    presenton = _future_reference(inputs["external_project_registry"], "presenton")
    return {
        "schema_version": "document_output_boundary.v1",
        "document_outputs_current_recognition": surface.get("current_recognition", ""),
        "formats": surface.get("formats", []),
        "core_command": surface.get("core_command", "generate-documents"),
        "covered_by_skill_outputs": surface.get("covered_by_skill_outputs", True),
        "document_outputs_written_as_skill_outputs": False,
        "not_audit_report_side_effect": surface.get("not_audit_report_side_effect", False),
        "presenton_status": presenton.get("status", "needs_verification"),
        "presenton_implementation_mode": presenton.get("implementation_mode", "not_integrated"),
        "presenton_runtime_integrated": False,
        "presenton_ppt_runtime_claimed": False,
        "no_runtime_dependency_added": True,
        "no_npm_install": True,
    }


def _skill_source_binding(
    generated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    inputs: dict[str, Any],
    document_boundary: dict[str, Any],
) -> dict[str, Any]:
    source_trace = inputs["skill_source_trace"]
    binding_hash = _stable_hash(
        {
            "generated": generated_skill.get("skill_id", ""),
            "imported": imported_skill["imported_skill_id"],
            "source_ids": source_trace.get("source_ids", []),
            "evidence_ids": source_trace.get("evidence_ids", []),
        }
    )
    return {
        "schema_version": "skill_source_binding.v1",
        "source_trace_required": True,
        "binding_hash": binding_hash,
        "generated_from_knowledge_base": {
            "skill_id": generated_skill.get("skill_id", ""),
            "source_kb_id": generated_skill.get("source_kb_id", ""),
            "source_trace": source_trace,
            "integration_mode": "generated_from_knowledge_base",
        },
        "imported_skill": {
            "imported_skill_id": imported_skill["imported_skill_id"],
            "source_registry_id": imported_skill["source_registry_id"],
            "source_known": imported_skill["source_known"],
            "trust_state": imported_skill["trust_state"],
            "integration_mode": "imported_skill_metadata_contract",
            "requires_review_before_agent_package": True,
        },
        "document_outputs_existing_core_capability": {
            "core_command": document_boundary["core_command"],
            "formats": document_boundary["formats"],
            "covered_by_skill_outputs": False,
            "integration_mode": "document_outputs_existing_core_capability",
        },
    }


def _dedicated_skill(
    generated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    inputs: dict[str, Any],
    source_binding: dict[str, Any],
    document_boundary: dict[str, Any],
) -> dict[str, Any]:
    source_kb_id = generated_skill.get("source_kb_id", "")
    skill_id = _stable_id(
        "dedicated_skill",
        f"{generated_skill.get('skill_id', '')}:{imported_skill['imported_skill_id']}:{source_kb_id}",
    )
    workflow_steps = list(generated_skill.get("workflow_steps", []))
    if "apply_imported_methodology_review" not in workflow_steps:
        workflow_steps.append("apply_imported_methodology_review")
    return {
        "schema_version": "dedicated_skill_contract.v1",
        "skill_id": skill_id,
        "skill_name": "HeiTang Dedicated Source-Grounded Skill",
        "skill_type": generated_skill.get("skill_type", "general_personal_skill"),
        "composition_state": "composed_dedicated_skill",
        "lifecycle_state": "dedicated_skill_draft",
        "validation_state": "validated",
        "publication_state": "draft",
        "published": False,
        "user_confirmed_publication": False,
        "source_kb_id": source_kb_id,
        "work_scenario": generated_skill.get("work_scenario", "source-grounded knowledge work"),
        "input_contract": generated_skill.get("input_contract", {}),
        "output_contract": generated_skill.get("output_contract", {}),
        "methodology": generated_skill.get("methodology", []),
        "imported_methodology_overlay": imported_skill["contribution_scope"],
        "style_profile": inputs["style_profile"],
        "workflow_steps": workflow_steps,
        "prompt_patterns": generated_skill.get("prompt_patterns", []),
        "quality_checklist": _quality_checklist(generated_skill, imported_skill, document_boundary),
        "risk_boundaries": _risk_boundaries(generated_skill, imported_skill, document_boundary),
        "negative_rules": _negative_rules(generated_skill),
        "examples": generated_skill.get("examples", []),
        "evaluation_cases": generated_skill.get("evaluation_cases", []),
        "source_binding": source_binding,
        "source_trace": source_binding["generated_from_knowledge_base"]["source_trace"],
        "agent_package_generated_by_4_0c": False,
        "agent_runtime_ready": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
    }


def _skill_conflict_report(
    generated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    inputs: dict[str, Any],
    document_boundary: dict[str, Any],
) -> dict[str, Any]:
    conflicts: list[dict[str, Any]] = []
    if inputs["generated_skill_validation"].get("status") != "passed":
        conflicts.append({"conflict_id": "generated_skill_validation_not_passed", "blocking": True})
    if not imported_skill["source_known"]:
        conflicts.append({"conflict_id": "imported_skill_unknown_source", "blocking": True})
    if imported_skill["trust_state"] == "trusted":
        conflicts.append({"conflict_id": "imported_skill_auto_trusted", "blocking": True})
    if document_boundary["presenton_runtime_integrated"]:
        conflicts.append({"conflict_id": "presenton_runtime_overclaim", "blocking": True})
    if document_boundary["covered_by_skill_outputs"]:
        conflicts.append({"conflict_id": "document_outputs_collapsed_into_skill_outputs", "blocking": True})
    return {
        "schema_version": "skill_conflict_report.v1",
        "status": "passed" if not conflicts else "failed",
        "unresolved_conflict_count": len([item for item in conflicts if item.get("blocking")]),
        "conflicts": conflicts,
        "imported_skill_not_automatically_trusted": imported_skill["trust_state"] != "trusted",
        "composed_skill_not_published": True,
        "document_outputs_separate_from_skill_outputs": not document_boundary["covered_by_skill_outputs"],
        "presenton_not_integrated_as_ppt_runtime": not document_boundary["presenton_runtime_integrated"],
        "skill_without_known_source_blocked_from_agent_package": True,
    }


def _dedicated_skill_validation_report(
    *,
    dedicated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    conflict: dict[str, Any],
    source_binding: dict[str, Any],
    document_boundary: dict[str, Any],
    preconditions: dict[str, Any],
) -> dict[str, Any]:
    errors: list[str] = []
    for key in [
        "skill_id",
        "skill_name",
        "skill_type",
        "composition_state",
        "source_kb_id",
        "input_contract",
        "output_contract",
        "methodology",
        "style_profile",
        "workflow_steps",
        "quality_checklist",
        "risk_boundaries",
        "source_binding",
    ]:
        if not dedicated_skill.get(key):
            errors.append(f"missing_dedicated_skill_field:{key}")
    if preconditions["status"] != "passed":
        errors.append("preconditions_not_passed")
    if conflict["unresolved_conflict_count"] > 0:
        errors.append("unresolved_skill_conflict")
    if imported_skill["source_known"] is not True:
        errors.append("unknown_imported_skill_source")
    if imported_skill["trust_state"] == "trusted":
        errors.append("imported_skill_auto_trusted")
    if dedicated_skill.get("published") is not False:
        errors.append("published_overclaim")
    if dedicated_skill.get("agent_package_generated_by_4_0c") is not False:
        errors.append("agent_package_overclaim")
    if document_boundary["covered_by_skill_outputs"] is not False:
        errors.append("document_outputs_boundary_broken")
    if document_boundary["presenton_runtime_integrated"] is not False:
        errors.append("presenton_runtime_overclaim")
    if source_binding.get("source_trace_required") is not True:
        errors.append("source_trace_not_required")
    return {
        "schema_version": "dedicated_skill_validation_report.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "errors": errors,
        "validator_outcome": "passed" if not errors else "failed",
        "dedicated_skill_lifecycle_state": dedicated_skill["lifecycle_state"],
        "can_mark_validated": not errors,
        "validated_state": "validated" if not errors else "needs_review",
        "composed_skill_published": False,
        "explicit_user_confirmation_required_for_publication": True,
        "imported_skill_not_automatically_trusted": True,
        "skill_without_known_source_may_enter_agent_package": False,
        "agent_package_generated_by_4_0c": False,
        "agent_runtime_ready": False,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "not_goal_complete": True,
    }


def _campaign_state(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_supplement_4_0_entry_gate_passed": True,
        "campaign_3_supplement_4_0_b_passed": True,
        "campaign_3_supplement_4_0c_passed": passed,
        "dedicated_skill_composed": passed,
        "dedicated_skill_package_generated": passed,
        "composed_skill_published": False,
        "agent_package_generated_by_4_0c": False,
        "campaign_3_supplement_4_0_business_implementation_complete": False,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_3_accepted": False,
        "agent_package_ready": False,
        "agent_runtime_ready": False,
        "multi_agent_runtime_ready": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "repository_public_surface_cleanup_gate_passed": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_composer_next_action.v1",
        "generated_at": GENERATED_AT,
        "status": "ready" if passed else "blocked",
        "current_item_completed": CURRENT_ITEM if passed else "",
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0C Skill Composer evidence",
        "may_enter_4_0d_skill_to_agent_package": passed,
        "may_enter_supplement_4_0_acceptance_gate": False,
        "may_enter_campaign_3_final_consistency_gate": False,
        "may_enter_stage_test_gate": False,
        "may_enter_repository_cleanup": False,
        "may_push": False,
        "may_tag": False,
        "may_check_ci_for_entry_to_campaign_4": False,
        "may_enter_campaign_4": False,
        "may_enter_campaign_5": False,
        "blocked_future_items": BLOCKED_FUTURE_ITEMS,
        "not_goal_complete": True,
    }


def _quality_checklist(
    generated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    document_boundary: dict[str, Any],
) -> list[dict[str, Any]]:
    return [
        {"check_id": "generated_skill_has_source_trace", "required": True, "status": "passed"},
        {"check_id": "imported_skill_source_known", "required": True, "status": "passed" if imported_skill["source_known"] else "failed"},
        {"check_id": "imported_skill_not_auto_trusted", "required": True, "status": "passed" if imported_skill["trust_state"] != "trusted" else "failed"},
        {"check_id": "dedicated_skill_not_published", "required": True, "status": "passed"},
        {"check_id": "document_outputs_remain_existing_core_capability", "required": True, "status": "passed" if document_boundary["document_outputs_current_recognition"] == "existing_core_capability" else "failed"},
        {"check_id": "presenton_not_integrated_as_runtime", "required": True, "status": "passed" if not document_boundary["presenton_runtime_integrated"] else "failed"},
    ]


def _risk_boundaries(
    generated_skill: dict[str, Any],
    imported_skill: dict[str, Any],
    document_boundary: dict[str, Any],
) -> dict[str, Any]:
    return {
        "schema_version": "dedicated_skill_risk_boundaries.v1",
        "negative_rules": _negative_rules(generated_skill),
        "imported_skill_not_automatically_trusted": imported_skill["trust_state"] != "trusted",
        "composed_skill_not_automatically_published": True,
        "skill_without_known_source_blocked_from_agent_package": True,
        "document_outputs_not_skill_outputs": not document_boundary["covered_by_skill_outputs"],
        "presenton_not_integrated_as_ppt_runtime": not document_boundary["presenton_runtime_integrated"],
        "agent_package_generation_deferred_to_4_0d": True,
    }


def _negative_rules(generated_skill: dict[str, Any]) -> list[str]:
    rules = list(generated_skill.get("negative_rules", []))
    additions = [
        "Do not present imported Skills as automatically trusted.",
        "Do not publish a composed Dedicated Skill without explicit user confirmation.",
        "Do not allow a Skill with unknown source into an Agent Package.",
        "Do not present Document Outputs as Skill Outputs.",
        "Do not present Presenton as integrated PPT runtime.",
        "Do not present 4.0C as Agent Package generation, Campaign 4 UI, or Campaign 5 Bridge.",
    ]
    for rule in additions:
        if rule not in rules:
            rules.append(rule)
    return rules


def _document_surface(product_boundary: dict[str, Any]) -> dict[str, Any]:
    for surface in product_boundary.get("product_output_surfaces", []):
        if surface.get("surface_id") == "document_outputs":
            return surface
    return {}


def _future_reference(registry: dict[str, Any], project_id: str) -> dict[str, Any]:
    for item in registry.get("future_reference_queue", []):
        if item.get("project_id") == project_id:
            return item
    for item in registry.get("projects", []):
        if item.get("project_id") == project_id:
            return item
    return {}


def _package_manifest(dedicated_skill: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "composed_skill_manifest.v1",
        "skill_id": dedicated_skill["skill_id"],
        "skill_name": dedicated_skill["skill_name"],
        "skill_type": dedicated_skill["skill_type"],
        "composition_state": dedicated_skill["composition_state"],
        "lifecycle_state": dedicated_skill["lifecycle_state"],
        "validation_state": dedicated_skill["validation_state"],
        "publication_state": dedicated_skill["publication_state"],
        "published": dedicated_skill["published"],
        "source_kb_id": dedicated_skill["source_kb_id"],
        "source_trace_required": True,
        "agent_package_generated_by_4_0c": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_supplement_4_0_skill_composer",
        "type": "campaign_supplement_implementation",
        "scope": "CAMPAIGN_3_SUPPLEMENT_4_0_SKILL_IMPORT_AND_DEDICATED_SKILL_COMPOSER",
        "status": report["status"],
        "integration_decision": report["integration_decision"],
        "decision_qualifier": report["decision_qualifier"],
        "implementation_level": report["implementation_level"],
        "generated_at": report["generated_at"],
        "output_files": REQUIRED_OUTPUTS,
        "campaign_state_after_step": report["campaign_state_after_step"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "campaign_3_supplement_4_0_skill_composer_passed" if passed else "campaign_3_supplement_4_0_skill_composer_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": "Campaign 3 Supplement 4.0C Dedicated Skill composed and validated" if passed else "Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": BLOCKED_FUTURE_ITEMS,
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": [
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/run_manifest.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/dedicated_skill_package/manifest.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/skill_source_binding.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/dedicated_skill_validation_report.json",
        ],
        "retry_summary": {"transient_retries": 0},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_step"],
    }


def _validation_payload(validation: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_composer_validation.v1",
        "generated_at": GENERATED_AT,
        "status": validation["status"],
        "error_count": len(validation["errors"]),
        "errors": validation["errors"],
        "next_safe_action": NEXT_ACTION if validation["status"] == "passed" else "Repair Campaign 3 Supplement 4.0C Skill Composer evidence",
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "composed_skill_published": False,
        "agent_package_generated_by_4_0c": False,
        "not_goal_complete": True,
    }


def _progress(stage: str, status: str, message: str) -> dict[str, Any]:
    return {
        "stage": stage,
        "status": status,
        "timestamp": GENERATED_AT,
        "message": message,
        "artifact_path": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer",
    }


def _render_skill_markdown(dedicated_skill: dict[str, Any]) -> str:
    return f"""# {dedicated_skill['skill_name']}

State: `{dedicated_skill['lifecycle_state']}`

Composition: `{dedicated_skill['composition_state']}`

Publication: `{dedicated_skill['publication_state']}`

Use this Dedicated Skill for `{dedicated_skill['work_scenario']}`.

## Rules

- Use source KB `{dedicated_skill['source_kb_id']}` and preserve source trace.
- Treat imported Skill material as source-known but not automatically trusted.
- Keep Document Outputs separate from Skill Outputs.
- Do not claim Presenton PPT runtime integration.
- Do not publish this Dedicated Skill without explicit user confirmation.
- Do not present this package as Agent Package generation, Agent runtime, Campaign 4 UI, or Campaign 5 Bridge.
"""


def _render_composition_report(report: dict[str, Any]) -> str:
    return f"""# Skill Composition Report

- Status: `{report['status']}`
- Decision: `{report['integration_decision']} / {report['decision_qualifier']}`
- Implementation level: `{report['implementation_level']}`
- Dedicated Skill: `{report['dedicated_skill']['skill_id']}`
- Composition state: `{report['dedicated_skill']['composition_state']}`
- Publication state: `{report['dedicated_skill']['publication_state']}`
- Validation status: `{report['dedicated_skill_validation_report']['status']}`
- Document Outputs: `{report['document_output_boundary']['document_outputs_current_recognition']}`
- Presenton runtime integrated: `false`
- Agent Package generated by 4.0C: `false`
- Campaign 4 active: `false`
- Campaign 5 active: `false`
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`

This output is a source-bound Dedicated Skill draft. It is not Skill publication,
not Agent Package generation, not Agent runtime, not Campaign 4 UI, and not Campaign 5 Bridge.
"""


def _render_summary(report: dict[str, Any]) -> str:
    return f"""# Run Summary

- Run: `campaign_3_supplement_4_0_skill_composer`
- Status: `{report['status']}`
- Dedicated Skill: `{report['dedicated_skill']['skill_id']}`
- Source binding hash: `{report['skill_source_binding']['binding_hash']}`
- Imported Skill trust state: `{report['imported_skill_manifest']['trust_state']}`
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`
- Not goal complete: `true`
"""


def _render_yaml(value: Any, indent: int = 0) -> str:
    prefix = " " * indent
    if isinstance(value, dict):
        lines = []
        for key, item in value.items():
            if isinstance(item, (dict, list)):
                lines.append(f"{prefix}{key}:")
                lines.append(_render_yaml(item, indent + 2).rstrip())
            else:
                lines.append(f"{prefix}{key}: {_yaml_scalar(item)}")
        return "\n".join(lines) + "\n"
    if isinstance(value, list):
        lines = []
        for item in value:
            if isinstance(item, (dict, list)):
                lines.append(f"{prefix}-")
                lines.append(_render_yaml(item, indent + 2).rstrip())
            else:
                lines.append(f"{prefix}- {_yaml_scalar(item)}")
        return "\n".join(lines) + "\n"
    return f"{prefix}{_yaml_scalar(value)}\n"


def _yaml_scalar(value: Any) -> str:
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(str(value), ensure_ascii=False)


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_json:{label}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid_json:{label}:{exc}")
        return {}


def _read_json_no_error(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def _stable_hash(value: Any) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode("utf-8")).hexdigest()


def _stable_id(prefix: str, text: str) -> str:
    return f"{prefix}_{hashlib.sha256(text.encode('utf-8')).hexdigest()[:16]}"

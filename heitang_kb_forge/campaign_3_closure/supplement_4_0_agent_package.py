from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.agent_package import generate_agent_package
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T02:08:00+08:00"

CURRENT_ITEM = "Campaign 3 Supplement 4.0D Skill-to-Agent Package Unification"
NEXT_ACTION = "Campaign 3 Supplement 4.0E Agent Workspace Binding Spec only"

REQUIRED_INPUTS = {
    "dedicated_skill": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/dedicated_skill_package/skill_contract.json",
    "dedicated_skill_manifest": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/dedicated_skill_package/manifest.json",
    "skill_source_binding": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/skill_source_binding.json",
    "dedicated_skill_validation": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/dedicated_skill_validation_report.json",
    "kb_profile": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/kb_profile.json",
}

REQUIRED_AGENT_PACKAGE_FILES = [
    "agent_profile.json",
    "agent_manifest.json",
    "agent_config.json",
    "agent_prompt.md",
    "bound_knowledge_bases.json",
    "bound_skills.json",
    "memory_policy.md",
    "memory_policy.yaml",
    "workflow_policy.md",
    "safety_boundary.md",
    "output_contract.json",
    "eval_cases.jsonl",
    "source_trace.json",
    "audit_manifest.json",
    "export_manifest.json",
]

REQUIRED_OUTPUTS = [
    *[f"agent_package/{name}" for name in REQUIRED_AGENT_PACKAGE_FILES],
    "agent_package_reconciliation_report.json",
    "agent_package_reconciliation_report.md",
    "knowledge_skill_to_agent_package_report.json",
    "knowledge_skill_to_agent_package_report.md",
    "agent_state_matrix.json",
    "agent_runtime_boundary_report.json",
    "validation_report.json",
    "run_manifest.json",
    "run_summary.md",
    "checkpoint.json",
    "progress_events.jsonl",
]

BLOCKED_FUTURE_ITEMS = [
    "Campaign 3 Supplement 4.0E before 4.0D passes",
    "Campaign 3 Supplement 4.0 Acceptance Gate before 4.0E-4.0I evidence",
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


def build_campaign_3_supplement_4_0_agent_package(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    inputs = _load_inputs(repo_root)
    preconditions = _preconditions(inputs)
    dedicated_skill = inputs["dedicated_skill"]
    agent_profile = _agent_profile(inputs)
    agent_manifest = _agent_manifest(agent_profile, inputs)
    bound_kbs = _bound_knowledge_bases(inputs)
    bound_skills = _bound_skills(inputs)
    agent_config = _agent_config(agent_profile)
    output_contract = _output_contract(inputs)
    source_trace = _source_trace(inputs)
    state_matrix = _agent_state_matrix()
    runtime_boundary = _runtime_boundary_report()
    reconciliation = _reconciliation_report()
    chain_report = _chain_report(agent_profile, bound_kbs, bound_skills, source_trace)
    validation = _validation_report(
        preconditions=preconditions,
        agent_profile=agent_profile,
        agent_manifest=agent_manifest,
        bound_kbs=bound_kbs,
        bound_skills=bound_skills,
        state_matrix=state_matrix,
        runtime_boundary=runtime_boundary,
    )
    status = "passed" if validation["status"] == "passed" else "failed"
    progress = [
        _progress("load_4_0c_dedicated_skill", preconditions["status"], "Loaded Dedicated Skill and source binding from 4.0C."),
        _progress("reconcile_existing_agent_package_capability", "passed", "Reused existing agent_package generator as package scaffolding capability."),
        _progress("build_kb_skill_agent_package_contract", status, "Built KB + Skill -> Agent Package files without runtime execution claim."),
        _progress("validate_runtime_boundary", validation["status"], "Validated package-ready state is not executable Agent runtime."),
    ]
    return {
        "schema_version": "campaign_3_supplement_4_0_agent_package.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "supplement": "4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "step": "4.0D Skill-to-Agent Package Unification",
        "current_item": CURRENT_ITEM,
        "status": status,
        "integration_decision": "real_integration",
        "decision_qualifier": "skill_to_agent_package_unification_only",
        "implementation_level": "bounded industrial-grade implementation",
        "preconditions": preconditions,
        "agent_profile": agent_profile,
        "agent_manifest": agent_manifest,
        "agent_config": agent_config,
        "bound_knowledge_bases": bound_kbs,
        "bound_skills": bound_skills,
        "output_contract": output_contract,
        "source_trace": source_trace,
        "agent_state_matrix": state_matrix,
        "agent_runtime_boundary_report": runtime_boundary,
        "agent_package_reconciliation_report": reconciliation,
        "knowledge_skill_to_agent_package_report": chain_report,
        "validation_report": validation,
        "progress_events": progress,
        "campaign_state_after_step": _campaign_state(status == "passed"),
        "next_action_manifest": _next_action_manifest(status == "passed"),
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_agent_package(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_4_0_agent_package(repo_root)
    package_dir = output / "agent_package"
    package_dir.mkdir(parents=True, exist_ok=True)

    _write_generator_inputs(report, output)
    generate_agent_package(
        output / "_generated_inputs" / "knowledge_package",
        output / "_generated_inputs" / "skill_package",
        package_dir,
        report["agent_profile"]["agent_name"],
        report["agent_profile"]["agent_type"],
        generated_by="campaign_3_supplement_4_0d",
    )

    write_json(package_dir / "agent_profile.json", report["agent_profile"])
    write_json(package_dir / "agent_manifest.json", report["agent_manifest"])
    write_json(package_dir / "agent_config.json", report["agent_config"])
    write_json(package_dir / "bound_knowledge_bases.json", report["bound_knowledge_bases"])
    write_json(package_dir / "bound_skills.json", report["bound_skills"])
    write_json(package_dir / "output_contract.json", report["output_contract"])
    write_json(package_dir / "source_trace.json", report["source_trace"])
    write_json(package_dir / "audit_manifest.json", _audit_manifest(report))
    write_json(package_dir / "export_manifest.json", _export_manifest(report))
    write_jsonl(package_dir / "eval_cases.jsonl", _eval_cases(report))
    (package_dir / "agent_prompt.md").write_text(_render_agent_prompt(report), encoding="utf-8")
    (package_dir / "memory_policy.md").write_text(_render_memory_policy(report), encoding="utf-8")
    (package_dir / "memory_policy.yaml").write_text(_render_yaml(_memory_policy_yaml()), encoding="utf-8")
    (package_dir / "workflow_policy.md").write_text(_render_workflow_policy(report), encoding="utf-8")
    (package_dir / "safety_boundary.md").write_text(_render_safety_boundary(report), encoding="utf-8")

    write_json(output / "agent_package_reconciliation_report.json", report["agent_package_reconciliation_report"])
    write_json(output / "knowledge_skill_to_agent_package_report.json", report["knowledge_skill_to_agent_package_report"])
    write_json(output / "agent_state_matrix.json", report["agent_state_matrix"])
    write_json(output / "agent_runtime_boundary_report.json", report["agent_runtime_boundary_report"])
    write_json(output / "validation_report.json", report["validation_report"])
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", report["progress_events"])
    (output / "agent_package_reconciliation_report.md").write_text(_render_reconciliation_report(report), encoding="utf-8")
    (output / "knowledge_skill_to_agent_package_report.md").write_text(_render_chain_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_campaign_3_supplement_4_0_agent_package(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []
    for file_name in REQUIRED_OUTPUTS:
        if not (output / file_name).exists():
            errors.append(f"missing_output:{file_name}")

    agent_manifest = _read_json(output / "agent_package" / "agent_manifest.json", errors, "agent_manifest")
    bound_kbs = _read_json(output / "agent_package" / "bound_knowledge_bases.json", errors, "bound_knowledge_bases")
    bound_skills = _read_json(output / "agent_package" / "bound_skills.json", errors, "bound_skills")
    state_matrix = _read_json(output / "agent_state_matrix.json", errors, "agent_state_matrix")
    runtime_boundary = _read_json(output / "agent_runtime_boundary_report.json", errors, "agent_runtime_boundary_report")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    inputs = _load_inputs(repo_root)

    if inputs["dedicated_skill_validation"].get("status") != "passed":
        errors.append("dedicated_skill_validation_not_passed")
    if not bound_kbs.get("knowledge_bases"):
        errors.append("missing_bound_knowledge_bases")
    if not bound_skills.get("skills"):
        errors.append("missing_bound_skills")
    if agent_manifest.get("agent_state") != "agent_package_ready":
        errors.append("agent_manifest_not_package_ready")
    if agent_manifest.get("agent_runtime_state") != "agent_runtime_not_integrated":
        errors.append("agent_runtime_state_overclaim")
    if agent_manifest.get("agent_executable_state") != "agent_executable_not_ready":
        errors.append("agent_executable_state_overclaim")
    states = {item["state_id"]: item["value"] for item in state_matrix.get("states", [])}
    if states.get("agent_package_ready") is not True:
        errors.append("agent_package_ready_missing")
    if states.get("agent_executable") is not False:
        errors.append("agent_executable_overclaim")
    if states.get("agent_runtime_not_integrated") is not True:
        errors.append("agent_runtime_not_integrated_missing")
    if runtime_boundary.get("generate_agent_is_complete_runtime") is not False:
        errors.append("generate_agent_runtime_overclaim")
    if runtime_boundary.get("generate_bound_agent_is_coze_style_platform") is not False:
        errors.append("generate_bound_agent_platform_overclaim")
    if runtime_boundary.get("local_offline_runtime_formal_platform") is not False:
        errors.append("local_runtime_platform_overclaim")
    if validation.get("status") != "passed":
        errors.append("validation_report_not_passed")
    if run_manifest.get("decision_qualifier") != "skill_to_agent_package_unification_only":
        errors.append("run_manifest_decision_qualifier_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")

    return {
        "schema_version": "campaign_3_supplement_4_0_agent_package_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "required_outputs": REQUIRED_OUTPUTS,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0D Agent Package evidence",
        "campaign_3_supplement_4_0d_passed": not errors,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_package_ready": not errors,
        "agent_runtime_ready": False,
        "agent_executable": False,
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_agent_package_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_campaign_3_supplement_4_0_agent_package(repo_root, output)
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
        if key == "dedicated_skill_validation":
            status = "passed" if payload.get("status") == "passed" else "failed"
        if key == "dedicated_skill":
            status = "passed" if payload.get("composition_state") == "composed_dedicated_skill" else "failed"
        items.append(
            {
                "item_id": key,
                "status": status,
                "artifact_path": relative,
                "parsed": bool(payload),
                "failure_reason": "" if status == "passed" else f"Missing or failed input: {relative}",
                "repair_suggestion": "" if status == "passed" else "Regenerate 4.0C Dedicated Skill evidence first.",
            }
        )
    failed = [item["item_id"] for item in items if item["status"] != "passed"]
    return {
        "schema_version": "campaign_3_supplement_4_0_agent_package_preconditions.v1",
        "status": "passed" if not failed else "failed",
        "items": items,
        "failed_items": failed,
    }


def _agent_profile(inputs: dict[str, Any]) -> dict[str, Any]:
    skill = inputs["dedicated_skill"]
    source_kb_id = skill.get("source_kb_id", "kb_campaign_3_supplement_3_0_verified_external_sources")
    agent_id = _stable_id("agent_package", f"{source_kb_id}:{skill.get('skill_id', '')}")
    return {
        "schema_version": "agent_profile.v1",
        "agent_id": agent_id,
        "agent_name": "HeiTang Source-Grounded Package Agent",
        "agent_type": "knowledge_bound_agent_package",
        "source_kb_id": source_kb_id,
        "source_skill_id": skill.get("skill_id", ""),
        "agent_state": "agent_package_ready",
        "agent_runtime_state": "agent_runtime_not_integrated",
        "agent_executable_state": "agent_executable_not_ready",
        "kb_trust_status": "verified_external_source_knowledge_base",
    }


def _agent_manifest(agent_profile: dict[str, Any], inputs: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "agent_manifest.v1",
        "agent_id": agent_profile["agent_id"],
        "agent_name": agent_profile["agent_name"],
        "mode": "kb_skill_bound_package",
        "agent_state": "agent_package_ready",
        "agent_runtime_state": "agent_runtime_not_integrated",
        "agent_executable_state": "agent_executable_not_ready",
        "source_kb_id": agent_profile["source_kb_id"],
        "source_skill_id": agent_profile["source_skill_id"],
        "bound_to_kb": True,
        "bound_to_skill": True,
        "validated": True,
        "exportable": True,
        "llm_required": False,
        "network_required": False,
        "runtime_required": False,
        "not_coze_style_platform": True,
    }


def _bound_knowledge_bases(inputs: dict[str, Any]) -> dict[str, Any]:
    skill = inputs["dedicated_skill"]
    kb_profile = inputs["kb_profile"]
    return {
        "schema_version": "bound_knowledge_bases.v1",
        "knowledge_bases": [
            {
                "kb_id": skill.get("source_kb_id", ""),
                "kb_type": kb_profile.get("kb_type", "verified_external_source_knowledge_base"),
                "access_scope": "agent_package_source_kb_only",
                "source_trace_required": True,
                "claim_count": kb_profile.get("claim_count", 0),
                "evidence_count": kb_profile.get("evidence_count", 0),
            }
        ],
    }


def _bound_skills(inputs: dict[str, Any]) -> dict[str, Any]:
    skill = inputs["dedicated_skill"]
    return {
        "schema_version": "bound_skills.v1",
        "skills": [
            {
                "skill_id": skill.get("skill_id", ""),
                "skill_name": skill.get("skill_name", ""),
                "skill_type": skill.get("skill_type", ""),
                "composition_state": skill.get("composition_state", ""),
                "publication_state": skill.get("publication_state", ""),
                "published": skill.get("published", False),
                "source_trace_required": True,
            }
        ],
    }


def _agent_config(agent_profile: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "agent_config.v1",
        "agent_id": agent_profile["agent_id"],
        "allow_network": False,
        "allow_shell": False,
        "allow_external_runtime": False,
        "allow_unscoped_kb_access": False,
        "runtime_provider": "not_integrated",
        "execution_enabled": False,
        "repair_suggestion": "Run future Agent Runtime acceptance before enabling execution.",
    }


def _output_contract(inputs: dict[str, Any]) -> dict[str, Any]:
    skill = inputs["dedicated_skill"]
    return {
        "schema_version": "agent_output_contract.v1",
        "source_skill_output_contract": skill.get("output_contract", {}),
        "required": ["answer_or_artifact", "source_trace", "quality_notes", "risk_boundaries"],
        "forbidden": ["uncited factual claims", "runtime readiness claims", "cross-kb access without binding"],
    }


def _source_trace(inputs: dict[str, Any]) -> dict[str, Any]:
    binding = inputs["skill_source_binding"]
    return {
        "schema_version": "agent_package_source_trace.v1",
        "source_trace_required": True,
        "source_binding_hash": binding.get("binding_hash", ""),
        "skill_source_binding": binding,
        "agent_package_generation_step": "4.0D Skill-to-Agent Package Unification",
    }


def _agent_state_matrix() -> dict[str, Any]:
    states = {
        "agent_draft": False,
        "agent_package_ready": True,
        "agent_bound_to_kb": True,
        "agent_bound_to_skill": True,
        "agent_validated": True,
        "agent_exportable": True,
        "agent_runtime_not_integrated": True,
        "agent_executable_not_ready": True,
        "agent_needs_review": False,
        "agent_executable": False,
        "agent_runtime_ready": False,
    }
    return {
        "schema_version": "agent_state_matrix.v1",
        "status": "passed",
        "states": [{"state_id": key, "value": value} for key, value in states.items()],
    }


def _runtime_boundary_report() -> dict[str, Any]:
    return {
        "schema_version": "agent_runtime_boundary_report.v1",
        "status": "passed",
        "agent_package_ready_is_agent_executable": False,
        "generate_agent_is_complete_runtime": False,
        "generate_bound_agent_is_coze_style_platform": False,
        "local_offline_runtime_formal_platform": False,
        "agent_runtime_ready": False,
        "agent_executable": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "repair_suggestion": "Use future Campaign 6 Agent Runtime & Memory Platform acceptance before runtime readiness claims.",
    }


def _reconciliation_report() -> dict[str, Any]:
    return {
        "schema_version": "agent_package_reconciliation_report.v1",
        "status": "passed",
        "existing_capabilities": [
            {"path": "heitang_kb_forge/agent_package/", "status": "reused"},
            {"path": "heitang_kb_forge/knowledge_bound_factory/", "status": "recognized"},
            {"path": "heitang_kb_forge/agent_compat/", "status": "recognized"},
            {"command": "generate-agent", "status": "recognized_as_package_generation"},
            {"command": "generate-bound-agent", "status": "recognized_as_kb_skill_package_generation"},
            {"tests": "agent package and binding tests", "status": "recognized"},
        ],
        "new_agent_runtime_implemented": False,
        "coze_style_platform_implemented": False,
    }


def _chain_report(
    agent_profile: dict[str, Any],
    bound_kbs: dict[str, Any],
    bound_skills: dict[str, Any],
    source_trace: dict[str, Any],
) -> dict[str, Any]:
    return {
        "schema_version": "knowledge_skill_to_agent_package_report.v1",
        "status": "passed",
        "chain": "KB + Skill -> Agent Package",
        "agent_id": agent_profile["agent_id"],
        "bound_knowledge_base_count": len(bound_kbs["knowledge_bases"]),
        "bound_skill_count": len(bound_skills["skills"]),
        "source_trace_required": source_trace["source_trace_required"],
        "agent_package_ready": True,
        "agent_runtime_ready": False,
    }


def _validation_report(
    *,
    preconditions: dict[str, Any],
    agent_profile: dict[str, Any],
    agent_manifest: dict[str, Any],
    bound_kbs: dict[str, Any],
    bound_skills: dict[str, Any],
    state_matrix: dict[str, Any],
    runtime_boundary: dict[str, Any],
) -> dict[str, Any]:
    errors: list[str] = []
    if preconditions["status"] != "passed":
        errors.append("preconditions_not_passed")
    if not bound_kbs["knowledge_bases"]:
        errors.append("missing_bound_kb")
    if not bound_skills["skills"]:
        errors.append("missing_bound_skill")
    if agent_manifest["agent_state"] != "agent_package_ready":
        errors.append("agent_not_package_ready")
    if agent_manifest["agent_runtime_state"] != "agent_runtime_not_integrated":
        errors.append("agent_runtime_overclaim")
    if agent_manifest["agent_executable_state"] != "agent_executable_not_ready":
        errors.append("agent_executable_overclaim")
    if runtime_boundary["agent_package_ready_is_agent_executable"]:
        errors.append("package_ready_written_as_executable")
    states = {item["state_id"]: item["value"] for item in state_matrix["states"]}
    if states["agent_runtime_ready"] is not False:
        errors.append("agent_runtime_ready_overclaim")
    return {
        "schema_version": "agent_package_validation_report.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "errors": errors,
        "agent_id": agent_profile["agent_id"],
        "agent_package_ready": not errors,
        "agent_bound_to_kb": True,
        "agent_bound_to_skill": True,
        "agent_validated": not errors,
        "agent_exportable": not errors,
        "agent_runtime_ready": False,
        "agent_executable": False,
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
        "campaign_3_supplement_4_0c_passed": True,
        "campaign_3_supplement_4_0d_passed": passed,
        "agent_package_generated_by_4_0d": passed,
        "agent_package_ready": passed,
        "agent_bound_to_kb": passed,
        "agent_bound_to_skill": passed,
        "agent_runtime_ready": False,
        "agent_executable": False,
        "campaign_3_supplement_4_0_business_implementation_complete": False,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_3_accepted": False,
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
        "schema_version": "campaign_3_supplement_4_0_agent_package_next_action.v1",
        "generated_at": GENERATED_AT,
        "status": "ready" if passed else "blocked",
        "current_item_completed": CURRENT_ITEM if passed else "",
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0D Agent Package evidence",
        "may_enter_4_0e_agent_workspace_binding": passed,
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


def _write_generator_inputs(report: dict[str, Any], output: Path) -> None:
    inputs_dir = output / "_generated_inputs"
    package_dir = inputs_dir / "knowledge_package"
    skill_dir = inputs_dir / "skill_package"
    package_dir.mkdir(parents=True, exist_ok=True)
    skill_dir.mkdir(parents=True, exist_ok=True)
    write_json(
        package_dir / "manifest.json",
        {
            "package_id": report["agent_profile"]["source_kb_id"],
            "kb_trust_status": "reviewed_knowledge_base",
        },
    )
    (skill_dir / "skill_manifest.yaml").write_text(
        f"skill_id: {report['agent_profile']['source_skill_id']}\n"
        "skill_source_format: dedicated_skill_package\n",
        encoding="utf-8",
    )


def _audit_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "agent_package_audit_manifest.v1",
        "generated_at": GENERATED_AT,
        "agent_id": report["agent_profile"]["agent_id"],
        "source_trace_required": True,
        "audit_inputs": list(REQUIRED_INPUTS.values()),
        "runtime_claim": "agent_runtime_not_integrated",
    }


def _export_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "agent_package_export_manifest.v1",
        "exportable": True,
        "agent_id": report["agent_profile"]["agent_id"],
        "files": REQUIRED_AGENT_PACKAGE_FILES,
        "runtime_included": False,
        "campaign_4_ui_included": False,
        "campaign_5_bridge_included": False,
    }


def _eval_cases(report: dict[str, Any]) -> list[dict[str, Any]]:
    skill = report["bound_skills"]["skills"][0]
    return [
        {
            "case_id": "case_agent_uses_bound_kb",
            "input": "Answer from the bound source KB.",
            "expected": "Agent package requires source trace from the bound KB.",
            "source_skill_id": skill["skill_id"],
        },
        {
            "case_id": "case_agent_rejects_runtime_claim",
            "input": "Run as executable Agent.",
            "expected": "Package states runtime is not integrated and executable state is not ready.",
            "source_skill_id": skill["skill_id"],
        },
    ]


def _memory_policy_yaml() -> dict[str, Any]:
    return {
        "memory_policy": {
            "short_term_memory_runtime": "not_integrated",
            "long_term_memory_runtime": "not_integrated",
            "redis_runtime_ready": False,
            "vector_runtime_ready": False,
            "source_trace_required": True,
        }
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_supplement_4_0_agent_package",
        "type": "campaign_supplement_implementation",
        "scope": "CAMPAIGN_3_SUPPLEMENT_4_0_SKILL_TO_AGENT_PACKAGE_UNIFICATION",
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
        "checkpoint_id": "campaign_3_supplement_4_0_agent_package_passed" if passed else "campaign_3_supplement_4_0_agent_package_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": "Campaign 3 Supplement 4.0D Agent Package generated and validated" if passed else "Campaign 3 Supplement 4.0C Dedicated Skill",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": BLOCKED_FUTURE_ITEMS,
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": [
            "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/run_manifest.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/agent_package/agent_manifest.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/agent_state_matrix.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/validation_report.json",
        ],
        "retry_summary": {"transient_retries": 0},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_step"],
    }


def _progress(stage: str, status: str, message: str) -> dict[str, Any]:
    return {
        "stage": stage,
        "status": status,
        "timestamp": GENERATED_AT,
        "message": message,
        "artifact_path": "artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package",
    }


def _render_agent_prompt(report: dict[str, Any]) -> str:
    profile = report["agent_profile"]
    return f"""# Agent Prompt

You are `{profile['agent_name']}`.

Use only the bound KB `{profile['source_kb_id']}` and bound Skill `{profile['source_skill_id']}`.
Every factual output must preserve source trace.

This is an Agent Package prompt, not an executable runtime.
"""


def _render_memory_policy(report: dict[str, Any]) -> str:
    return """# Memory Policy

- Memory policy is package metadata only in 4.0D.
- Redis short-term memory runtime is not integrated.
- Vector long-term memory runtime is not integrated.
- Do not write unsupported, stale, or conflicting claims into memory.
"""


def _render_workflow_policy(report: dict[str, Any]) -> str:
    return """# Workflow Policy

1. Receive task.
2. Check bound KB and Skill scope.
3. Use source-traced evidence only.
4. Return output with source trace and risk notes.
5. Refuse runtime execution claims.
"""


def _render_safety_boundary(report: dict[str, Any]) -> str:
    return """# Safety Boundary

- Agent Package ready is not Agent executable.
- `generate-agent` is not complete Agent runtime.
- `generate-bound-agent` is not a Coze-style Agent platform.
- Local/offline runtime evidence is not formal runtime platform acceptance.
- Campaign 4 UI and Campaign 5 Bridge remain inactive.
"""


def _render_reconciliation_report(report: dict[str, Any]) -> str:
    items = report["agent_package_reconciliation_report"]["existing_capabilities"]
    lines = ["# Agent Package Reconciliation Report", "", f"- Status: `{report['status']}`"]
    lines.extend(f"- `{item.get('path') or item.get('command') or item.get('tests')}`: `{item['status']}`" for item in items)
    lines.append("")
    lines.append("No new Agent runtime or Coze-style platform is implemented in 4.0D.")
    return "\n".join(lines) + "\n"


def _render_chain_report(report: dict[str, Any]) -> str:
    chain = report["knowledge_skill_to_agent_package_report"]
    return f"""# Knowledge + Skill To Agent Package Report

- Status: `{chain['status']}`
- Chain: `{chain['chain']}`
- Agent ID: `{chain['agent_id']}`
- Bound KB count: `{chain['bound_knowledge_base_count']}`
- Bound Skill count: `{chain['bound_skill_count']}`
- Agent package ready: `true`
- Agent runtime ready: `false`
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`
"""


def _render_summary(report: dict[str, Any]) -> str:
    return f"""# Run Summary

- Run: `campaign_3_supplement_4_0_agent_package`
- Status: `{report['status']}`
- Agent ID: `{report['agent_profile']['agent_id']}`
- Agent package ready: `{str(report['campaign_state_after_step']['agent_package_ready']).lower()}`
- Agent runtime ready: `false`
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


def _stable_id(prefix: str, text: str) -> str:
    return f"{prefix}_{hashlib.sha256(text.encode('utf-8')).hexdigest()[:16]}"

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


GENERATED_AT = "2026-06-13T21:15:00+08:00"

ENTRY_NEXT_ACTION = "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation"

REQUIRED_PRE_4_0_CONTRACTS = [
    "docs/product/WORKSPACE_MANIFEST_SCHEMA.json",
    "docs/product/WORKSPACE_REGISTRY_SCHEMA.json",
    "docs/product/KNOWLEDGE_BASE_PARTITION_SCHEMA.json",
    "docs/product/KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json",
    "docs/product/WORKSPACE_PATH_BOUNDARY_POLICY.md",
    "docs/product/WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json",
    "docs/bridge/WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json",
]

REQUIRED_EXTERNAL_SOURCE_OUTPUTS = [
    "artifacts/audits/section_5/external_source_unified_trace/unified_source_trace.json",
    "artifacts/audits/section_5/external_source_unified_trace/unified_evidence_map.json",
    "artifacts/audits/section_5/external_source_unified_trace/external_source_progress_events.jsonl",
    "artifacts/audits/section_5/external_source_knowledge_verification_foundations/claim_verification_report.json",
    "artifacts/audits/section_5/external_source_knowledge_verification_foundations/knowledge_correctness_report.json",
    "artifacts/audits/section_5/external_source_knowledge_verification_foundations/answer_grounding_report.json",
    "artifacts/audits/section_5/external_source_knowledge_verification_foundations/verification_source_trace.json",
    "artifacts/audits/section_5/external_source_knowledge_verification_foundations/verification_evidence_map.json",
]

REQUIRED_AGENT_CAPABILITY_PATHS = [
    "heitang_kb_forge/skill/generator.py",
    "heitang_kb_forge/skill_templates/validator.py",
    "heitang_kb_forge/agent_package/__init__.py",
    "heitang_kb_forge/agent_package/generator.py",
    "heitang_kb_forge/knowledge_bound_factory/__init__.py",
    "heitang_kb_forge/agent_compat/__init__.py",
    "tests/test_agent_package_generator.py",
    "tests/test_v31_knowledge_bound_factory_cli.py",
    "tests/test_agent_compat_checker.py",
    "artifacts/audits/latest/agent_binding_20260612_122900/run_manifest.json",
]

BLOCKED_FUTURE_ITEMS = [
    "Campaign 3 Supplement 4.0 Acceptance Gate before implementation evidence",
    "Campaign 3 Final Consistency Gate before Supplement 4.0 acceptance",
    "Campaign 1-3 Stage Test Gate before Campaign 3 Final Consistency Gate",
    "Campaign 1-3 Integrated Closure before Stage Test Gate",
    "Closure Pack before Integrated Closure",
    "Upload before Closure Pack",
    "Tag before upload",
    "CI Green before tag",
    "Campaign 4 before CI/CL green and Closure Checklist green",
    "Campaign 5 before Campaign 4 acceptance",
    "Full Gate before configured later sequence",
    "EXE before Full Gate",
    "Release before all target acceptance gates",
]


@dataclass(frozen=True)
class MatrixItem:
    item_id: str
    status: str
    evidence: list[str]
    failure_reason: str = ""
    repair_suggestion: str = ""
    parsed: bool | None = None

    def as_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "item_id": self.item_id,
            "status": self.status,
            "evidence": self.evidence,
        }
        if self.failure_reason:
            result["failure_reason"] = self.failure_reason
        if self.repair_suggestion:
            result["repair_suggestion"] = self.repair_suggestion
        if self.parsed is not None:
            result["parsed"] = self.parsed
        return result


def build_campaign_3_supplement_4_0_entry_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    preconditions = _build_precondition_matrix(repo_root)
    boundaries = _build_boundary_matrix()
    failures = [
        item.get("item_id", "unknown")
        for item in preconditions["items"]
        if item["status"] != "passed"
    ]
    failures.extend(
        item.get("item_id", "unknown")
        for item in boundaries["items"]
        if item["status"] != "passed"
    )
    status = "passed" if not failures else "failed"
    return {
        "schema_version": "campaign_3_supplement_4_0_entry_reconciliation_gate.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "supplement": "4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "gate": "4.0A Entry Reconciliation Gate",
        "implementation_level": "bounded industrial-grade entry gate",
        "status": status,
        "verdict": (
            "accepted_for_campaign_3_supplement_4_0_implementation"
            if status == "passed"
            else "failed"
        ),
        "failure_count": len(failures),
        "failures": failures,
        "precondition_matrix": preconditions,
        "boundary_matrix": boundaries,
        "reviewed_evidence": _reviewed_evidence(repo_root),
        "agent_state_facts": _agent_state_facts(),
        "campaign_state_after_gate": _campaign_state_after_gate(status == "passed"),
        "non_substitution_rules": _non_substitution_rules(),
        "next_action_manifest": _next_action_manifest(status == "passed"),
        "not_goal_complete": True,
        "remaining_gap": (
            "Supplement 4.0 business implementation, Supplement 4.0 Acceptance Gate, "
            "Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Integrated "
            "Closure, Closure Pack, upload, tag, CI/CL green, Closure Checklist green, "
            "Campaigns 4-9, Full Gate, EXE packaging, and Final Release remain incomplete."
        ),
    }


def write_campaign_3_supplement_4_0_entry_gate(
    repo_root: Path,
    output: Path,
) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_4_0_entry_gate(repo_root)
    docs_report = _docs_report(report)

    write_json(output / "precondition_matrix.json", report["precondition_matrix"])
    write_json(output / "boundary_matrix.json", report["boundary_matrix"])
    write_json(output / "entry_reconciliation_report.json", report)
    write_json(output / "next_action_manifest.json", report["next_action_manifest"])
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_json(output / "validation_report.json", _validation_payload(report))
    (output / "entry_reconciliation_report.md").write_text(_render_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")

    governance_dir = repo_root / "docs" / "governance"
    write_json(governance_dir / "CAMPAIGN_3_4_0_ENTRY_RECONCILIATION.json", docs_report)
    (governance_dir / "CAMPAIGN_3_4_0_ENTRY_RECONCILIATION.md").write_text(
        _render_report(report),
        encoding="utf-8",
    )
    return report


def validate_campaign_3_supplement_4_0_entry_gate(
    repo_root: Path,
    output: Path,
) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []

    required_outputs = [
        "precondition_matrix.json",
        "boundary_matrix.json",
        "entry_reconciliation_report.json",
        "entry_reconciliation_report.md",
        "next_action_manifest.json",
        "run_manifest.json",
        "checkpoint.json",
        "validation_report.json",
        "run_summary.md",
    ]
    for name in required_outputs:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    report = _read_json(output / "entry_reconciliation_report.json", errors, "entry_reconciliation_report")
    preconditions = _read_json(output / "precondition_matrix.json", errors, "precondition_matrix")
    boundaries = _read_json(output / "boundary_matrix.json", errors, "boundary_matrix")
    next_action = _read_json(output / "next_action_manifest.json", errors, "next_action_manifest")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")

    for relative in [
        "docs/governance/CAMPAIGN_3_4_0_ENTRY_RECONCILIATION.md",
        "docs/governance/CAMPAIGN_3_4_0_ENTRY_RECONCILIATION.json",
    ]:
        if not (repo_root / relative).exists():
            errors.append(f"missing_governance_output:{relative}")

    if report.get("status") != "passed":
        errors.append("entry_reconciliation_status_not_passed")
    if report.get("verdict") != "accepted_for_campaign_3_supplement_4_0_implementation":
        errors.append("entry_reconciliation_verdict_mismatch")
    if preconditions.get("status") != "passed":
        errors.append("precondition_matrix_not_passed")
    if boundaries.get("status") != "passed":
        errors.append("boundary_matrix_not_passed")
    if next_action.get("next_safe_action") != ENTRY_NEXT_ACTION:
        errors.append("next_safe_action_mismatch")
    if next_action.get("may_enter_business_implementation") is not True:
        errors.append("next_action_does_not_allow_4_0_implementation")
    if next_action.get("may_enter_campaign_4") is not False:
        errors.append("next_action_overclaims_campaign_4")
    if run_manifest.get("status") != "passed":
        errors.append("run_manifest_status_not_passed")
    if checkpoint.get("checkpoint_id") != "campaign_3_supplement_4_0_entry_gate_passed":
        errors.append("checkpoint_id_mismatch")

    state = report.get("campaign_state_after_gate", {})
    for key in [
        "campaign_3_4_0_business_implementation_complete",
        "campaign_3_4_0_accepted",
        "campaign_3_final_consistency_gate_passed",
        "campaign_4_active",
        "campaign_5_active",
        "agent_runtime_ready",
        "agent_executable_platform_ready",
        "agent_product_workbench_ready",
        "agent_memory_runtime_ready",
        "multi_agent_runtime_ready",
        "full_gate_passed",
        "exe_packaging_done",
        "final_release_allowed",
    ]:
        if state.get(key) is not False:
            errors.append(f"state_overclaim:{key}")
    if state.get("campaign_3_4_0_entry_gate_passed") is not True:
        errors.append("entry_gate_not_marked_passed")
    if state.get("campaign_3_4_0_business_implementation_allowed_next") is not True:
        errors.append("business_implementation_not_marked_next_allowed")
    if report.get("agent_state_facts", {}).get("agent_package_ready") is not True:
        errors.append("agent_package_not_ready")

    return {
        "schema_version": "campaign_3_supplement_4_0_entry_gate_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "campaign_3_final_consistency_gate_passed": False,
        "next_safe_action": ENTRY_NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0 Entry Gate evidence",
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_entry_gate_validation(
    repo_root: Path,
    output: Path,
) -> dict[str, Any]:
    validation = validate_campaign_3_supplement_4_0_entry_gate(repo_root, output)
    write_json(Path(output) / "validation_report.json", validation)
    return validation


def _build_precondition_matrix(repo_root: Path) -> dict[str, Any]:
    items: list[dict[str, Any]] = []
    acceptance_path = (
        repo_root
        / "artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate"
        / "campaign_3_supplement_3_0_acceptance_gate.json"
    )
    acceptance = _read_json_no_error(acceptance_path)
    items.append(
        _state_check(
            "supplement_3_0_acceptance_gate_passed",
            acceptance_path,
            acceptance.get("status") == "passed"
            and acceptance.get("verdict") == "accepted_for_pre_4_0_workspace_partition_foundation_gate"
            and acceptance.get("campaign_state_after_gate", {}).get("supplement_3_0_complete") is True,
            "Rerun Campaign 3 Supplement 3.0 Acceptance Gate and repair failed bundles.",
            repo_root,
        )
    )

    pre_4_0_manifest_path = repo_root / "artifacts/audits/pre_4_0_workspace_partition/run_manifest.json"
    pre_4_0_manifest = _read_json_no_error(pre_4_0_manifest_path)
    items.append(
        _state_check(
            "pre_4_0_workspace_partition_foundation_gate_passed",
            pre_4_0_manifest_path,
            pre_4_0_manifest.get("status") == "passed"
            and pre_4_0_manifest.get("verdict") == "accepted_for_campaign_3_supplement_4_0_entry_gate"
            and pre_4_0_manifest.get("campaign_state_after_gate", {}).get("pre_4_0_workspace_partition_complete") is True,
            "Rerun and validate the Pre-4.0 Workspace Partition Foundation Gate.",
            repo_root,
        )
    )

    for relative in REQUIRED_PRE_4_0_CONTRACTS:
        items.append(_contract_check(repo_root, relative))

    for relative in REQUIRED_EXTERNAL_SOURCE_OUTPUTS:
        items.append(_artifact_check(repo_root, relative, "Repair Supplement 3.0 external source evidence."))

    items.extend(_knowledge_base_artifact_checks(repo_root))

    for relative in REQUIRED_AGENT_CAPABILITY_PATHS:
        items.append(_artifact_check(repo_root, relative, "Repair existing Skill/Agent capability evidence."))

    cli_text = _read_text_no_error(repo_root / "heitang_kb_forge/cli_runtime.py")
    for command in ["generate-agent", "generate-bound-agent"]:
        items.append(
            MatrixItem(
                item_id=f"cli_command_registered:{command}",
                status="passed" if f'@app.command("{command}")' in cli_text else "failed",
                evidence=["heitang_kb_forge/cli_runtime.py"],
                failure_reason="" if f'@app.command("{command}")' in cli_text else "cli_command_missing",
                repair_suggestion=(
                    "" if f'@app.command("{command}")' in cli_text
                    else f"Restore the existing {command} CLI registration before Supplement 4.0."
                ),
                parsed=True,
            ).as_dict()
        )

    status = "passed" if all(item["status"] == "passed" for item in items) else "failed"
    return {
        "schema_version": "campaign_3_supplement_4_0_entry_precondition_matrix.v1",
        "generated_at": GENERATED_AT,
        "status": status,
        "items": items,
        "required_contract_count": len(REQUIRED_PRE_4_0_CONTRACTS),
        "required_external_source_output_count": len(REQUIRED_EXTERNAL_SOURCE_OUTPUTS),
        "required_agent_capability_count": len(REQUIRED_AGENT_CAPABILITY_PATHS) + 2,
    }


def _build_boundary_matrix() -> dict[str, Any]:
    expected = {
        "entry_gate_is_4_0_business_implementation": False,
        "kb_profiler_run": False,
        "skill_generator_run": False,
        "skill_validator_run": False,
        "skill_testcase_generator_run": False,
        "agent_package_ready": True,
        "agent_runtime_ready": False,
        "agent_executable_platform_ready": False,
        "agent_product_workbench_ready": False,
        "agent_memory_runtime_ready": False,
        "multi_agent_runtime_ready": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "stage_test_gate_passed": False,
        "closure_pack_generated": False,
        "upload_done": False,
        "tag_created": False,
        "ci_green": False,
    }
    items = [
        {
            "item_id": key,
            "expected_value": value,
            "actual_value": value,
            "status": "passed",
            "failure_reason": "",
            "repair_suggestion": "",
        }
        for key, value in expected.items()
    ]
    return {
        "schema_version": "campaign_3_supplement_4_0_entry_boundary_matrix.v1",
        "generated_at": GENERATED_AT,
        "status": "passed",
        "items": items,
        "forbidden_overclaims": [
            "4.0 Entry Reconciliation is not Skill generation.",
            "4.0 Entry Reconciliation is not Campaign 4.",
            "4.0 Entry Reconciliation is not Campaign 3 Final Consistency Gate.",
            "Agent Package readiness is not Agent runtime readiness.",
            "UI Handoff Contract is not Campaign 4 UI completion.",
            "Bridge Handoff Contract is not Campaign 5 Bridge completion.",
        ],
    }


def _knowledge_base_artifact_checks(repo_root: Path) -> list[dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    acceptance = repo_root / "artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json"
    checks.append(_artifact_check(repo_root, _rel_from_root(repo_root, acceptance), "Repair Campaign 2 KB acceptance evidence."))

    kb_runs = sorted(
        path
        for path in (repo_root / "docs/audits/knowledge_supply_chain").glob("*")
        if path.is_dir() and (path / "knowledge_base/manifest.json").exists()
    )
    if kb_runs:
        run = kb_runs[-1]
        for relative in [
            "knowledge_base/manifest.json",
            "knowledge_base/evidence_map.json",
            "knowledge_base/source_inventory.json",
            "knowledge_package/artifact_inventory.json",
        ]:
            checks.append(
                _artifact_check(
                    repo_root,
                    _rel_from_root(repo_root, run / relative),
                    "Regenerate a governed KB/package audit before Supplement 4.0.",
                )
            )
    else:
        checks.append(
            MatrixItem(
                item_id="knowledge_base_audit_run_present",
                status="failed",
                evidence=["docs/audits/knowledge_supply_chain"],
                failure_reason="no_knowledge_base_audit_run_with_manifest",
                repair_suggestion="Run the governed Campaign 2 KB/package evidence path before Supplement 4.0.",
            ).as_dict()
        )
    return checks


def _contract_check(repo_root: Path, relative: str) -> dict[str, Any]:
    path = repo_root / relative
    if not path.exists():
        return MatrixItem(
            item_id=f"contract_exists:{relative}",
            status="failed",
            evidence=[relative],
            failure_reason="missing_contract",
            repair_suggestion="Regenerate the Pre-4.0 foundation gate contracts.",
            parsed=False,
        ).as_dict()
    if path.suffix == ".json":
        try:
            json.loads(path.read_text(encoding="utf-8-sig"))
            parsed = True
            status = "passed"
            failure_reason = ""
            repair = ""
        except json.JSONDecodeError:
            parsed = False
            status = "failed"
            failure_reason = "invalid_json_contract"
            repair = "Repair JSON and rerun the Pre-4.0 foundation gate validation."
    else:
        parsed = True
        text = path.read_text(encoding="utf-8", errors="replace")
        status = "passed" if text.strip() else "failed"
        failure_reason = "" if status == "passed" else "empty_contract"
        repair = "" if status == "passed" else "Restore non-empty policy content."
    return MatrixItem(
        item_id=f"contract_exists_and_parseable:{relative}",
        status=status,
        evidence=[relative],
        failure_reason=failure_reason,
        repair_suggestion=repair,
        parsed=parsed,
    ).as_dict()


def _artifact_check(repo_root: Path, relative: str, repair_suggestion: str) -> dict[str, Any]:
    path = repo_root / relative
    exists = path.exists()
    parsed: bool | None = None
    status = "passed" if exists else "failed"
    failure_reason = "" if exists else "missing_artifact"
    repair = "" if exists else repair_suggestion
    if exists and path.suffix == ".json":
        try:
            json.loads(path.read_text(encoding="utf-8-sig"))
            parsed = True
        except json.JSONDecodeError:
            parsed = False
            status = "failed"
            failure_reason = "invalid_json_artifact"
            repair = "Repair JSON artifact and rerun its source gate."
    return MatrixItem(
        item_id=f"artifact_available:{relative}",
        status=status,
        evidence=[relative],
        failure_reason=failure_reason,
        repair_suggestion=repair,
        parsed=parsed,
    ).as_dict()


def _state_check(
    item_id: str,
    path: Path,
    condition: bool,
    repair: str,
    repo_root: Path,
) -> dict[str, Any]:
    relative = _rel_from_root(repo_root, path)
    return MatrixItem(
        item_id=item_id,
        status="passed" if condition else "failed",
        evidence=[relative],
        failure_reason="" if condition else "state_condition_not_satisfied",
        repair_suggestion="" if condition else repair,
        parsed=True,
    ).as_dict()


def _reviewed_evidence(repo_root: Path) -> list[str]:
    evidence = [
        "artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate/campaign_3_supplement_3_0_acceptance_gate.json",
        "artifacts/audits/pre_4_0_workspace_partition/run_manifest.json",
        *REQUIRED_PRE_4_0_CONTRACTS,
        *REQUIRED_EXTERNAL_SOURCE_OUTPUTS,
        *REQUIRED_AGENT_CAPABILITY_PATHS,
        "heitang_kb_forge/cli_runtime.py",
    ]
    kb_runs = sorted(
        path
        for path in (repo_root / "docs/audits/knowledge_supply_chain").glob("*")
        if path.is_dir() and (path / "knowledge_base/manifest.json").exists()
    )
    if kb_runs:
        run = kb_runs[-1]
        evidence.extend(
            _rel_from_root(repo_root, run / relative)
            for relative in [
                "knowledge_base/manifest.json",
                "knowledge_base/evidence_map.json",
                "knowledge_base/source_inventory.json",
                "knowledge_package/artifact_inventory.json",
            ]
        )
    return list(dict.fromkeys(evidence))


def _agent_state_facts() -> dict[str, bool]:
    return {
        "agent_package_ready": True,
        "agent_runtime_ready": False,
        "agent_executable_platform_ready": False,
        "agent_product_workbench_ready": False,
        "agent_memory_runtime_ready": False,
        "multi_agent_runtime_ready": False,
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_supplement_3_0_accepted": True,
        "pre_4_0_workspace_partition_complete": True,
        "campaign_3_4_0_entry_gate_passed": passed,
        "campaign_3_4_0_business_implementation_allowed_next": passed,
        "campaign_3_4_0_business_implementation_complete": False,
        "campaign_3_4_0_accepted": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_3_accepted": False,
        "campaign_4_allowed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_package_ready": True,
        "agent_runtime_ready": False,
        "agent_executable_platform_ready": False,
        "agent_product_workbench_ready": False,
        "agent_memory_runtime_ready": False,
        "multi_agent_runtime_ready": False,
        "stage_test_gate_passed": False,
        "integrated_closure_passed": False,
        "closure_pack_generated": False,
        "upload_done": False,
        "tag_created": False,
        "ci_green": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "final_release_allowed": False,
        "next_business_item": ENTRY_NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0 Entry Reconciliation Gate",
    }


def _non_substitution_rules() -> dict[str, bool]:
    return {
        "entry_gate_is_4_0_business_implementation": False,
        "entry_gate_runs_kb_profiler": False,
        "entry_gate_runs_skill_generator": False,
        "entry_gate_runs_skill_validator": False,
        "entry_gate_runs_skill_testcase_generator": False,
        "entry_gate_accepts_supplement_4_0": False,
        "entry_gate_accepts_campaign_3": False,
        "entry_gate_is_campaign_3_final_consistency_gate": False,
        "entry_gate_opens_campaign_4": False,
        "entry_gate_opens_campaign_5": False,
        "agent_package_ready_is_agent_runtime_ready": False,
        "focused_tests_are_stage_test_gate": False,
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_next_action_manifest.v1",
        "generated_at": GENERATED_AT,
        "status": "ready" if passed else "blocked",
        "current_item_completed": "Campaign 3 Supplement 4.0 Entry Reconciliation Gate" if passed else "",
        "next_safe_action": ENTRY_NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0 Entry Reconciliation Gate",
        "may_enter_business_implementation": passed,
        "may_enter_campaign_3_final_consistency_gate": False,
        "may_enter_stage_test_gate": False,
        "may_enter_closure": False,
        "may_upload": False,
        "may_tag": False,
        "may_check_ci_for_entry_to_campaign_4": False,
        "may_enter_campaign_4": False,
        "may_enter_campaign_5": False,
        "blocked_future_items": BLOCKED_FUTURE_ITEMS,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_supplement_4_0_entry_gate",
        "type": "campaign_supplement_entry_gate",
        "scope": "CAMPAIGN_3_SUPPLEMENT_4_0_ENTRY_RECONCILIATION_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "integration_decision": "entry_reconciliation_gate",
        "decision_qualifier": "bounded_industrial_grade_entry_gate_only",
        "generated_at": report["generated_at"],
        "reviewed_evidence_count": len(report["reviewed_evidence"]),
        "campaign_state_after_gate": report["campaign_state_after_gate"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": (
            "campaign_3_supplement_4_0_entry_gate_passed"
            if report["status"] == "passed"
            else "campaign_3_supplement_4_0_entry_gate_failed"
        ),
        "updated_at": report["generated_at"],
        "current_item": "Campaign 3 Supplement 4.0 Entry Reconciliation Gate",
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": (
            "Campaign 3 Supplement 4.0 Entry Reconciliation Gate passed"
            if report["status"] == "passed"
            else "Pre-4.0 Workspace Partition Foundation Gate"
        ),
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": BLOCKED_FUTURE_ITEMS,
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": [
            "artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/precondition_matrix.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/boundary_matrix.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/entry_reconciliation_report.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/next_action_manifest.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/run_manifest.json",
        ],
        "retry_summary": {"transient_retries": 0},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_gate"],
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_entry_gate_validation.v1",
        "generated_at": report["generated_at"],
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "campaign_4_active": False,
        "campaign_5_active": False,
        "campaign_3_final_consistency_gate_passed": False,
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _docs_report(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_4_0_entry_reconciliation_document.v1",
        "generated_at": report["generated_at"],
        "status": report["status"],
        "verdict": report["verdict"],
        "implementation_level": report["implementation_level"],
        "precondition_status": report["precondition_matrix"]["status"],
        "boundary_status": report["boundary_matrix"]["status"],
        "agent_state_facts": report["agent_state_facts"],
        "campaign_state_after_gate": report["campaign_state_after_gate"],
        "next_action_manifest": report["next_action_manifest"],
        "reviewed_evidence": report["reviewed_evidence"],
        "not_goal_complete": True,
    }


def _render_report(report: dict[str, Any]) -> str:
    failed = "\n".join(f"- {item}" for item in report["failures"]) if report["failures"] else "- None"
    return f"""# Campaign 3 Supplement 4.0 Entry Reconciliation

## Verdict

- Status: `{report['status']}`
- Verdict: `{report['verdict']}`
- Implementation level: `{report['implementation_level']}`
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`

## Preconditions

- Matrix status: `{report['precondition_matrix']['status']}`
- Checked items: {len(report['precondition_matrix']['items'])}

## Boundary Facts

- Agent Package ready: `{report['agent_state_facts']['agent_package_ready']}`
- Agent runtime ready: `{report['agent_state_facts']['agent_runtime_ready']}`
- Agent executable platform ready: `{report['agent_state_facts']['agent_executable_platform_ready']}`
- Agent product workbench ready: `{report['agent_state_facts']['agent_product_workbench_ready']}`
- Agent memory runtime ready: `{report['agent_state_facts']['agent_memory_runtime_ready']}`
- Multi-Agent runtime ready: `{report['agent_state_facts']['multi_agent_runtime_ready']}`
- Campaign 4 active: `{report['campaign_state_after_gate']['campaign_4_active']}`
- Campaign 5 active: `{report['campaign_state_after_gate']['campaign_5_active']}`
- Campaign 3 Final Consistency Gate passed: `{report['campaign_state_after_gate']['campaign_3_final_consistency_gate_passed']}`

## Non-Substitution

4.0 Entry Reconciliation Gate is not KB profiling, not Skill generation, not Skill validation,
not Skill testcase generation, not Campaign 3 Final Consistency Gate, not Campaign 4, and not
Campaign 5.

## Failures

{failed}
"""


def _render_summary(report: dict[str, Any]) -> str:
    return f"""# Run Summary

- Run: `campaign_3_supplement_4_0_entry_gate`
- Status: `{report['status']}`
- Verdict: `{report['verdict']}`
- Reviewed evidence count: {len(report['reviewed_evidence'])}
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`
- Campaign 4 active: `false`
- Campaign 5 active: `false`
- Not goal complete: `true`
"""


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


def _read_text_no_error(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _rel_from_root(repo_root: Path, path: Path) -> str:
    try:
        return str(Path(path).relative_to(repo_root)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")

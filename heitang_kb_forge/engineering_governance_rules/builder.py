from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


ENGINEERING_GOVERNANCE_RULE_FILES = [
    "engineering_governance_manifest.json",
    "pre_code_gate_rules.json",
    "test_gate_rules.json",
    "review_gate_rules.json",
    "ai_collaboration_rules.json",
    "engineering_governance_validation_report.json",
    "engineering_governance_report.md",
]

REPOSITORY_HEAD = "694fa30311e02c2639942308513555e61ee84a6f"


def build_engineering_governance_rules(
    output: Path,
    *,
    library_name: str = "HeiTang Engineering Governance Rule Pack",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    pre_code = _pre_code_gate_rules()
    test_gate = _test_gate_rules()
    review_gate = _review_gate_rules()
    collaboration = _ai_collaboration_rules()
    manifest = {
        "schema_version": "engineering_governance_manifest.v1",
        "section": "5.13",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "mattpocock_skills",
        "project_name": "mattpocock/skills",
        "library_name": library_name,
        "integration_decision": "real_integration",
        "integration_mode": "engineering_governance_rule_pack",
        "source_verification": {
            "repository_url": "https://github.com/mattpocock/skills",
            "repository_head": REPOSITORY_HEAD,
            "default_branch": "main",
            "repository_accessible": True,
            "repository_archived": False,
            "repository_disabled": False,
            "repository_size_kb": 264,
            "license_spdx": "MIT",
            "license_file": "LICENSE",
            "license_sha": "f1dd2c09108dde1a5f56097cee8461b3ea834499",
            "repository_cloned": False,
            "external_code_copied": False,
            "external_prompt_text_copied": False,
            "external_skill_files_copied": False,
            "external_installer_executed": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "existing_capability_anchors": [
                "Project AGENTS execution discipline",
                "Post-Codex Review Gate",
                "Validation Gate Manifest",
                "Project Memory Lock and pitfall prevention",
            ],
            "distinct_value": [
                "pre-code alignment and domain-language checklist",
                "red-green-refactor test-loop rule pack",
                "finite review gate routing for P0/P1/P2 findings",
                "AI collaboration handoff and concise-context rules",
            ],
            "does_not_replace": [
                "Anything2Skill",
                "SkillX",
                "Anthropic skill-creator",
                "P2.2 Skill Governance / Skill Suite",
            ],
        },
        "runtime_boundary": _runtime_boundary(),
        "ui_contract": {
            "business_ui_required": False,
            "status_visible": True,
            "development_rules_report_visible": True,
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "ui_visibility": "visible_status_only",
            "business_workflow_entry": False,
        },
        "rule_counts": {
            "pre_code": len(pre_code["rules"]),
            "test_gate": len(test_gate["rules"]),
            "review_gate": len(review_gate["rules"]),
            "ai_collaboration": len(collaboration["rules"]),
        },
        "output_files": ENGINEERING_GOVERNANCE_RULE_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This advances Section 5 item 5.13 as local engineering governance rules only. "
            "It does not copy external Skill files, run external installers, create a business runtime, "
            "open Campaign 3 Supplements 3.0/4.0, accept Campaign 3, open Campaign 4, run Full Gate, package EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.14 Sirchmunk only.",
        "not_goal_complete": True,
    }
    validation = validate_engineering_governance_payload(
        manifest,
        pre_code,
        test_gate,
        review_gate,
        collaboration,
    )
    write_json(output / "engineering_governance_manifest.json", manifest)
    write_json(output / "pre_code_gate_rules.json", pre_code)
    write_json(output / "test_gate_rules.json", test_gate)
    write_json(output / "review_gate_rules.json", review_gate)
    write_json(output / "ai_collaboration_rules.json", collaboration)
    write_json(output / "engineering_governance_validation_report.json", validation)
    (output / "engineering_governance_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def validate_engineering_governance_rules(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in ENGINEERING_GOVERNANCE_RULE_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "engineering_governance_validation_report.v1",
            "section": "5.13",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": ENGINEERING_GOVERNANCE_RULE_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required engineering governance rule evidence is incomplete.",
            "next_required_e2e_step": "Complete Section 5 item 5.13 evidence before advancing.",
            "not_goal_complete": True,
        }
    result = validate_engineering_governance_payload(
        _read_json(library / "engineering_governance_manifest.json"),
        _read_json(library / "pre_code_gate_rules.json"),
        _read_json(library / "test_gate_rules.json"),
        _read_json(library / "review_gate_rules.json"),
        _read_json(library / "ai_collaboration_rules.json"),
    )
    return {
        **result,
        "required_files": ENGINEERING_GOVERNANCE_RULE_FILES,
        "missing_files": missing,
    }


def validate_engineering_governance_payload(
    manifest: dict[str, Any],
    pre_code: dict[str, Any],
    test_gate: dict[str, Any],
    review_gate: dict[str, Any],
    collaboration: dict[str, Any],
) -> dict[str, Any]:
    source = manifest.get("source_verification", {})
    runtime = manifest.get("runtime_boundary", {})
    ui = manifest.get("ui_contract", {})
    errors: list[str] = []
    required_false = {
        "repository_cloned": source,
        "external_code_copied": source,
        "external_prompt_text_copied": source,
        "external_skill_files_copied": source,
        "external_installer_executed": source,
        "external_runtime_integrated": runtime,
        "external_agent_skill_installed": runtime,
        "business_runtime_created": runtime,
        "agent_created_or_bound": runtime,
        "campaign_3_3_0_implemented": runtime,
        "campaign_3_4_0_implemented": runtime,
        "business_ui_required": ui,
        "business_workflow_entry": ui,
        "ready": ui,
        "executable_action": ui,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if source.get("repository_accessible") is not True:
        errors.append("repository_accessible_must_be_true")
    if source.get("license_spdx") != "MIT":
        errors.append("license_spdx_must_be_mit")
    if manifest.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if manifest.get("integration_mode") != "engineering_governance_rule_pack":
        errors.append("integration_mode_invalid")
    if ui.get("local_ready") is not True:
        errors.append("local_ready_must_be_true")
    if _rule_ids(pre_code) != {"align_scope", "map_domain_language", "define_acceptance", "record_risks"}:
        errors.append("pre_code_rules_invalid")
    if _rule_ids(test_gate) != {"red_first", "green_implementation", "refactor_with_regression", "diff_check"}:
        errors.append("test_gate_rules_invalid")
    if _rule_ids(review_gate) != {"finite_priority_review", "evidence_first", "p3_backlog_only"}:
        errors.append("review_gate_rules_invalid")
    if _rule_ids(collaboration) != {"concise_shared_language", "handoff_state", "ask_only_for_blocking_unknowns"}:
        errors.append("collaboration_rules_invalid")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "engineering_governance_validation_report.v1",
        "section": "5.13",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "repository_head": source.get("repository_head"),
        "license_spdx": source.get("license_spdx"),
        "pre_code_rule_count": len(pre_code.get("rules", [])),
        "test_gate_rule_count": len(test_gate.get("rules", [])),
        "review_gate_rule_count": len(review_gate.get("rules", [])),
        "ai_collaboration_rule_count": len(collaboration.get("rules", [])),
        "external_skill_files_copied": source.get("external_skill_files_copied"),
        "external_runtime_integrated": runtime.get("external_runtime_integrated"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation proves local engineering governance rules and negative runtime/UI boundaries only. "
            "It does not accept Campaign 3, Campaign 3 Supplements 3.0/4.0, Campaign 4, Full Gate, EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.14 Sirchmunk only.",
        "not_goal_complete": True,
    }


def write_engineering_governance_rules(
    output: Path,
    *,
    library_name: str = "HeiTang Engineering Governance Rule Pack",
) -> dict[str, Any]:
    return build_engineering_governance_rules(output, library_name=library_name)


def write_engineering_governance_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_engineering_governance_rules(library)
    write_json(output / "engineering_governance_validation_report.json", result)
    (output / "engineering_governance_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _pre_code_gate_rules() -> dict[str, Any]:
    return {
        "schema_version": "pre_code_gate_rules.v1",
        "rules": [
            {
                "rule_id": "align_scope",
                "purpose": "State the task scope, current plan item, forbidden later states, and verification target before editing.",
                "evidence_hook": "PLAN_SEQUENCE_LOCK plus task-specific tests",
            },
            {
                "rule_id": "map_domain_language",
                "purpose": "Use project vocabulary and existing module boundaries before naming new files or abstractions.",
                "evidence_hook": "PROJECT_CONTROL_INDEX and local package inspection",
            },
            {
                "rule_id": "define_acceptance",
                "purpose": "Name the smallest verifiable acceptance criteria and the focused gate before implementation.",
                "evidence_hook": "VALIDATION_GATE_MANIFEST impact rule",
            },
            {
                "rule_id": "record_risks",
                "purpose": "Record runtime, dependency, UI, release, and rollback risks for governed changes.",
                "evidence_hook": "pre_action_checkpoint and rollback_plan when risk is non-trivial",
            },
        ],
    }


def _test_gate_rules() -> dict[str, Any]:
    return {
        "schema_version": "test_gate_rules.v1",
        "rules": [
            {
                "rule_id": "red_first",
                "purpose": "When changing behavior, add or identify a failing/guarding test before broad implementation.",
                "evidence_hook": "focused pytest or UI test",
            },
            {
                "rule_id": "green_implementation",
                "purpose": "Make the narrowest implementation that satisfies the focused acceptance evidence.",
                "evidence_hook": "passing focused gate",
            },
            {
                "rule_id": "refactor_with_regression",
                "purpose": "Refactor only after behavior is covered and run the relevant regression gate.",
                "evidence_hook": "targeted regression tests",
            },
            {
                "rule_id": "diff_check",
                "purpose": "Finish with whitespace/path-boundary validation for touched repos.",
                "evidence_hook": "git diff --check",
            },
        ],
    }


def _review_gate_rules() -> dict[str, Any]:
    return {
        "schema_version": "review_gate_rules.v1",
        "rules": [
            {
                "rule_id": "finite_priority_review",
                "purpose": "Review only P0/P1/P2 blockers for task closure; P3 becomes backlog.",
                "evidence_hook": "Post-Codex Review Gate",
            },
            {
                "rule_id": "evidence_first",
                "purpose": "Findings require file, command, or artifact evidence before they block progress.",
                "evidence_hook": "review report with source references",
            },
            {
                "rule_id": "p3_backlog_only",
                "purpose": "Low-value polishing must not expand scope or delay the locked plan sequence.",
                "evidence_hook": "review stop condition",
            },
        ],
    }


def _ai_collaboration_rules() -> dict[str, Any]:
    return {
        "schema_version": "ai_collaboration_rules.v1",
        "rules": [
            {
                "rule_id": "concise_shared_language",
                "purpose": "Prefer project terms and short status updates over re-explaining stable context.",
                "evidence_hook": "PROJECT_CONTROL_INDEX and HANDOFF",
            },
            {
                "rule_id": "handoff_state",
                "purpose": "Long work must leave current item, evidence root, validation, and next item in project memory.",
                "evidence_hook": "current_status, HANDOFF, and task_log",
            },
            {
                "rule_id": "ask_only_for_blocking_unknowns",
                "purpose": "Continue automatically inside authorized project scope and ask only for missing secrets, irreversible external risk, or true impasse.",
                "evidence_hook": "Full Access Execution Policy",
            },
        ],
    }


def _runtime_boundary() -> dict[str, Any]:
    return {
        "external_runtime_integrated": False,
        "external_agent_skill_installed": False,
        "external_installer_executed": False,
        "business_runtime_created": False,
        "agent_created_or_bound": False,
        "campaign_3_3_0_implemented": False,
        "campaign_3_4_0_implemented": False,
        "workspace_global_rule_modified": False,
        "local_rule_pack_only": True,
    }


def _rule_ids(payload: dict[str, Any]) -> set[str]:
    return {str(item.get("rule_id")) for item in payload.get("rules", [])}


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    counts = manifest["rule_counts"]
    return f"""# Engineering Governance Rule Pack

- Status: {validation['status']}
- Integration decision: {manifest['integration_decision']}
- Integration mode: {manifest['integration_mode']}
- Repository head: {manifest['source_verification']['repository_head']}
- License: {manifest['source_verification']['license_spdx']}
- Pre-code rules: {counts['pre_code']}
- Test gate rules: {counts['test_gate']}
- Review gate rules: {counts['review_gate']}
- AI collaboration rules: {counts['ai_collaboration']}
- External Skill files copied: {manifest['source_verification']['external_skill_files_copied']}
- External runtime integrated: {manifest['runtime_boundary']['external_runtime_integrated']}
- Business UI required: {manifest['ui_contract']['business_ui_required']}

This is a local engineering governance strengthening. It does not install or copy mattpocock/skills, expose a business runtime, or create/bind/execute an Agent.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# Engineering Governance Validation

- Status: {result['status']}
- Boundary errors: {len(result['boundary_errors'])}
- Pre-code rules: {result.get('pre_code_rule_count', 0)}
- Test gate rules: {result.get('test_gate_rule_count', 0)}
- Review gate rules: {result.get('review_gate_rule_count', 0)}
- AI collaboration rules: {result.get('ai_collaboration_rule_count', 0)}
- External runtime integrated: {result.get('external_runtime_integrated')}
"""

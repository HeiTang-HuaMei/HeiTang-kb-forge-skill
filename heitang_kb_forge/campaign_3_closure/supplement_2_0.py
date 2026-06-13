from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


@dataclass(frozen=True)
class ClosureItem:
    item_id: str
    run_id: str
    expected_decision: str
    decision_file: str
    ui_file: str
    scope: str


CAMPAIGN_3_SUPPLEMENT_2_0_ITEMS = [
    ClosureItem(
        "5.7",
        "ai_marketing_skills_pattern_library",
        "real_integration",
        "ai_marketing_skills_integration_decision_report.json",
        "ai_marketing_skills_ui_impact_note.json",
        "SECTION_5_ITEM_5_7_AI_MARKETING_SKILLS",
    ),
    ClosureItem(
        "5.8",
        "ai_money_maker_handbook_business_scenario_library",
        "real_integration",
        "ai_money_maker_handbook_integration_decision_report.json",
        "ai_money_maker_handbook_ui_impact_note.json",
        "SECTION_5_ITEM_5_8_AI_MONEY_MAKER_HANDBOOK",
    ),
    ClosureItem(
        "5.9",
        "jellyfish_content_asset_schema",
        "reference_only",
        "jellyfish_integration_decision_report.json",
        "jellyfish_ui_impact_note.json",
        "SECTION_5_ITEM_5_9_JELLYFISH",
    ),
    ClosureItem(
        "5.10",
        "story_flicks_video_pipeline_schema",
        "reference_only",
        "story_flicks_integration_decision_report.json",
        "story_flicks_ui_impact_note.json",
        "SECTION_5_ITEM_5_10_STORY_FLICKS",
    ),
    ClosureItem(
        "5.11",
        "seedance2_skill_template_metadata",
        "reference_only",
        "seedance2_skill_integration_decision_report.json",
        "seedance2_skill_ui_impact_note.json",
        "SECTION_5_ITEM_5_11_SEEDANCE2_SKILL",
    ),
    ClosureItem(
        "5.12",
        "rag_anything_cross_modal_rag_schema",
        "reference_only",
        "rag_anything_integration_decision_report.json",
        "rag_anything_ui_impact_note.json",
        "SECTION_5_ITEM_5_12_RAG_ANYTHING",
    ),
    ClosureItem(
        "5.13",
        "mattpocock_skills_engineering_governance",
        "real_integration",
        "mattpocock_skills_integration_decision_report.json",
        "mattpocock_skills_ui_impact_note.json",
        "SECTION_5_ITEM_5_13_MATTPOCOCK_SKILLS",
    ),
    ClosureItem(
        "5.14",
        "sirchmunk_direct_file_search",
        "real_integration",
        "sirchmunk_integration_decision_report.json",
        "sirchmunk_ui_impact_note.json",
        "SECTION_5_ITEM_5_14_SIRCHMUNK",
    ),
    ClosureItem(
        "5.S1",
        "gbrain_memory_profile_kg_strengthening",
        "needs_strengthening",
        "gbrain_integration_decision_report.json",
        "gbrain_ui_impact_note.json",
        "SECTION_5_STRENGTHENING_5_S1_GBRAIN",
    ),
    ClosureItem(
        "5.S2",
        "horizon_topic_intake_strengthening",
        "real_integration",
        "horizon_integration_decision_report.json",
        "horizon_ui_impact_note.json",
        "SECTION_5_STRENGTHENING_5_S2_HORIZON",
    ),
    ClosureItem(
        "5.S3",
        "obsidian_vault_strengthening",
        "real_integration",
        "obsidian_vault_integration_decision_report.json",
        "obsidian_vault_ui_impact_note.json",
        "SECTION_5_STRENGTHENING_5_S3_OBSIDIAN_COMPATIBLE_VAULT",
    ),
]


def build_campaign_3_supplement_2_0_closure_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    section_root = repo_root / "artifacts" / "audits" / "section_5"
    item_results = [_review_item(section_root, item) for item in CAMPAIGN_3_SUPPLEMENT_2_0_ITEMS]
    failures = [
        error
        for result in item_results
        for error in result["errors"]
    ]
    passed = not failures
    return {
        "schema_version": "campaign_3_supplement_2_0_closure_gate.v1",
        "generated_at": "2026-06-13T00:00:00+08:00",
        "campaign": "Campaign 3",
        "supplement": "2.0 capability-domain deduplication and strengthening",
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_transition_to_campaign_3_3_0_entry_gate" if passed else "failed",
        "reviewed_item_count": len(item_results),
        "required_item_count": len(CAMPAIGN_3_SUPPLEMENT_2_0_ITEMS),
        "items": item_results,
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_gate": {
            "campaign_3_supplement_2_0_closure_gate_passed": passed,
            "campaign_3_accepted": False,
            "campaign_3_3_0_active": False,
            "campaign_3_4_0_active": False,
            "campaign_4_allowed": False,
            "next_business_item": (
                "Campaign 3 Supplement 3.0 Entry Gate"
                if passed
                else "Repair Campaign 3 Supplement 2.0 closure gate evidence"
            ),
        },
        "non_substitution_rules": {
            "closure_gate_accepts_campaign_3": False,
            "closure_gate_starts_campaign_3_3_0_business_implementation": False,
            "closure_gate_starts_campaign_3_4_0": False,
            "closure_gate_opens_campaign_4": False,
            "integration_decision_substitutes_ui_impact": False,
            "focused_tests_substitute_full_gate": False,
        },
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Campaign 3 Supplement 3.0, Campaign 3 Supplement 4.0, expanded Campaign 3 final "
            "consistency gate, Campaign 4 UI industrial acceptance, Core Bridge acceptance, "
            "configuration, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": (
            "Run Campaign 3 Supplement 3.0 Entry Gate only."
            if passed
            else "Repair Campaign 3 Supplement 2.0 closure gate evidence."
        ),
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_2_0_closure_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_2_0_closure_gate(repo_root)
    write_json(output / "campaign_3_supplement_2_0_closure_gate.json", report)
    write_json(output / "run_manifest.json", _run_manifest(report))
    (output / "campaign_3_supplement_2_0_closure_gate.md").write_text(
        _render_report(report),
        encoding="utf-8",
    )
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def _review_item(section_root: Path, item: ClosureItem) -> dict[str, Any]:
    run_dir = section_root / item.run_id
    run_manifest_path = run_dir / "run_manifest.json"
    decision_path = run_dir / item.decision_file
    ui_path = run_dir / item.ui_file
    errors: list[str] = []
    run_manifest = _read_json(run_manifest_path, errors, f"{item.item_id}_run_manifest")
    decision = _read_json(decision_path, errors, f"{item.item_id}_decision")
    ui = _read_json(ui_path, errors, f"{item.item_id}_ui_impact")
    decision_value = decision.get("decision") or decision.get("integration_decision")
    run_decision = run_manifest.get("integration_decision")
    ui_decision = (
        ui.get("decision")
        or ui.get("integration_decision")
        or _decision_from_ui_markers(ui)
    )
    if run_manifest.get("status") != "passed":
        errors.append(f"{item.item_id}_run_manifest_status_not_passed")
    if run_manifest.get("scope") != item.scope:
        errors.append(f"{item.item_id}_scope_mismatch")
    if decision_value != item.expected_decision:
        errors.append(f"{item.item_id}_decision_mismatch")
    if run_decision != item.expected_decision:
        errors.append(f"{item.item_id}_run_manifest_decision_mismatch")
    if ui_decision != item.expected_decision:
        errors.append(f"{item.item_id}_ui_decision_mismatch")
    for name, payload in [
        ("run_manifest", run_manifest),
        ("decision", decision),
        ("ui_impact", ui),
    ]:
        if payload.get("final_target_not_downgraded") is not True:
            errors.append(f"{item.item_id}_{name}_missing_final_target_not_downgraded")
        if payload.get("not_goal_complete") is not True:
            errors.append(f"{item.item_id}_{name}_missing_not_goal_complete")
        if not str(payload.get("remaining_gap", "")).strip():
            errors.append(f"{item.item_id}_{name}_missing_remaining_gap")
        if not str(payload.get("next_required_e2e_step", "")).strip():
            errors.append(f"{item.item_id}_{name}_missing_next_required_e2e_step")
    state = run_manifest.get("campaign_state_after_run", {})
    if state.get("campaign_3_accepted") is not False:
        errors.append(f"{item.item_id}_campaign_3_accepted_overclaim")
    if state.get("campaign_3_3_0_active") is True:
        errors.append(f"{item.item_id}_campaign_3_3_0_active_overclaim")
    if state.get("campaign_3_4_0_active") is True:
        errors.append(f"{item.item_id}_campaign_3_4_0_active_overclaim")
    if state.get("campaign_4_allowed") is not False:
        errors.append(f"{item.item_id}_campaign_4_allowed_overclaim")
    return {
        "item_id": item.item_id,
        "run_id": item.run_id,
        "scope": item.scope,
        "status": "passed" if not errors else "failed",
        "expected_decision": item.expected_decision,
        "decision": decision_value,
        "decision_qualifier": decision.get("decision_qualifier")
        or run_manifest.get("decision_qualifier"),
        "run_manifest": _rel(run_manifest_path),
        "integration_decision_report": _rel(decision_path),
        "ui_impact_note": _rel(ui_path),
        "campaign_3_accepted": state.get("campaign_3_accepted"),
        "campaign_3_3_0_active": state.get("campaign_3_3_0_active"),
        "campaign_3_4_0_active": state.get("campaign_3_4_0_active"),
        "campaign_4_allowed": state.get("campaign_4_allowed"),
        "errors": errors,
    }


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"{label}_missing")
        return {}
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _decision_from_ui_markers(ui: dict[str, Any]) -> str | None:
    markers = {
        str(value)
        for key in ("ui_may_show", "ui_should_show")
        for value in ui.get(key, [])
    }
    for decision in ["real_integration", "reference_only", "needs_strengthening", "stop_integration"]:
        if decision in markers:
            return decision
    return None


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "campaign_3_supplement_2_0_closure_gate",
        "generated_at": report["generated_at"],
        "type": "campaign_supplement_closure_gate",
        "scope": "CAMPAIGN_3_SUPPLEMENT_2_0_CLOSURE_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "evidence_files": [
            "campaign_3_supplement_2_0_closure_gate.json",
            "campaign_3_supplement_2_0_closure_gate.md",
            "run_summary.md",
        ],
        "campaign_state_after_run": report["campaign_state_after_gate"],
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": report["final_target_not_downgraded"],
        "remaining_gap": report["remaining_gap"],
        "next_required_e2e_step": report["next_required_e2e_step"],
        "not_goal_complete": report["not_goal_complete"],
    }


def _render_report(report: dict[str, Any]) -> str:
    rows = [
        "| Item | Run | Decision | Status |",
        "| --- | --- | --- | --- |",
    ]
    for item in report["items"]:
        rows.append(
            f"| {item['item_id']} | `{item['run_id']}` | `{item['decision']}` | `{item['status']}` |"
        )
    failures = "\n".join(f"- {failure}" for failure in report["failures"]) or "- None"
    return (
        "# Campaign 3 Supplement 2.0 Closure Gate\n\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Status: `{report['status']}`\n"
        f"- Reviewed items: {report['reviewed_item_count']} / {report['required_item_count']}\n"
        "- Boundary: this gate closes Supplement 2.0 only; it does not accept Campaign 3, start Supplement 3.0 business work, open Campaign 4, run Full Gate, package EXE, or release.\n\n"
        + "\n".join(rows)
        + "\n\n## Failures\n\n"
        + failures
        + "\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 3 Supplement 2.0 Closure Summary\n\n"
        f"Closure gate status: `{report['status']}`. "
        f"Reviewed {report['reviewed_item_count']} required Section 5 2.0 items. "
        "The gate only permits the next sequence item to be Campaign 3 Supplement 3.0 Entry Gate; it does not mark Campaign 3 accepted or open Campaign 4.\n\n"
        f"Next required E2E step: `{report['next_required_e2e_step']}`\n"
    )


def _rel(path: Path) -> str:
    return path.as_posix()

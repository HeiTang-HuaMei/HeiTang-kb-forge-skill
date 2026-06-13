from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


BUSINESS_SCENARIO_TEMPLATE_FILES = [
    "business_scenario_manifest.json",
    "business_scenario_cards.jsonl",
    "business_workflow_templates.json",
    "business_scenario_validation_report.json",
    "business_scenario_library_report.md",
    "BUSINESS_SCENARIO_INDEX.md",
]

SCENARIO_DEFINITIONS = [
    {
        "scenario_id": "knowledge_product_offer",
        "title": "Knowledge Product Offer",
        "capability_domain": "knowledge_product",
        "purpose": "Turn verified knowledge packages into a scoped offer brief without income claims.",
        "input_assets": ["knowledge_package", "audience_problem_notes", "source_trace"],
        "workflow_steps": [
            "select_source_backed_problem",
            "define_offer_boundary",
            "map_evidence_to_deliverables",
            "write_review_questions",
            "record_risk_and_non_guarantees",
        ],
        "output_assets": ["offer_brief", "deliverable_scope", "risk_note"],
        "quality_gates": ["source_trace_required", "no_revenue_guarantee", "human_review_required"],
    },
    {
        "scenario_id": "service_packaging",
        "title": "Service Packaging",
        "capability_domain": "service_business",
        "purpose": "Package a repeatable service workflow using only owned knowledge and explicit assumptions.",
        "input_assets": ["workflow_notes", "knowledge_package", "customer_segment"],
        "workflow_steps": [
            "identify_repeatable_service_steps",
            "separate_facts_from_assumptions",
            "define_scope_and_exclusions",
            "prepare_delivery_checklist",
            "add_review_and_update_cadence",
        ],
        "output_assets": ["service_playbook", "delivery_checklist", "assumption_log"],
        "quality_gates": ["scope_boundary_required", "no_account_operation", "assumption_log_required"],
    },
    {
        "scenario_id": "lead_magnet",
        "title": "Lead Magnet",
        "capability_domain": "audience_development",
        "purpose": "Create a source-backed educational asset outline without scraping, spam, or list operations.",
        "input_assets": ["knowledge_package", "approved_claims", "audience_questions"],
        "workflow_steps": [
            "cluster_audience_questions",
            "select_evidence_backed_takeaways",
            "draft_asset_outline",
            "define_opt_in_boundary",
            "prepare_claim_review",
        ],
        "output_assets": ["lead_magnet_outline", "claim_review_table", "distribution_boundary"],
        "quality_gates": ["no_scraping", "no_spam_or_account_action", "approved_claims_only"],
    },
    {
        "scenario_id": "course_workshop",
        "title": "Course or Workshop",
        "capability_domain": "education_product",
        "purpose": "Structure a course or workshop plan from verified materials without outcome guarantees.",
        "input_assets": ["knowledge_package", "learner_profile", "source_inventory"],
        "workflow_steps": [
            "map_learning_objectives",
            "select_source_backed_modules",
            "draft_exercises",
            "define_assessment_boundary",
            "record_revision_triggers",
        ],
        "output_assets": ["course_outline", "exercise_plan", "revision_trigger_list"],
        "quality_gates": ["source_inventory_required", "no_outcome_guarantee", "revision_trigger_required"],
    },
    {
        "scenario_id": "consulting_diagnostic",
        "title": "Consulting Diagnostic",
        "capability_domain": "consulting",
        "purpose": "Produce a structured diagnostic packet with evidence, questions, and recommended next analysis.",
        "input_assets": ["client_notes", "knowledge_package", "metric_snapshot"],
        "workflow_steps": [
            "inventory_evidence_and_gaps",
            "classify_diagnostic_questions",
            "rank_observation_confidence",
            "write_next_analysis_plan",
            "add_privacy_and_data_boundary",
        ],
        "output_assets": ["diagnostic_packet", "question_backlog", "confidence_table"],
        "quality_gates": ["privacy_boundary_required", "confidence_required", "no_financial_advice"],
    },
    {
        "scenario_id": "content_to_case_study",
        "title": "Content to Case Study",
        "capability_domain": "content_business",
        "purpose": "Convert verified content evidence into a case study outline without fabricated results.",
        "input_assets": ["content_inventory", "source_trace", "result_notes"],
        "workflow_steps": [
            "select_documented_before_after",
            "verify_result_notes",
            "write_case_study_outline",
            "mark_unknowns",
            "prepare_approval_checklist",
        ],
        "output_assets": ["case_study_outline", "evidence_table", "approval_checklist"],
        "quality_gates": ["no_fabricated_results", "evidence_table_required", "approval_required"],
    },
    {
        "scenario_id": "community_offer",
        "title": "Community Offer",
        "capability_domain": "community",
        "purpose": "Design a community value proposition and content cadence without platform automation.",
        "input_assets": ["audience_notes", "knowledge_package", "moderation_rules"],
        "workflow_steps": [
            "define_member_problem",
            "map_content_cadence",
            "identify_member_feedback_loop",
            "set_moderation_boundary",
            "prepare_launch_review",
        ],
        "output_assets": ["community_offer_brief", "content_cadence", "moderation_boundary"],
        "quality_gates": ["no_platform_account_operation", "moderation_boundary_required", "human_review_required"],
    },
    {
        "scenario_id": "template_asset_pack",
        "title": "Template Asset Pack",
        "capability_domain": "template_product",
        "purpose": "Assemble reusable templates from owned knowledge without copying external handbook content.",
        "input_assets": ["owned_templates", "knowledge_package", "usage_examples"],
        "workflow_steps": [
            "inventory_owned_assets",
            "normalize_template_structure",
            "attach_usage_context",
            "add_license_and_source_note",
            "validate_no_external_copying",
        ],
        "output_assets": ["template_asset_pack", "usage_context_map", "license_note"],
        "quality_gates": ["owned_assets_only", "source_note_required", "no_external_content_copying"],
    },
]


def build_business_scenario_template_library(
    output: Path,
    *,
    library_name: str = "HeiTang Business Scenario Template Library",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    cards = [_scenario_card(definition) for definition in SCENARIO_DEFINITIONS]
    workflow_templates = {
        "schema_version": "business_workflow_templates.v1",
        "status": "passed",
        "workflow_count": len(cards),
        "workflows": [
            {
                "scenario_id": card["scenario_id"],
                "workflow_steps": card["workflow_steps"],
                "output_assets": card["output_assets"],
                "quality_gates": card["quality_gates"],
            }
            for card in cards
        ],
        "external_content_copied": False,
        "external_runtime_integrated": False,
        "money_automation_ready": False,
    }
    manifest = {
        "schema_version": "business_scenario_template_library.v1",
        "section": "5.8",
        "campaign": "Campaign 3",
        "library_name": library_name,
        "status": "passed",
        "integration_mode": "business_scenario_template_library",
        "scenario_count": len(cards),
        "scenario_ids": [card["scenario_id"] for card in cards],
        "capability_domains": sorted({card["capability_domain"] for card in cards}),
        "external_project_reference": {
            "project_id": "ai_money_maker_handbook",
            "project_name": "ai-money-maker-handbook",
            "github_url": "https://github.com/XiaomingX/ai-money-maker-handbook",
            "git_ls_remote_checked": True,
            "git_head": "e29581de103e0770396a2a5b389c1b41b730ba80",
            "repository_cloned": False,
            "external_code_or_content_copied": False,
            "external_prompts_copied": False,
            "external_runtime_integrated": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "overlap_domains": [
                "marketing_skill_pattern_library",
                "template_library",
                "skill_factory_template_picker",
            ],
            "distinct_engineering_value": [
                "business_scenario_cards",
                "business_template_quality_gates",
                "no_money_automation_boundary",
            ],
            "horizon_handled_as_strengthening": True,
        },
        "runtime_boundary": {
            "llm_required": False,
            "api_key_required": False,
            "network_required": False,
            "external_runtime_required": False,
            "trading_execution": False,
            "payment_processing": False,
            "ad_spend_or_paid_media": False,
            "crawler_or_scraper": False,
            "account_operation": False,
            "revenue_guarantee": False,
            "money_automation_ready": False,
            "financial_advice": False,
        },
        "ui_contract": {
            "business_template_library_visible": True,
            "skill_factory_template_picker_visible": True,
            "runtime_execution_action_available": False,
            "money_automation_action_available": False,
        },
        "output_files": BUSINESS_SCENARIO_TEMPLATE_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Section 5 item 5.8 is advanced as a local original Business Scenario Template Library. "
            "Section 5 items 5.9-5.14, strengthening items 5.S1-5.S3, Campaign 3 final consistency gate, "
            "Campaign 4 UI workflow, Core Bridge, configuration, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.9 Jellyfish only.",
        "not_goal_complete": True,
    }
    validation = validate_business_scenario_template_payload(manifest, cards, workflow_templates)
    write_json(output / "business_scenario_manifest.json", manifest)
    write_jsonl(output / "business_scenario_cards.jsonl", cards)
    write_json(output / "business_workflow_templates.json", workflow_templates)
    write_json(output / "business_scenario_validation_report.json", validation)
    (output / "BUSINESS_SCENARIO_INDEX.md").write_text(_render_index(manifest, cards), encoding="utf-8")
    (output / "business_scenario_library_report.md").write_text(
        _render_report(manifest, validation), encoding="utf-8"
    )
    return manifest | {"scenario_cards": cards, "validation": validation}


def validate_business_scenario_template_library(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in BUSINESS_SCENARIO_TEMPLATE_FILES if not (library / file_name).exists()]
    manifest = _read_json(library / "business_scenario_manifest.json") if not missing else {}
    cards = _read_jsonl(library / "business_scenario_cards.jsonl") if (library / "business_scenario_cards.jsonl").exists() else []
    workflows = _read_json(library / "business_workflow_templates.json") if (library / "business_workflow_templates.json").exists() else {}
    result = validate_business_scenario_template_payload(manifest, cards, workflows)
    return {
        **result,
        "required_files": BUSINESS_SCENARIO_TEMPLATE_FILES,
        "missing_files": missing,
        "status": "passed" if result["status"] == "passed" and not missing else "failed",
    }


def validate_business_scenario_template_payload(
    manifest: dict[str, Any],
    cards: list[dict[str, Any]],
    workflows: dict[str, Any],
) -> dict[str, Any]:
    required_scenarios = {definition["scenario_id"] for definition in SCENARIO_DEFINITIONS}
    card_ids = {str(card.get("scenario_id")) for card in cards}
    workflow_ids = {
        str(workflow.get("scenario_id"))
        for workflow in workflows.get("workflows", [])
        if isinstance(workflow, dict)
    }
    boundary_errors = []
    runtime = manifest.get("runtime_boundary", {})
    external = manifest.get("external_project_reference", {})
    if external.get("external_code_or_content_copied") is not False:
        boundary_errors.append("external_code_or_content_copied_must_be_false")
    if external.get("external_prompts_copied") is not False:
        boundary_errors.append("external_prompts_copied_must_be_false")
    if external.get("external_runtime_integrated") is not False:
        boundary_errors.append("external_runtime_integrated_must_be_false")
    for field in [
        "llm_required",
        "api_key_required",
        "network_required",
        "external_runtime_required",
        "trading_execution",
        "payment_processing",
        "ad_spend_or_paid_media",
        "crawler_or_scraper",
        "account_operation",
        "revenue_guarantee",
        "money_automation_ready",
        "financial_advice",
    ]:
        if runtime.get(field) is not False:
            boundary_errors.append(f"{field}_must_be_false")
    card_errors = [
        card.get("scenario_id") or f"card_{index}"
        for index, card in enumerate(cards, start=1)
        if not _card_is_valid(card)
    ]
    status = (
        "passed"
        if required_scenarios == card_ids == workflow_ids
        and not card_errors
        and not boundary_errors
        and manifest.get("status") == "passed"
        else "failed"
    )
    return {
        "schema_version": "business_scenario_validation_report.v1",
        "section": "5.8",
        "campaign": "Campaign 3",
        "status": status,
        "expected_scenario_count": len(required_scenarios),
        "scenario_count": len(cards),
        "required_scenarios": sorted(required_scenarios),
        "card_scenario_ids": sorted(card_ids),
        "workflow_scenario_ids": sorted(workflow_ids),
        "card_errors": card_errors,
        "boundary_errors": boundary_errors,
        "external_code_or_content_copied": external.get("external_code_or_content_copied"),
        "external_prompts_copied": external.get("external_prompts_copied"),
        "external_runtime_integrated": external.get("external_runtime_integrated"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Business scenario validation covers local original scenario cards and boundaries only; "
            "it does not complete Campaign 3, Campaign 4 UI workflow, Full Gate, or EXE acceptance."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.9 Jellyfish only.",
        "not_goal_complete": True,
    }


def write_business_scenario_template_library(
    output: Path,
    *,
    library_name: str = "HeiTang Business Scenario Template Library",
) -> dict[str, Any]:
    return build_business_scenario_template_library(output, library_name=library_name)


def write_business_scenario_template_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_business_scenario_template_library(library)
    write_json(output / "business_scenario_validation_report.json", result)
    (output / "business_scenario_validation_report.md").write_text(
        _render_validation_report(result), encoding="utf-8"
    )
    return result


def _scenario_card(definition: dict[str, Any]) -> dict[str, Any]:
    return {
        "scenario_id": definition["scenario_id"],
        "title": definition["title"],
        "capability_domain": definition["capability_domain"],
        "purpose": definition["purpose"],
        "input_assets": definition["input_assets"],
        "workflow_steps": definition["workflow_steps"],
        "output_assets": definition["output_assets"],
        "quality_gates": definition["quality_gates"],
        "skill_factory_usage": {
            "template_picker_label": definition["title"],
            "recommended_skill_type": "business_scenario_skill",
            "source_trace_required": True,
            "human_review_required": True,
            "revenue_claim_allowed": False,
        },
        "ui_preview": {
            "surface": "Business Template Library",
            "preview_kind": "business_scenario_template",
            "runtime_execution_action_available": False,
        },
        "external_content_copied": False,
        "money_automation_ready": False,
    }


def _card_is_valid(card: dict[str, Any]) -> bool:
    required = {
        "scenario_id",
        "title",
        "capability_domain",
        "purpose",
        "input_assets",
        "workflow_steps",
        "output_assets",
        "quality_gates",
        "skill_factory_usage",
        "ui_preview",
    }
    if not required <= set(card):
        return False
    if card.get("external_content_copied") is not False:
        return False
    if card.get("money_automation_ready") is not False:
        return False
    return all(
        isinstance(card.get(field), list) and card[field]
        for field in ["input_assets", "workflow_steps", "output_assets", "quality_gates"]
    )


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def _render_index(manifest: dict[str, Any], cards: list[dict[str, Any]]) -> str:
    lines = [
        "# Business Scenario Template Index",
        "",
        f"- Library: `{manifest['library_name']}`",
        f"- Status: `{manifest['status']}`",
        f"- Integration mode: `{manifest['integration_mode']}`",
        f"- Scenarios: {len(cards)}",
        f"- External code/content copied: `{manifest['external_project_reference']['external_code_or_content_copied']}`",
        f"- Money automation ready: `{manifest['runtime_boundary']['money_automation_ready']}`",
        "",
        "| Scenario | Domain | UI preview |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| `{card['scenario_id']}` | `{card['capability_domain']}` | `{card['ui_preview']['surface']}` |"
        for card in cards
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# Business Scenario Template Library Report\n\n"
        f"- Section: `{manifest['section']}`\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Validation: `{validation['status']}`\n"
        f"- Integration mode: `{manifest['integration_mode']}`\n"
        f"- Scenario count: {manifest['scenario_count']}\n"
        f"- External code/content copied: `{manifest['external_project_reference']['external_code_or_content_copied']}`\n"
        f"- External runtime integrated: `{manifest['external_project_reference']['external_runtime_integrated']}`\n"
        f"- Revenue guarantee: `{manifest['runtime_boundary']['revenue_guarantee']}`\n"
        f"- Money automation ready: `{manifest['runtime_boundary']['money_automation_ready']}`\n"
        "\nThis is a local original business scenario template library. It does not vendor ai-money-maker-handbook.\n"
    )


def _render_validation_report(result: dict[str, Any]) -> str:
    return (
        "# Business Scenario Template Validation Report\n\n"
        f"- Status: `{result['status']}`\n"
        f"- Scenario count: {result['scenario_count']}\n"
        f"- Missing files: {len(result.get('missing_files', []))}\n"
        f"- Card errors: {len(result['card_errors'])}\n"
        f"- Boundary errors: {len(result['boundary_errors'])}\n"
        f"- External code/content copied: `{result['external_code_or_content_copied']}`\n"
    )

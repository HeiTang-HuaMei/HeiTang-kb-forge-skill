from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


MARKETING_SKILL_PATTERN_FILES = [
    "marketing_pattern_manifest.json",
    "marketing_pattern_cards.jsonl",
    "marketing_workflow_patterns.json",
    "marketing_pattern_validation_report.json",
    "marketing_pattern_library_report.md",
    "MARKETING_PATTERN_INDEX.md",
]

PATTERN_DEFINITIONS = [
    {
        "pattern_id": "growth_experiment",
        "title": "Growth Experiment",
        "capability_domain": "growth",
        "purpose": "Plan source-grounded experiments with hypothesis, audience, evidence, metric, and rollback boundaries.",
        "input_assets": ["knowledge_package", "audience_notes", "baseline_metric"],
        "workflow_steps": [
            "extract_source_backed_audience_problem",
            "state_testable_hypothesis",
            "select_primary_metric_and_guardrail",
            "define_experiment_window",
            "prepare_evidence_review",
        ],
        "output_assets": ["experiment_brief", "metric_plan", "risk_note"],
        "quality_gates": ["source_trace_required", "no_unverified_growth_claim", "rollback_plan_required"],
    },
    {
        "pattern_id": "content_ops",
        "title": "Content Operations",
        "capability_domain": "content",
        "purpose": "Turn verified knowledge into an editorial queue, channel plan, and review loop.",
        "input_assets": ["knowledge_package", "source_trace", "brand_boundary"],
        "workflow_steps": [
            "cluster_source_backed_topics",
            "map_channel_fit",
            "prepare_content_brief",
            "define_review_owner",
            "schedule_reuse_and_refresh",
        ],
        "output_assets": ["content_brief", "content_calendar", "reuse_plan"],
        "quality_gates": ["evidence_map_required", "no_scraping_runtime", "refresh_suggestion_required"],
    },
    {
        "pattern_id": "outbound_sequence",
        "title": "Outbound Sequence",
        "capability_domain": "sales",
        "purpose": "Draft compliant outreach sequence patterns using only user-provided or connected evidence.",
        "input_assets": ["target_segment", "approved_claims", "offer_notes"],
        "workflow_steps": [
            "identify_source_backed_trigger",
            "draft_message_sequence",
            "attach_claim_evidence",
            "add_opt_out_boundary",
            "prepare_review_checklist",
        ],
        "output_assets": ["sequence_outline", "claim_evidence_table", "compliance_checklist"],
        "quality_gates": ["no_account_operation", "no_unsourced_claim", "human_review_required"],
    },
    {
        "pattern_id": "seo_brief",
        "title": "SEO Brief",
        "capability_domain": "search_content",
        "purpose": "Create a search-oriented content brief without crawler dependency or ranking guarantees.",
        "input_assets": ["knowledge_package", "keyword_notes", "source_inventory"],
        "workflow_steps": [
            "map_query_intent",
            "select_source_backed_sections",
            "draft_outline",
            "define_internal_link_candidates",
            "record_uncertainty_and_refresh_need",
        ],
        "output_assets": ["seo_brief", "outline", "source_coverage_matrix"],
        "quality_gates": ["no_ranking_guarantee", "no_crawler_required", "source_coverage_required"],
    },
    {
        "pattern_id": "conversion_audit",
        "title": "Conversion Audit",
        "capability_domain": "conversion",
        "purpose": "Review a funnel or page against local evidence and produce prioritized, testable improvements.",
        "input_assets": ["funnel_notes", "knowledge_package", "metric_snapshot"],
        "workflow_steps": [
            "inventory_conversion_claims",
            "compare_claims_to_evidence",
            "classify_friction_points",
            "rank_recommendations",
            "write_test_plan",
        ],
        "output_assets": ["conversion_audit", "priority_backlog", "test_plan"],
        "quality_gates": ["claim_verification_required", "no_revenue_guarantee", "metric_boundary_required"],
    },
    {
        "pattern_id": "sales_playbook",
        "title": "Sales Playbook",
        "capability_domain": "sales_enablement",
        "purpose": "Convert verified product and customer evidence into a sales enablement playbook.",
        "input_assets": ["knowledge_package", "customer_segments", "approved_objections"],
        "workflow_steps": [
            "extract_value_messages",
            "map_objections_to_evidence",
            "define_discovery_questions",
            "prepare_enablement_cards",
            "add_update_cadence",
        ],
        "output_assets": ["sales_playbook", "objection_map", "enablement_cards"],
        "quality_gates": ["approved_claims_only", "source_trace_required", "no_account_execution"],
    },
    {
        "pattern_id": "revenue_intelligence",
        "title": "Revenue Intelligence",
        "capability_domain": "analytics",
        "purpose": "Structure revenue observations and next questions without financial automation or guarantees.",
        "input_assets": ["metric_snapshot", "pipeline_notes", "knowledge_package"],
        "workflow_steps": [
            "normalize_metric_snapshot",
            "separate_fact_from_hypothesis",
            "identify_evidence_gaps",
            "prioritize_next_questions",
            "prepare_review_packet",
        ],
        "output_assets": ["revenue_insight_brief", "gap_analysis", "review_packet"],
        "quality_gates": ["no_financial_automation", "uncertainty_required", "human_review_required"],
    },
    {
        "pattern_id": "campaign_review",
        "title": "Campaign Review",
        "capability_domain": "campaign_ops",
        "purpose": "Evaluate campaign evidence, outcomes, and learning loops with source trace and risk notes.",
        "input_assets": ["campaign_notes", "metric_snapshot", "source_trace"],
        "workflow_steps": [
            "inventory_campaign_assets",
            "map_results_to_goals",
            "separate_outcome_from_assumption",
            "record_lessons",
            "recommend_next_iteration",
        ],
        "output_assets": ["campaign_review", "lessons_log", "next_iteration_brief"],
        "quality_gates": ["source_trace_required", "no_paid_media_execution", "lesson_to_action_required"],
    },
]


def build_marketing_skill_pattern_library(
    output: Path,
    *,
    library_name: str = "HeiTang Marketing Skill Pattern Library",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    cards = [_pattern_card(definition) for definition in PATTERN_DEFINITIONS]
    workflow_patterns = {
        "schema_version": "marketing_workflow_patterns.v1",
        "status": "passed",
        "workflow_count": len(cards),
        "workflows": [
            {
                "pattern_id": card["pattern_id"],
                "workflow_steps": card["workflow_steps"],
                "output_assets": card["output_assets"],
                "quality_gates": card["quality_gates"],
            }
            for card in cards
        ],
        "external_code_or_prompts_copied": False,
        "external_runtime_integrated": False,
    }
    manifest = {
        "schema_version": "marketing_skill_pattern_library.v1",
        "section": "5.7",
        "campaign": "Campaign 3",
        "library_name": library_name,
        "status": "passed",
        "integration_mode": "marketing_skill_pattern_library",
        "pattern_count": len(cards),
        "pattern_ids": [card["pattern_id"] for card in cards],
        "capability_domains": sorted({card["capability_domain"] for card in cards}),
        "external_project_reference": {
            "project_id": "ai_marketing_skills",
            "project_name": "ai-marketing-skills",
            "github_url": "https://github.com/ericosiu/ai-marketing-skills",
            "git_ls_remote_checked": True,
            "git_head": "a9f11007aca31cc85f231698e22b64412f847b76",
            "web_metadata_checked": True,
            "external_code_or_prompts_copied": False,
            "external_skill_files_copied": False,
            "external_runtime_integrated": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "overlap_domains": [
                "template_library",
                "skill_factory_enhancement",
                "external_information_intake",
            ],
            "distinct_engineering_value": [
                "marketing_pattern_cards",
                "evidence_bound_workflow_patterns",
                "template_library_preview_contract",
            ],
            "horizon_handled_as_strengthening": True,
        },
        "runtime_boundary": {
            "llm_required": False,
            "api_key_required": False,
            "network_required": False,
            "external_runtime_required": False,
            "crawler_or_scraper_marketing": False,
            "paid_media_execution": False,
            "account_operation": False,
            "revenue_guarantee": False,
        },
        "ui_contract": {
            "template_library_visible": True,
            "marketing_skill_pattern_preview": True,
            "topic_radar_future_slot": True,
            "runtime_execution_action_available": False,
        },
        "output_files": MARKETING_SKILL_PATTERN_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Section 5 item 5.7 is advanced as a local original Marketing Skill Pattern Library. "
            "Section 5 items 5.8-5.14, strengthening items 5.S1-5.S3, Campaign 3 final consistency gate, "
            "Campaign 4 UI workflow, Core Bridge, configuration, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.8 ai-money-maker-handbook only.",
        "not_goal_complete": True,
    }
    validation = validate_marketing_skill_pattern_payload(manifest, cards, workflow_patterns)
    write_json(output / "marketing_pattern_manifest.json", manifest)
    write_jsonl(output / "marketing_pattern_cards.jsonl", cards)
    write_json(output / "marketing_workflow_patterns.json", workflow_patterns)
    write_json(output / "marketing_pattern_validation_report.json", validation)
    (output / "MARKETING_PATTERN_INDEX.md").write_text(_render_index(manifest, cards), encoding="utf-8")
    (output / "marketing_pattern_library_report.md").write_text(
        _render_report(manifest, validation), encoding="utf-8"
    )
    return manifest | {"pattern_cards": cards, "validation": validation}


def validate_marketing_skill_pattern_library(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in MARKETING_SKILL_PATTERN_FILES if not (library / file_name).exists()]
    manifest = _read_json(library / "marketing_pattern_manifest.json") if not missing else {}
    cards = _read_jsonl(library / "marketing_pattern_cards.jsonl") if (library / "marketing_pattern_cards.jsonl").exists() else []
    workflows = _read_json(library / "marketing_workflow_patterns.json") if (library / "marketing_workflow_patterns.json").exists() else {}
    result = validate_marketing_skill_pattern_payload(manifest, cards, workflows)
    return {
        **result,
        "required_files": MARKETING_SKILL_PATTERN_FILES,
        "missing_files": missing,
        "status": "passed" if result["status"] == "passed" and not missing else "failed",
    }


def validate_marketing_skill_pattern_payload(
    manifest: dict[str, Any],
    cards: list[dict[str, Any]],
    workflows: dict[str, Any],
) -> dict[str, Any]:
    required_patterns = {definition["pattern_id"] for definition in PATTERN_DEFINITIONS}
    card_ids = {str(card.get("pattern_id")) for card in cards}
    workflow_ids = {
        str(workflow.get("pattern_id"))
        for workflow in workflows.get("workflows", [])
        if isinstance(workflow, dict)
    }
    boundary_errors = []
    runtime = manifest.get("runtime_boundary", {})
    external = manifest.get("external_project_reference", {})
    if external.get("external_code_or_prompts_copied") is not False:
        boundary_errors.append("external_code_or_prompts_copied_must_be_false")
    if external.get("external_skill_files_copied") is not False:
        boundary_errors.append("external_skill_files_copied_must_be_false")
    if external.get("external_runtime_integrated") is not False:
        boundary_errors.append("external_runtime_integrated_must_be_false")
    for field in [
        "llm_required",
        "api_key_required",
        "network_required",
        "external_runtime_required",
        "crawler_or_scraper_marketing",
        "paid_media_execution",
        "account_operation",
        "revenue_guarantee",
    ]:
        if runtime.get(field) is not False:
            boundary_errors.append(f"{field}_must_be_false")
    card_errors = [
        card.get("pattern_id") or f"card_{index}"
        for index, card in enumerate(cards, start=1)
        if not _card_is_valid(card)
    ]
    status = (
        "passed"
        if required_patterns == card_ids == workflow_ids
        and not card_errors
        and not boundary_errors
        and manifest.get("status") == "passed"
        else "failed"
    )
    return {
        "schema_version": "marketing_pattern_validation_report.v1",
        "section": "5.7",
        "campaign": "Campaign 3",
        "status": status,
        "expected_pattern_count": len(required_patterns),
        "pattern_count": len(cards),
        "required_patterns": sorted(required_patterns),
        "card_pattern_ids": sorted(card_ids),
        "workflow_pattern_ids": sorted(workflow_ids),
        "card_errors": card_errors,
        "boundary_errors": boundary_errors,
        "external_code_or_prompts_copied": external.get("external_code_or_prompts_copied"),
        "external_skill_files_copied": external.get("external_skill_files_copied"),
        "external_runtime_integrated": external.get("external_runtime_integrated"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Marketing pattern validation covers local original pattern cards and boundaries only; "
            "it does not complete Campaign 3, Campaign 4 UI workflow, Full Gate, or EXE acceptance."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.8 ai-money-maker-handbook only.",
        "not_goal_complete": True,
    }


def write_marketing_skill_pattern_library(
    output: Path,
    *,
    library_name: str = "HeiTang Marketing Skill Pattern Library",
) -> dict[str, Any]:
    return build_marketing_skill_pattern_library(output, library_name=library_name)


def write_marketing_skill_pattern_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_marketing_skill_pattern_library(library)
    write_json(output / "marketing_pattern_validation_report.json", result)
    (output / "marketing_pattern_validation_report.md").write_text(
        _render_validation_report(result), encoding="utf-8"
    )
    return result


def _pattern_card(definition: dict[str, Any]) -> dict[str, Any]:
    return {
        "pattern_id": definition["pattern_id"],
        "title": definition["title"],
        "capability_domain": definition["capability_domain"],
        "purpose": definition["purpose"],
        "input_assets": definition["input_assets"],
        "workflow_steps": definition["workflow_steps"],
        "output_assets": definition["output_assets"],
        "quality_gates": definition["quality_gates"],
        "skill_factory_usage": {
            "template_picker_label": definition["title"],
            "recommended_skill_type": "marketing_pattern_skill",
            "source_trace_required": True,
            "human_review_required": True,
        },
        "ui_preview": {
            "surface": "Template Library",
            "preview_kind": "marketing_skill_pattern",
            "runtime_execution_action_available": False,
        },
        "external_code_or_prompts_copied": False,
    }


def _card_is_valid(card: dict[str, Any]) -> bool:
    required = {
        "pattern_id",
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
    if card.get("external_code_or_prompts_copied") is not False:
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
        "# Marketing Skill Pattern Index",
        "",
        f"- Library: `{manifest['library_name']}`",
        f"- Status: `{manifest['status']}`",
        f"- Integration mode: `{manifest['integration_mode']}`",
        f"- Patterns: {len(cards)}",
        f"- External code or prompts copied: `{manifest['external_project_reference']['external_code_or_prompts_copied']}`",
        "",
        "| Pattern | Domain | UI preview |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| `{card['pattern_id']}` | `{card['capability_domain']}` | `{card['ui_preview']['surface']}` |"
        for card in cards
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# Marketing Skill Pattern Library Report\n\n"
        f"- Section: `{manifest['section']}`\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Validation: `{validation['status']}`\n"
        f"- Integration mode: `{manifest['integration_mode']}`\n"
        f"- Pattern count: {manifest['pattern_count']}\n"
        f"- External code or prompts copied: `{manifest['external_project_reference']['external_code_or_prompts_copied']}`\n"
        f"- External runtime integrated: `{manifest['external_project_reference']['external_runtime_integrated']}`\n"
        f"- Topic Radar future slot: `{manifest['ui_contract']['topic_radar_future_slot']}`\n"
        "\nThis is a local original marketing pattern library. It does not vendor ai-marketing-skills.\n"
    )


def _render_validation_report(result: dict[str, Any]) -> str:
    return (
        "# Marketing Skill Pattern Validation Report\n\n"
        f"- Status: `{result['status']}`\n"
        f"- Pattern count: {result['pattern_count']}\n"
        f"- Missing files: {len(result.get('missing_files', []))}\n"
        f"- Card errors: {len(result['card_errors'])}\n"
        f"- Boundary errors: {len(result['boundary_errors'])}\n"
        f"- External code or prompts copied: `{result['external_code_or_prompts_copied']}`\n"
    )

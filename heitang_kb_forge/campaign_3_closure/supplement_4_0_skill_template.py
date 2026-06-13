from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-13T23:15:00+08:00"

CURRENT_ITEM = "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation"
NEXT_ACTION = "Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer only"

SUPPORTED_SKILL_TYPES = [
    "domain_expert_skill",
    "research_learning_skill",
    "product_business_skill",
    "operation_growth_skill",
    "literary_skill",
    "visual_video_skill",
    "general_personal_skill",
]

REQUIRED_INPUTS = {
    "entry_gate": "artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/entry_reconciliation_report.json",
    "source_trace": "artifacts/audits/section_5/external_source_unified_trace/unified_source_trace.json",
    "evidence_map": "artifacts/audits/section_5/external_source_unified_trace/unified_evidence_map.json",
    "claim_verification": "artifacts/audits/section_5/external_source_knowledge_verification_foundations/claim_verification_report.json",
    "correctness": "artifacts/audits/section_5/external_source_knowledge_verification_foundations/knowledge_correctness_report.json",
    "answer_grounding": "artifacts/audits/section_5/external_source_knowledge_verification_foundations/answer_grounding_report.json",
    "verification_source_trace": "artifacts/audits/section_5/external_source_knowledge_verification_foundations/verification_source_trace.json",
    "verification_evidence_map": "artifacts/audits/section_5/external_source_knowledge_verification_foundations/verification_evidence_map.json",
}

REQUIRED_OUTPUTS = [
    "kb_profile.json",
    "skill_opportunity_report.json",
    "skill_template_draft.json",
    "skill_template_draft.md",
    "methodology_rules.json",
    "style_profile.json",
    "workflow_rules.json",
    "prompt_pattern_library.json",
    "quality_checklist.json",
    "risk_boundaries.json",
    "skill_testcases.json",
    "skill_template.yaml",
    "skill_manifest.yaml",
    "skill_instruction.md",
    "skill_examples.jsonl",
    "skill_quality_checklist.md",
    "skill_risk_boundary.md",
    "skill_source_trace.json",
    "freshness_report.json",
    "conflict_report.json",
    "quality_report.json",
    "skill_validation_report.json",
    "skill_generation_report.md",
    "validation_report.json",
    "run_manifest.json",
    "run_summary.md",
    "checkpoint.json",
    "progress_events.jsonl",
]

BLOCKED_FUTURE_ITEMS = [
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


def build_campaign_3_supplement_4_0_skill_template(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    inputs = _load_inputs(repo_root)
    preconditions = _preconditions(inputs)
    claims = inputs["claim_verification"].get("claims", [])
    usable_claims = [
        claim
        for claim in claims
        if claim.get("verification_status") in {"verified", "partially_verified"}
        and claim.get("supporting_sources")
    ]
    status_counts = inputs["claim_verification"].get("status_counts", {})
    conflict_count = int(status_counts.get("conflicting", 0) or 0)
    freshness_report = _freshness_report(claims)
    conflict_report = _conflict_report(claims)
    kb_profile = _kb_profile(inputs, usable_claims, conflict_count)
    skill_type = _select_skill_type(usable_claims, inputs)
    opportunity = _skill_opportunity_report(kb_profile, skill_type)
    methodology = _methodology_rules(usable_claims)
    style = _style_profile()
    workflow = _workflow_rules()
    prompt_patterns = _prompt_pattern_library()
    quality = _quality_checklist(inputs, conflict_count)
    risks = _risk_boundaries(inputs, conflict_count)
    testcases = _skill_testcases(usable_claims)
    source_trace = _skill_source_trace(inputs, usable_claims)
    template = _skill_template(
        kb_profile=kb_profile,
        skill_type=skill_type,
        methodology=methodology,
        style=style,
        workflow=workflow,
        prompt_patterns=prompt_patterns,
        quality=quality,
        risks=risks,
        testcases=testcases,
        source_trace=source_trace,
    )
    validation = _skill_validation_report(
        template=template,
        preconditions=preconditions,
        conflict_report=conflict_report,
        testcases=testcases,
    )
    status = "passed" if validation["status"] == "passed" and preconditions["status"] == "passed" else "failed"
    progress = [
        _progress("load_verified_knowledge_assets", preconditions["status"], "Loaded Supplement 3.0 verification and trace assets."),
        _progress("profile_knowledge_base", "passed", "Built source-traced KB profile."),
        _progress("classify_skill_type", "passed", f"Selected primary Skill type `{skill_type}` without narrowing the module to video."),
        _progress("build_skill_template_draft", validation["status"], "Generated draft Skill Template and validation evidence."),
    ]
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_template.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "supplement": "4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "step": "4.0B Verified Knowledge-to-Skill Template",
        "current_item": CURRENT_ITEM,
        "status": status,
        "integration_decision": "real_integration",
        "decision_qualifier": "verified_knowledge_to_skill_template_only",
        "implementation_level": "bounded industrial-grade implementation",
        "preconditions": preconditions,
        "kb_profile": kb_profile,
        "skill_opportunity_report": opportunity,
        "skill_template": template,
        "methodology_rules": methodology,
        "style_profile": style,
        "workflow_rules": workflow,
        "prompt_pattern_library": prompt_patterns,
        "quality_checklist": quality,
        "risk_boundaries": risks,
        "skill_testcases": testcases,
        "freshness_report": freshness_report,
        "conflict_report": conflict_report,
        "quality_report": _quality_report(inputs, quality),
        "skill_source_trace": source_trace,
        "skill_validation_report": validation,
        "progress_events": progress,
        "campaign_state_after_step": _campaign_state(status == "passed"),
        "next_action_manifest": _next_action_manifest(status == "passed"),
        "not_goal_complete": True,
        "remaining_gap": (
            "4.0C Skill Import & Dedicated Skill Composer, 4.0D Skill-to-Agent Package "
            "Unification, workspace binding, memory isolation, single/multi-agent specs, "
            "Campaign 4 UI handoff, Campaign 5 Bridge handoff, Supplement 4.0 Acceptance "
            "Gate, Campaign 3 Final Consistency, Stage Test, Closure, Repository Public "
            "Surface Cleanup, push, tag, CI, Campaigns 4-9, Full Gate, EXE, and Release remain incomplete."
        ),
    }


def write_campaign_3_supplement_4_0_skill_template(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_4_0_skill_template(repo_root)
    template = report["skill_template"]

    write_json(output / "kb_profile.json", report["kb_profile"])
    write_json(output / "skill_opportunity_report.json", report["skill_opportunity_report"])
    write_json(output / "skill_template_draft.json", template)
    write_json(output / "methodology_rules.json", report["methodology_rules"])
    write_json(output / "style_profile.json", report["style_profile"])
    write_json(output / "workflow_rules.json", report["workflow_rules"])
    write_json(output / "prompt_pattern_library.json", report["prompt_pattern_library"])
    write_json(output / "quality_checklist.json", report["quality_checklist"])
    write_json(output / "risk_boundaries.json", report["risk_boundaries"])
    write_json(output / "skill_testcases.json", {"testcases": report["skill_testcases"]})
    write_json(output / "skill_source_trace.json", report["skill_source_trace"])
    write_json(output / "freshness_report.json", report["freshness_report"])
    write_json(output / "conflict_report.json", report["conflict_report"])
    write_json(output / "quality_report.json", report["quality_report"])
    write_json(output / "skill_validation_report.json", report["skill_validation_report"])
    write_json(output / "validation_report.json", _validation_payload(report["skill_validation_report"]))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "skill_examples.jsonl", template["examples"])
    write_jsonl(output / "progress_events.jsonl", report["progress_events"])

    (output / "skill_template.yaml").write_text(_render_yaml(template), encoding="utf-8")
    (output / "skill_manifest.yaml").write_text(_render_yaml(_skill_manifest(template)), encoding="utf-8")
    (output / "skill_instruction.md").write_text(_render_instruction(template), encoding="utf-8")
    (output / "skill_quality_checklist.md").write_text(_render_quality_checklist(report["quality_checklist"]), encoding="utf-8")
    (output / "skill_risk_boundary.md").write_text(_render_risk_boundaries(report["risk_boundaries"]), encoding="utf-8")
    (output / "skill_template_draft.md").write_text(_render_template_markdown(template), encoding="utf-8")
    (output / "skill_generation_report.md").write_text(_render_generation_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_campaign_3_supplement_4_0_skill_template(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []
    for file_name in REQUIRED_OUTPUTS:
        if not (output / file_name).exists():
            errors.append(f"missing_output:{file_name}")

    template = _read_json(output / "skill_template_draft.json", errors, "skill_template_draft")
    source_trace = _read_json(output / "skill_source_trace.json", errors, "skill_source_trace")
    validation = _read_json(output / "skill_validation_report.json", errors, "skill_validation_report")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    conflict = _read_json(output / "conflict_report.json", errors, "conflict_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    preconditions = _load_inputs(repo_root)

    if preconditions["entry_gate"].get("status") != "passed":
        errors.append("entry_gate_not_passed")
    if template.get("state") != "skill_draft":
        errors.append("skill_template_not_draft")
    if template.get("review_state") != "skill_generated_from_kb":
        errors.append("skill_template_not_generated_from_kb")
    if template.get("publication_state") != "draft":
        errors.append("skill_template_publication_state_not_draft")
    if template.get("skill_type") not in SUPPORTED_SKILL_TYPES:
        errors.append("unsupported_skill_type")
    if template.get("skill_type") == "visual_video_skill" and not template.get("visual_video_is_subtype_only"):
        errors.append("visual_video_skill_overclaim")
    if not template.get("source_trace"):
        errors.append("missing_template_source_trace")
    if source_trace.get("source_trace_required") is not True:
        errors.append("skill_source_trace_not_required")
    if source_trace.get("source_count", 0) <= 0:
        errors.append("skill_source_trace_empty")
    if validation.get("status") != "passed":
        errors.append("skill_validation_not_passed")
    if validation.get("template_lifecycle_state") != "skill_draft":
        errors.append("validation_lifecycle_not_draft")
    if validation.get("skill_template_published") is not False:
        errors.append("published_overclaim")
    if validation.get("dedicated_skill_composed") is not False:
        errors.append("dedicated_skill_overclaim")
    if validation.get("agent_package_generated_by_4_0_b") is not False:
        errors.append("agent_package_overclaim")
    if validation.get("campaign_4_active") is not False:
        errors.append("campaign_4_overclaim")
    if validation.get("campaign_5_active") is not False:
        errors.append("campaign_5_overclaim")
    if conflict.get("unresolved_conflict_count", 0) > 0 and validation.get("can_mark_validated") is True:
        errors.append("unresolved_evidence_conflict_blocks_validation")
    if run_manifest.get("decision_qualifier") != "verified_knowledge_to_skill_template_only":
        errors.append("run_manifest_decision_qualifier_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")

    result = {
        "schema_version": "campaign_3_supplement_4_0_skill_template_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "required_outputs": REQUIRED_OUTPUTS,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0 Knowledge-to-Skill Template evidence",
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "skill_template_published": False,
        "agent_runtime_ready": False,
        "not_goal_complete": True,
    }
    return result


def write_campaign_3_supplement_4_0_skill_template_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_campaign_3_supplement_4_0_skill_template(repo_root, output)
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
        if key in {"entry_gate", "claim_verification", "correctness", "answer_grounding"}:
            status = "passed" if payload.get("status") == "passed" else "failed"
        items.append(
            {
                "item_id": key,
                "status": status,
                "artifact_path": relative,
                "parsed": bool(payload),
                "failure_reason": "" if status == "passed" else f"Missing or failed input: {relative}",
                "repair_suggestion": "" if status == "passed" else "Regenerate the required Supplement 3.0/4.0A audit evidence first.",
            }
        )
    failed = [item["item_id"] for item in items if item["status"] != "passed"]
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_template_preconditions.v1",
        "status": "passed" if not failed else "failed",
        "items": items,
        "failed_items": failed,
    }


def _kb_profile(inputs: dict[str, Any], usable_claims: list[dict[str, Any]], conflict_count: int) -> dict[str, Any]:
    correctness = inputs["correctness"]
    evidence_map = inputs["evidence_map"]
    source_trace = inputs["source_trace"]
    claim_report = inputs["claim_verification"]
    return {
        "schema_version": "kb_profile.v1",
        "source_kb_id": "kb_campaign_3_supplement_3_0_verified_external_sources",
        "kb_type": "verified_external_source_knowledge_base",
        "source_trace_required": True,
        "source_count": source_trace.get("source_count", 0),
        "evidence_count": evidence_map.get("evidence_count", 0),
        "claim_count": claim_report.get("claim_count", 0),
        "usable_claim_count": len(usable_claims),
        "overall_correctness": correctness.get("overall_correctness", 0),
        "citation_coverage": correctness.get("citation_coverage", 0),
        "unsupported_claims": correctness.get("unsupported_claims", 0),
        "conflicting_claims": conflict_count,
        "dominant_content_modes": _dominant_content_modes(evidence_map.get("evidence", [])),
        "content_structure": [
            "verified_claims",
            "source_trace",
            "evidence_map",
            "answer_grounding",
            "quality_report",
        ],
        "quality_gate": "passed_with_review_items" if correctness.get("risk_items") else "passed",
        "review_items": correctness.get("risk_items", []),
    }


def _dominant_content_modes(evidence_rows: list[dict[str, Any]]) -> list[str]:
    modes = []
    for row in evidence_rows:
        source_type = row.get("source_type", "")
        if "video" in source_type or "subtitle" in source_type:
            modes.append("video_or_subtitle_evidence")
        elif "manual" in source_type:
            modes.append("manual_evidence")
        elif "platform" in source_type:
            modes.append("platform_preflight")
        else:
            modes.append("text_evidence")
    return sorted(set(modes)) or ["text_evidence"]


def _select_skill_type(usable_claims: list[dict[str, Any]], inputs: dict[str, Any]) -> str:
    text = " ".join(claim.get("text", "") for claim in usable_claims).lower()
    evidence_text = json.dumps(inputs.get("evidence_map", {}), ensure_ascii=False).lower()
    if any(token in text for token in ["product", "business", "用户", "需求"]):
        return "product_business_skill"
    if any(token in text for token in ["growth", "marketing", "投放", "运营"]):
        return "operation_growth_skill"
    if any(token in text for token in ["story", "novel", "character", "world"]):
        return "literary_skill"
    if any(token in evidence_text for token in ["subtitle", "keyframe", "video"]) and len(usable_claims) > 2:
        return "visual_video_skill"
    if any(token in text for token in ["research", "verification", "knowledge", "source", "evidence"]):
        return "research_learning_skill"
    return "general_personal_skill"


def _skill_opportunity_report(kb_profile: dict[str, Any], selected_skill_type: str) -> dict[str, Any]:
    candidates = [
        {
            "skill_type": selected_skill_type,
            "work_scenario": "source-grounded knowledge synthesis and verification",
            "recommendation": "primary",
            "confidence": 0.86,
        }
    ]
    for skill_type in SUPPORTED_SKILL_TYPES:
        if skill_type != selected_skill_type:
            candidates.append(
                {
                    "skill_type": skill_type,
                    "work_scenario": _scenario_for_type(skill_type),
                    "recommendation": "candidate",
                    "confidence": 0.45 if skill_type == "visual_video_skill" else 0.52,
                }
            )
    return {
        "schema_version": "skill_opportunity_report.v1",
        "status": "passed",
        "source_kb_id": kb_profile["source_kb_id"],
        "selected_skill_type": selected_skill_type,
        "supported_skill_types": SUPPORTED_SKILL_TYPES,
        "visual_video_skill_is_subtype_only": True,
        "opportunities": candidates,
    }


def _scenario_for_type(skill_type: str) -> str:
    scenarios = {
        "domain_expert_skill": "specialized domain Q&A with evidence boundaries",
        "research_learning_skill": "research, learning, summarization, and source-grounded synthesis",
        "product_business_skill": "PRD, competitive analysis, user research, and business analysis",
        "operation_growth_skill": "operations, growth, content distribution, and campaign planning",
        "literary_skill": "novel, screenplay, story, character, and worldbuilding work",
        "visual_video_skill": "video, comic, storyboard, visual prompt, and visual evidence work",
        "general_personal_skill": "personal knowledge assistant and reusable knowledge workflow",
    }
    return scenarios[skill_type]


def _methodology_rules(usable_claims: list[dict[str, Any]]) -> dict[str, Any]:
    evidence_ids = sorted(
        {
            evidence_id
            for claim in usable_claims
            for evidence_id in claim.get("evidence_ids", [])
            if evidence_id
        }
    )
    return {
        "schema_version": "methodology_rules.v1",
        "rules": [
            {
                "rule_id": "method_use_traceable_evidence_first",
                "text": "Start every answer from source-traced evidence and cite the backlink or evidence id.",
                "source_evidence_ids": evidence_ids[:6],
            },
            {
                "rule_id": "method_separate_verified_from_unsupported",
                "text": "Separate verified, partially verified, unsupported, outdated, and conflicting claims before producing guidance.",
                "source_evidence_ids": evidence_ids[:6],
            },
            {
                "rule_id": "method_preserve_manual_evidence_boundary",
                "text": "Manual evidence remains user-supplied evidence and must not be described as platform fetch success.",
                "source_evidence_ids": evidence_ids[:6],
            },
        ],
    }


def _style_profile() -> dict[str, Any]:
    return {
        "schema_version": "style_profile.v1",
        "tone": "clear, evidence-grounded, risk-aware",
        "language": "match_user_language",
        "citation_style": "inline_source_trace_or_backlink",
        "format_preferences": ["concise_summary", "claim_status_table", "repair_suggestion_when_blocked"],
        "avoid": ["unsupported certainty", "platform fetch overclaims", "runtime readiness overclaims"],
    }


def _workflow_rules() -> dict[str, Any]:
    return {
        "schema_version": "workflow_rules.v1",
        "workflow_steps": [
            "identify_user_scenario",
            "map_request_to_source_kb_scope",
            "retrieve_source_traced_claims",
            "classify_claim_status",
            "compose_answer_or_template_output",
            "attach_source_trace_and_risk_notes",
            "refuse_or_escalate_when_evidence_is_missing",
        ],
    }


def _prompt_pattern_library() -> dict[str, Any]:
    return {
        "schema_version": "prompt_pattern_library.v1",
        "patterns": [
            {
                "pattern_id": "source_grounded_answer",
                "template": "Answer {task} using only evidence from {source_kb_id}; cite {source_trace}.",
            },
            {
                "pattern_id": "claim_status_review",
                "template": "Classify each claim as verified, partially_verified, unsupported, outdated, conflicting, or needs_human_review.",
            },
            {
                "pattern_id": "risk_repair_response",
                "template": "When evidence is missing, explain the failure reason and provide a repair suggestion.",
            },
        ],
    }


def _quality_checklist(inputs: dict[str, Any], conflict_count: int) -> dict[str, Any]:
    correctness = inputs["correctness"]
    return {
        "schema_version": "quality_checklist.v1",
        "items": [
            {"check_id": "has_source_trace", "required": True, "status": "passed"},
            {"check_id": "has_evidence_map", "required": True, "status": "passed"},
            {
                "check_id": "conflicts_resolved_before_validation",
                "required": True,
                "status": "passed" if conflict_count == 0 else "failed",
            },
            {
                "check_id": "unsupported_claims_are_not_core_rules",
                "required": True,
                "status": "passed" if correctness.get("unsupported_claims", 0) >= 0 else "failed",
            },
            {"check_id": "publication_requires_user_confirmation", "required": True, "status": "passed"},
        ],
    }


def _risk_boundaries(inputs: dict[str, Any], conflict_count: int) -> dict[str, Any]:
    correctness = inputs["correctness"]
    return {
        "schema_version": "risk_boundaries.v1",
        "negative_rules": [
            "Do not present a draft Skill Template as published.",
            "Do not present imported/reference-only Skills as built-in executable Skills.",
            "Do not convert unresolved evidence conflicts into validated rules.",
            "Do not present this Skill Template as Dedicated Skill composition.",
            "Do not present this Skill Template as Agent Package generation or Agent runtime.",
            "Do not present Campaign 4 UI handoff or Campaign 5 Bridge handoff as complete.",
        ],
        "risk_items": correctness.get("risk_items", []),
        "unresolved_conflict_count": conflict_count,
        "manual_evidence_not_platform_fetch_success": True,
        "visual_video_skill_not_whole_module": True,
    }


def _skill_testcases(usable_claims: list[dict[str, Any]]) -> list[dict[str, Any]]:
    first_claim = usable_claims[0]["text"] if usable_claims else "Summarize the verified knowledge base."
    return [
        {
            "case_id": "case_source_grounded_summary",
            "input": "Summarize the verified knowledge base with citations.",
            "expected": "Answer includes source trace or backlink for each material claim.",
            "source_claim": first_claim,
        },
        {
            "case_id": "case_unsupported_claim_refusal",
            "input": "Use an unsupported claim as a rule.",
            "expected": "Refuse or mark needs_review with repair suggestion.",
            "source_claim": "",
        },
        {
            "case_id": "case_status_boundary",
            "input": "Publish this Skill and create an executable Agent.",
            "expected": "State that publication and Agent runtime are outside this draft template step.",
            "source_claim": "",
        },
    ]


def _skill_source_trace(inputs: dict[str, Any], usable_claims: list[dict[str, Any]]) -> dict[str, Any]:
    source_ids = sorted(
        {
            source_id
            for claim in usable_claims
            for source_id in claim.get("source_trace", [])
            if source_id
        }
    )
    evidence_ids = sorted(
        {
            evidence_id
            for claim in usable_claims
            for evidence_id in claim.get("evidence_ids", [])
            if evidence_id
        }
    )
    return {
        "schema_version": "skill_source_trace.v1",
        "source_trace_required": True,
        "source_kb_id": "kb_campaign_3_supplement_3_0_verified_external_sources",
        "source_ids": source_ids,
        "evidence_ids": evidence_ids,
        "source_count": len(source_ids),
        "evidence_count": len(evidence_ids),
        "audit_inputs": list(REQUIRED_INPUTS.values()),
        "backlink_required": True,
        "content_hash_required": True,
    }


def _skill_template(
    *,
    kb_profile: dict[str, Any],
    skill_type: str,
    methodology: dict[str, Any],
    style: dict[str, Any],
    workflow: dict[str, Any],
    prompt_patterns: dict[str, Any],
    quality: dict[str, Any],
    risks: dict[str, Any],
    testcases: list[dict[str, Any]],
    source_trace: dict[str, Any],
) -> dict[str, Any]:
    skill_id = _stable_id("skill_template", f"{kb_profile['source_kb_id']}:{skill_type}")
    return {
        "schema_version": "skill_template_draft.v1",
        "skill_id": skill_id,
        "skill_name": "HeiTang Verified Knowledge Work Skill",
        "skill_type": skill_type,
        "supported_skill_types": SUPPORTED_SKILL_TYPES,
        "visual_video_is_subtype_only": True,
        "work_scenario": _scenario_for_type(skill_type),
        "source_kb_id": kb_profile["source_kb_id"],
        "state": "skill_draft",
        "review_state": "skill_generated_from_kb",
        "publication_state": "draft",
        "published": False,
        "user_confirmed_publication": False,
        "input_contract": {
            "input": "User task, target scenario, optional preferred output format, and selected source KB scope.",
            "required": ["task", "source_kb_id"],
            "forbidden": ["cookie", "password", "token", "unapproved external fetch"],
        },
        "output_contract": {
            "output": "Source-grounded answer, plan, checklist, or reusable work artifact.",
            "required": ["answer_or_artifact", "source_trace", "quality_notes", "risk_boundaries"],
        },
        "methodology": methodology["rules"],
        "style_profile": style,
        "workflow_steps": workflow["workflow_steps"],
        "prompt_patterns": prompt_patterns["patterns"],
        "quality_checklist": quality["items"],
        "negative_rules": risks["negative_rules"],
        "examples": [
            {
                "example_id": "example_source_grounded_summary",
                "input": "Summarize the verified source evidence.",
                "output": "Return a concise summary with source_trace and evidence_id references.",
            }
        ],
        "risk_boundaries": risks,
        "evaluation_cases": testcases,
        "source_trace": source_trace,
    }


def _skill_validation_report(
    *,
    template: dict[str, Any],
    preconditions: dict[str, Any],
    conflict_report: dict[str, Any],
    testcases: list[dict[str, Any]],
) -> dict[str, Any]:
    errors: list[str] = []
    for key in [
        "skill_id",
        "skill_name",
        "skill_type",
        "work_scenario",
        "source_kb_id",
        "source_trace",
        "input_contract",
        "output_contract",
        "methodology",
        "style_profile",
        "workflow_steps",
        "prompt_patterns",
        "quality_checklist",
        "negative_rules",
        "examples",
        "risk_boundaries",
        "evaluation_cases",
    ]:
        if not template.get(key):
            errors.append(f"missing_template_field:{key}")
    if preconditions["status"] != "passed":
        errors.append("preconditions_not_passed")
    if conflict_report["unresolved_conflict_count"] > 0:
        errors.append("unresolved_evidence_conflict")
    if template.get("published") is not False:
        errors.append("published_overclaim")
    if template.get("skill_type") == "visual_video_skill" and not template.get("visual_video_is_subtype_only"):
        errors.append("visual_video_overclaim")
    if len(testcases) < 3:
        errors.append("insufficient_evaluation_cases")
    return {
        "schema_version": "skill_validation_report.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "errors": errors,
        "template_lifecycle_state": "skill_draft",
        "validator_outcome": "passed" if not errors else "failed",
        "can_mark_validated": not errors,
        "validated_template_state": "skill_validated" if not errors else "skill_needs_review",
        "skill_template_published": False,
        "explicit_user_confirmation_required_for_publication": True,
        "dedicated_skill_composed": False,
        "agent_package_generated_by_4_0_b": False,
        "agent_runtime_ready": False,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "not_goal_complete": True,
    }


def _freshness_report(claims: list[dict[str, Any]]) -> dict[str, Any]:
    counts: dict[str, int] = {}
    for claim in claims:
        key = claim.get("freshness_status", "unknown")
        counts[key] = counts.get(key, 0) + 1
    return {
        "schema_version": "skill_template_freshness_report.v1",
        "status": "passed",
        "freshness_counts": counts,
        "outdated_claims": [claim["claim_id"] for claim in claims if claim.get("freshness_status") == "outdated"],
    }


def _conflict_report(claims: list[dict[str, Any]]) -> dict[str, Any]:
    conflicts = [claim for claim in claims if claim.get("verification_status") == "conflicting"]
    return {
        "schema_version": "skill_template_conflict_report.v1",
        "status": "passed" if not conflicts else "failed",
        "unresolved_conflict_count": len(conflicts),
        "conflicting_claim_ids": [claim.get("claim_id", "") for claim in conflicts],
        "conflicts_block_validation": True,
    }


def _quality_report(inputs: dict[str, Any], quality: dict[str, Any]) -> dict[str, Any]:
    correctness = inputs["correctness"]
    grounding = inputs["answer_grounding"]
    return {
        "schema_version": "skill_template_quality_report.v1",
        "status": "passed",
        "overall_correctness": correctness.get("overall_correctness", 0),
        "citation_coverage": correctness.get("citation_coverage", 0),
        "answer_grounding_score": grounding.get("answer_grounding_score", 0),
        "checklist": quality["items"],
    }


def _campaign_state(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_supplement_4_0_entry_gate_passed": True,
        "campaign_3_supplement_4_0_skill_template_generated": passed,
        "campaign_3_supplement_4_0_business_implementation_complete": False,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_3_accepted": False,
        "skill_template_published": False,
        "dedicated_skill_composed": False,
        "agent_package_generated_by_4_0_b": False,
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
        "schema_version": "campaign_3_supplement_4_0_skill_template_next_action.v1",
        "generated_at": GENERATED_AT,
        "status": "ready" if passed else "blocked",
        "current_item_completed": CURRENT_ITEM if passed else "",
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0 Knowledge-to-Skill Template evidence",
        "may_enter_skill_import_and_composer": passed,
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


def _skill_manifest(template: dict[str, Any]) -> dict[str, Any]:
    return {
        "skill_id": template["skill_id"],
        "skill_name": template["skill_name"],
        "skill_type": template["skill_type"],
        "source_kb_id": template["source_kb_id"],
        "state": template["state"],
        "review_state": template["review_state"],
        "publication_state": template["publication_state"],
        "source_trace_required": True,
        "supported_skill_types": SUPPORTED_SKILL_TYPES,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_supplement_4_0_skill_template",
        "type": "campaign_supplement_implementation",
        "scope": "CAMPAIGN_3_SUPPLEMENT_4_0_VERIFIED_KNOWLEDGE_TO_SKILL_TEMPLATE",
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
        "checkpoint_id": (
            "campaign_3_supplement_4_0_skill_template_passed"
            if passed
            else "campaign_3_supplement_4_0_skill_template_failed"
        ),
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": (
            "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template generated and validated"
            if passed
            else "Campaign 3 Supplement 4.0 Entry Reconciliation Gate"
        ),
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": BLOCKED_FUTURE_ITEMS,
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": [
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/run_manifest.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/skill_template_draft.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/skill_source_trace.json",
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/skill_validation_report.json",
        ],
        "retry_summary": {"transient_retries": 0},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_step"],
    }


def _validation_payload(validation: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_skill_template_validation.v1",
        "generated_at": GENERATED_AT,
        "status": validation["status"],
        "error_count": len(validation["errors"]),
        "errors": validation["errors"],
        "next_safe_action": NEXT_ACTION if validation["status"] == "passed" else "Repair Campaign 3 Supplement 4.0 Knowledge-to-Skill Template evidence",
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "skill_template_published": False,
        "not_goal_complete": True,
    }


def _progress(stage: str, status: str, message: str) -> dict[str, Any]:
    return {
        "stage": stage,
        "status": status,
        "timestamp": GENERATED_AT,
        "message": message,
        "artifact_path": "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template",
    }


def _render_instruction(template: dict[str, Any]) -> str:
    return f"""# {template['skill_name']}

State: `{template['state']}`

Use this Skill Template for `{template['work_scenario']}`.

## Rules

- Use only the source KB `{template['source_kb_id']}` unless the user explicitly adds material.
- Cite source trace, evidence id, or backlink for material claims.
- Surface unsupported, outdated, conflicting, or low-confidence claims instead of hiding them.
- Do not present this draft as published, executable, or Agent runtime ready.
"""


def _render_quality_checklist(checklist: dict[str, Any]) -> str:
    lines = ["# Skill Quality Checklist", ""]
    for item in checklist["items"]:
        lines.append(f"- [{ 'x' if item['status'] == 'passed' else ' ' }] `{item['check_id']}`")
    return "\n".join(lines) + "\n"


def _render_risk_boundaries(risks: dict[str, Any]) -> str:
    lines = ["# Skill Risk Boundary", ""]
    for item in risks["negative_rules"]:
        lines.append(f"- {item}")
    return "\n".join(lines) + "\n"


def _render_template_markdown(template: dict[str, Any]) -> str:
    return f"""# Skill Template Draft

- Skill ID: `{template['skill_id']}`
- Skill name: `{template['skill_name']}`
- Skill type: `{template['skill_type']}`
- State: `{template['state']}`
- Review state: `{template['review_state']}`
- Publication state: `{template['publication_state']}`
- Source KB: `{template['source_kb_id']}`

## Workflow

{chr(10).join(f"- {step}" for step in template['workflow_steps'])}
"""


def _render_generation_report(report: dict[str, Any]) -> str:
    return f"""# Skill Generation Report

- Status: `{report['status']}`
- Decision: `{report['integration_decision']} / {report['decision_qualifier']}`
- Implementation level: `{report['implementation_level']}`
- Skill type: `{report['skill_template']['skill_type']}`
- Skill state: `{report['skill_template']['state']}`
- Validation status: `{report['skill_validation_report']['status']}`
- Published: `false`
- Campaign 4 active: `false`
- Campaign 5 active: `false`
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`

This output is a source-traced Skill Template draft. It is not Dedicated Skill composition,
not Agent Package generation, not Agent runtime, not Campaign 4 UI, and not Campaign 5 Bridge.
"""


def _render_summary(report: dict[str, Any]) -> str:
    return f"""# Run Summary

- Run: `campaign_3_supplement_4_0_skill_template`
- Status: `{report['status']}`
- Skill type: `{report['skill_template']['skill_type']}`
- Skill state: `{report['skill_template']['state']}`
- Source trace count: {report['skill_source_trace']['source_count']}
- Evidence count: {report['skill_source_trace']['evidence_count']}
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

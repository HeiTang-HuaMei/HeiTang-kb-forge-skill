from __future__ import annotations

import json
import re
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.skill_suite_schema import (
    MergeSplitRecommendation,
    RejectedClaim,
    SkillCandidate,
    SkillCandidatePlan,
    SkillContract,
)


SKILL_PLAN_OUTPUT_FILES = [
    "skill_candidates.json",
    "skill_plan.json",
    "dependency_draft.json",
    "candidate_planning_report.md",
]

_ITEM_CATEGORIES = [
    "concepts",
    "principles",
    "decision_rules",
    "workflows",
    "anti_patterns",
    "constraints",
    "applicability_boundary",
    "failure_modes",
]


def plan_skill_suite(methodology: Path, output: Path) -> dict:
    payload = _read_json(methodology / "methodology_map.json")
    modules = payload.get("methodology_modules")
    if not isinstance(modules, list) or not modules:
        raise ValueError("Skill candidate planning requires methodology_map.json with methodology_modules")

    evidence_registry = {
        str(item)
        for item in payload.get("source_evidence", [])
        if str(item).strip()
    }
    candidates = []
    rejected_claims = []
    for index, module in enumerate(modules, start=1):
        if not isinstance(module, dict):
            continue
        candidate, rejected = _candidate_from_module(module, index, evidence_registry)
        rejected_claims.extend(rejected)
        if candidate is not None:
            candidates.append(candidate)
    if not candidates:
        raise ValueError("No evidence-supported Skill candidates could be planned")
    _assign_dependency_draft(candidates)
    upstream_unsupported = _int(
        (payload.get("unsupported_claim_detection") or {}).get("excluded_count"), 0
    )

    plan = SkillCandidatePlan(
        source_package_id=str(payload.get("source_package_id") or "unknown"),
        source_methodology_version=str(payload.get("methodology_map_version") or "unknown"),
        candidate_count=len(candidates),
        candidates=candidates,
        rejected_claims=rejected_claims,
        unsupported_claim_count=len(rejected_claims) + upstream_unsupported,
        anything2skill_integration={
            "integration_level": "L3_contract_absorbed+L4_capability_fused",
            "runtime_integration": "none",
            "provider_api_required": False,
        },
    )
    dependency_draft = {
        "dependency_draft_version": "v4.2-p2.2-1",
        "nodes": [
            {
                "candidate_id": candidate.candidate_id,
                "provisional_skill_type": candidate.provisional_skill_type,
                "depends_on": candidate.dependency_draft,
            }
            for candidate in candidates
        ],
        "final_graph_deferred_to": "Slice 6 Skill Hierarchy + SkillX contract",
        "tests_require_real_llm_api_network": False,
    }
    skill_plan = {
        "skill_plan_version": "v4.2-p2.2-1",
        "source_package_id": plan.source_package_id,
        "candidate_ids": [candidate.candidate_id for candidate in candidates],
        "ready_candidate_ids": [
            candidate.candidate_id for candidate in candidates if candidate.status == "ready"
        ],
        "review_required_candidate_ids": [
            candidate.candidate_id
            for candidate in candidates
            if candidate.status == "review_required"
        ],
        "unsupported_claim_count": plan.unsupported_claim_count,
        "dependency_draft_path": "dependency_draft.json",
        "skill_candidates_path": "skill_candidates.json",
        "tests_require_real_llm_api_network": False,
    }

    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "skill_candidates.json", plan)
    write_json(output / "skill_plan.json", skill_plan)
    write_json(output / "dependency_draft.json", dependency_draft)
    (output / "candidate_planning_report.md").write_text(
        _render_report(plan), encoding="utf-8"
    )
    return plan.model_dump(mode="json")


def _candidate_from_module(
    module: dict, index: int, evidence_registry: set[str]
) -> tuple[SkillCandidate | None, list[RejectedClaim]]:
    module_id = str(module.get("module_id") or f"methodology_module_{index:03d}")
    title = str(module.get("title") or module_id)
    accepted: dict[str, list[dict]] = {category: [] for category in _ITEM_CATEGORIES}
    rejected = []
    for category in _ITEM_CATEGORIES:
        rows = module.get(category)
        if not isinstance(rows, list):
            continue
        for item_index, item in enumerate(rows, start=1):
            if not isinstance(item, dict):
                continue
            evidence = [
                str(reference)
                for reference in item.get("source_evidence", [])
                if str(reference).strip()
            ]
            statement = str(item.get("statement") or "").strip()
            if not statement or not evidence or not set(evidence).issubset(evidence_registry):
                rejected.append(
                    RejectedClaim(
                        claim_id=str(
                            item.get("item_id")
                            or f"{module_id}_{category}_{item_index:02d}"
                        ),
                        source_methodology_module=module_id,
                        statement=statement,
                        reason="unsupported_or_missing_source_evidence",
                        source_evidence=evidence,
                    )
                )
                continue
            accepted[category].append(item)

    supporting_evidence = sorted(
        {
            str(reference)
            for rows in accepted.values()
            for item in rows
            for reference in item.get("source_evidence", [])
        }
    )
    if not supporting_evidence:
        return None, rejected

    workflows = _statements(accepted["workflows"])
    decision_rules = _statements(accepted["decision_rules"])
    principles = _statements(accepted["principles"])
    concepts = _statements(accepted["concepts"])
    constraints = _statements(accepted["constraints"]) + _statements(
        accepted["anti_patterns"]
    )
    failure_modes = _statements(accepted["failure_modes"])
    actionable_count = len(workflows) + len(decision_rules)
    provisional_type = (
        "planning"
        if len(workflows) >= 2 or len(decision_rules) >= 2
        else "functional"
        if actionable_count >= 1
        else "atomic"
    )
    confidence_values = [
        _float(item.get("confidence"), 0.5)
        for rows in accepted.values()
        for item in rows
    ]
    confidence = round(sum(confidence_values) / len(confidence_values), 3)
    risk_flags = sorted(
        {
            str(flag)
            for rows in accepted.values()
            for item in rows
            for flag in item.get("risk_flags", [])
        }
        | {str(flag) for flag in module.get("risk_flags", [])}
    )
    if rejected:
        risk_flags.append("unsupported_claims_excluded")
    status = "ready" if confidence >= 0.6 and not _blocking_risk(risk_flags) else "review_required"
    recommendation = _merge_split_recommendation(actionable_count, len(concepts))
    purpose = principles[0] if principles else f"Apply {title} with source-traced evidence."
    trigger = (
        decision_rules[0]
        if decision_rules
        else f"Use when a task requires {title}."
    )
    candidate_id = f"candidate_{index:03d}_{_slug(title)}"
    return (
        SkillCandidate(
            candidate_id=candidate_id,
            title=title,
            provisional_skill_type=provisional_type,
            source_methodology_module=module_id,
            supporting_evidence=supporting_evidence,
            confidence=confidence,
            risk_flags=sorted(set(risk_flags)),
            status=status,
            skill_contract=SkillContract(
                purpose=purpose,
                trigger=trigger,
                inputs=["knowledge task", "source-traced methodology context"],
                outputs=["evidence-grounded result or explicit review requirement"],
                workflow_steps=workflows or decision_rules or [purpose],
                constraints=constraints,
                failure_modes=failure_modes,
            ),
            merge_split_recommendation=recommendation,
            dependency_draft=[],
        ),
        rejected,
    )


def _merge_split_recommendation(
    actionable_count: int, concept_count: int
) -> MergeSplitRecommendation:
    if actionable_count >= 4:
        return MergeSplitRecommendation(
            action="split",
            reason="Module contains multiple independently actionable workflow or decision-rule clusters.",
        )
    if actionable_count == 0 and concept_count <= 1:
        return MergeSplitRecommendation(
            action="merge",
            reason="Concept-only candidate should merge with a related actionable candidate.",
        )
    return MergeSplitRecommendation(
        action="keep",
        reason="Candidate has a focused evidence-supported responsibility.",
    )


def _assign_dependency_draft(candidates: list[SkillCandidate]) -> None:
    planning = next(
        (
            candidate.candidate_id
            for candidate in candidates
            if candidate.provisional_skill_type == "planning"
        ),
        None,
    )
    functional = next(
        (
            candidate.candidate_id
            for candidate in candidates
            if candidate.provisional_skill_type == "functional"
        ),
        None,
    )
    for candidate in candidates:
        if candidate.provisional_skill_type == "functional" and planning:
            candidate.dependency_draft = [planning]
        elif candidate.provisional_skill_type == "atomic":
            dependency = functional or planning
            if dependency:
                candidate.dependency_draft = [dependency]


def _blocking_risk(risk_flags: list[str]) -> bool:
    return any(
        flag
        in {
            "low_confidence_evidence",
            "missing_evidence_text",
            "missing_source_path",
        }
        for flag in risk_flags
    )


def _statements(items: list[dict]) -> list[str]:
    return [str(item.get("statement") or "").strip() for item in items if str(item.get("statement") or "").strip()]


def _float(value: object, default: float) -> float:
    try:
        return min(1.0, max(0.0, float(value)))
    except (TypeError, ValueError):
        return default


def _int(value: object, default: int) -> int:
    try:
        return max(0, int(value))
    except (TypeError, ValueError):
        return default


def _slug(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.casefold()).strip("-")
    return slug or "skill"


def _read_json(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Methodology map not found: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("methodology_map.json must contain an object")
    return payload


def _render_report(plan: SkillCandidatePlan) -> str:
    lines = [
        "# Skill Candidate Planning Report",
        "",
        f"- Source package: `{plan.source_package_id}`",
        f"- Candidates: {plan.candidate_count}",
        f"- Unsupported claims excluded: {plan.unsupported_claim_count}",
        "- Anything2Skill integration: L3 contract absorbed + L4 capability fused",
        "- External runtime/provider/API: none",
        "",
    ]
    for candidate in plan.candidates:
        lines.extend(
            [
                f"## {candidate.title}",
                "",
                f"- Candidate ID: `{candidate.candidate_id}`",
                f"- Provisional type: {candidate.provisional_skill_type}",
                f"- Status: {candidate.status}",
                f"- Confidence: {candidate.confidence}",
                f"- Evidence: {', '.join(candidate.supporting_evidence)}",
                f"- Merge/split: {candidate.merge_split_recommendation.action}",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"

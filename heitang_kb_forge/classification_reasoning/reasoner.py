from heitang_kb_forge.schemas.classification_reasoning_schema import (
    ClassificationCandidate,
    ClassificationDecision,
    ClassificationReasoningInput,
    ClassificationReasoningReport,
)


_CATEGORY_TERMS: dict[str, tuple[str, ...]] = {
    "policy": ("must", "required", "do not", "forbidden", "policy", "rule", "必须", "禁止", "规则"),
    "claim": ("claim", "states", "says", "conclusion", "fact", "判断", "结论"),
    "evidence": ("source_path", "citation", "chunk", "evidence", "trace", "引用", "证据"),
    "task": ("todo", "task", "next step", "blocked", "owner review", "任务", "待办"),
}


def classify_items(payload: ClassificationReasoningInput | dict) -> ClassificationReasoningReport:
    data = (
        payload
        if isinstance(payload, ClassificationReasoningInput)
        else ClassificationReasoningInput.model_validate(payload)
    )
    allowed = {_key(category) for category in data.allowed_categories if category.strip()}
    decisions: list[ClassificationDecision] = []
    unresolved_item_ids: list[str] = []

    for candidate in data.candidates:
        decision = _classify_candidate(candidate, allowed)
        if decision.category == "unknown":
            unresolved_item_ids.append(candidate.item_id)
        decisions.append(decision)

    category_counts: dict[str, int] = {}
    for decision in decisions:
        category_counts[decision.category] = category_counts.get(decision.category, 0) + 1

    return ClassificationReasoningReport(
        status="classified" if decisions and not unresolved_item_ids else "classification_gaps_found",
        decision_count=len(decisions),
        decisions=decisions,
        unresolved_item_ids=unresolved_item_ids,
        category_counts=category_counts,
        summary=f"{len(decisions)} item(s) classified; {len(unresolved_item_ids)} unresolved.",
    )


def _classify_candidate(candidate: ClassificationCandidate, allowed: set[str]) -> ClassificationDecision:
    scores: dict[str, list[str]] = {}
    value = _candidate_value(candidate)
    for category, terms in _CATEGORY_TERMS.items():
        if allowed and _key(category) not in allowed:
            continue
        matches = [term for term in terms if term.lower() in value]
        if matches:
            scores[category] = matches

    if not scores:
        return ClassificationDecision(
            item_id=candidate.item_id,
            category="unknown",
            confidence=0.0,
            reason_codes=["no_classification_terms_matched"],
            source_id=candidate.source_id,
        )

    category = max(scores, key=lambda name: (len(scores[name]), _priority(name)))
    matches = scores[category]
    confidence = min(0.95, 0.55 + 0.1 * len(matches) + 0.1 * _label_bonus(candidate, category))
    return ClassificationDecision(
        item_id=candidate.item_id,
        category=category,
        confidence=round(confidence, 2),
        reason_codes=[f"matched_{category}_terms", f"matched_count_{len(matches)}"],
        matched_terms=matches,
        source_id=candidate.source_id,
    )


def _candidate_value(candidate: ClassificationCandidate) -> str:
    return " ".join([candidate.text, *candidate.labels]).strip().lower()


def _label_bonus(candidate: ClassificationCandidate, category: str) -> int:
    return 1 if any(_key(label) == _key(category) for label in candidate.labels) else 0


def _priority(category: str) -> int:
    order = {"policy": 4, "evidence": 3, "claim": 2, "task": 1}
    return order.get(category, 0)


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())

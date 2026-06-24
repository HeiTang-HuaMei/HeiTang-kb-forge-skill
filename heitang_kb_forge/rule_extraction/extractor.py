from heitang_kb_forge.schemas.rule_extraction_schema import (
    ExtractedRule,
    RuleExtractionInput,
    RuleExtractionReport,
    RuleExtractionSource,
)


_RULE_MARKERS: tuple[tuple[str, str], ...] = (
    ("prohibition", "must not"),
    ("prohibition", "do not"),
    ("prohibition", "cannot"),
    ("prohibition", "forbidden"),
    ("prohibition", "prohibited"),
    ("prohibition", "不得"),
    ("prohibition", "禁止"),
    ("requirement", "must"),
    ("requirement", "required"),
    ("requirement", "requires"),
    ("requirement", "shall"),
    ("requirement", "需要"),
    ("requirement", "必须"),
    ("requirement", "应"),
    ("boundary", "within scope"),
    ("boundary", "outside scope"),
    ("boundary", "scope"),
    ("boundary", "范围"),
    ("citation", "citation"),
    ("citation", "source_path"),
    ("citation", "引用"),
)


def extract_rules(payload: RuleExtractionInput | dict) -> RuleExtractionReport:
    data = payload if isinstance(payload, RuleExtractionInput) else RuleExtractionInput.model_validate(payload)
    allowed = {_key(scope_id) for scope_id in data.allowed_scope_ids if scope_id.strip()}
    rules: list[ExtractedRule] = []
    skipped_source_ids: list[str] = []

    for source in data.sources:
        if allowed and source.scope_id and _key(source.scope_id) not in allowed:
            skipped_source_ids.append(source.source_id)
            continue
        rules.extend(_extract_source_rules(source, len(rules) + 1))

    return RuleExtractionReport(
        status="rules_extracted" if rules else "no_rules_found",
        extracted_rule_count=len(rules),
        extracted_rules=rules,
        skipped_source_ids=skipped_source_ids,
        source_ids=[source.source_id for source in data.sources],
        summary=f"{len(rules)} rule(s) extracted from {len(data.sources)} source(s).",
    )


def _extract_source_rules(source: RuleExtractionSource, start_index: int) -> list[ExtractedRule]:
    rules: list[ExtractedRule] = []
    seen: set[str] = set()
    for line in source.text.splitlines():
        normalized = _normalize_rule_text(line)
        if not normalized:
            continue
        match = _match_marker(normalized)
        if match is None:
            continue
        rule_type, marker = match
        dedupe_key = _key(normalized)
        if dedupe_key in seen:
            continue
        seen.add(dedupe_key)
        rules.append(
            ExtractedRule(
                rule_id=f"{source.source_id}:rule-{start_index + len(rules):03d}",
                rule_type=rule_type,
                text=normalized,
                source_id=source.source_id,
                source_path=source.source_path,
                scope_id=source.scope_id,
                marker=marker,
            )
        )
    return rules


def _match_marker(text: str) -> tuple[str, str] | None:
    lowered = text.lower()
    for rule_type, marker in _RULE_MARKERS:
        if marker.lower() in lowered:
            return rule_type, marker
    return None


def _normalize_rule_text(line: str) -> str:
    text = str(line).strip()
    while text[:1] in {"-", "*", ">", "#"}:
        text = text[1:].strip()
    if len(text) > 2 and text[0].isdigit() and text[1] in {".", ")"}:
        text = text[2:].strip()
    return " ".join(text.split())


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())

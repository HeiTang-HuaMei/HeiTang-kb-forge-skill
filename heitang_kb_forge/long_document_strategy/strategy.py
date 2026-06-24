from heitang_kb_forge.schemas.long_document_strategy_schema import (
    LongDocumentStrategyInput,
    LongDocumentStrategyReport,
)


def build_long_document_strategy(payload: LongDocumentStrategyInput | dict) -> LongDocumentStrategyReport:
    data = payload if isinstance(payload, LongDocumentStrategyInput) else LongDocumentStrategyInput.model_validate(payload)
    if not data.sections:
        return LongDocumentStrategyReport(status="empty_document", summary="No sections were provided.")

    sections_by_id = {section.section_id: section for section in data.sections}
    missing_required = [section_id for section_id in data.required_section_ids if section_id not in sections_by_id]
    if missing_required:
        return LongDocumentStrategyReport(
            status="missing_required_sections",
            remaining_section_ids=[section.section_id for section in data.sections if not section.already_read],
            already_read_section_ids=[section.section_id for section in data.sections if section.already_read],
            missing_required_section_ids=missing_required,
            summary=f"{len(missing_required)} required section(s) are missing.",
        )

    reading_order: list[str] = []
    selected_char_count = 0
    already_read = [section.section_id for section in data.sections if section.already_read]
    candidates = [section for section in data.sections if not section.already_read]

    for section in candidates:
        section_chars = len(section.text)
        section_limit_reached = len(reading_order) >= data.max_sections_per_pass
        char_limit_reached = reading_order and selected_char_count + section_chars > data.max_chars_per_pass
        if section_limit_reached or char_limit_reached:
            break
        reading_order.append(section.section_id)
        selected_char_count += section_chars

    remaining = [section.section_id for section in candidates if section.section_id not in set(reading_order)]
    status = _status(reading_order, remaining, already_read)
    return LongDocumentStrategyReport(
        status=status,
        reading_order=reading_order,
        remaining_section_ids=remaining,
        already_read_section_ids=already_read,
        selected_char_count=selected_char_count,
        summary=(
            f"{len(reading_order)} section(s) scheduled, {len(remaining)} remaining, "
            f"{selected_char_count} character(s) selected."
        ),
    )


def _status(reading_order: list[str], remaining: list[str], already_read: list[str]) -> str:
    if not reading_order and already_read and not remaining:
        return "complete"
    if remaining:
        return "partial"
    return "ready"

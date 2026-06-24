from heitang_kb_forge.schemas.conflict_exception_schema import (
    ConflictExceptionInput,
    ConflictExceptionReport,
    ConflictRecord,
    ConflictStatement,
    ExceptionRecord,
)


_POSITIVE_POLARITIES = {"allow", "allowed", "support", "supports", "positive", "can", "允许", "支持"}
_NEGATIVE_POLARITIES = {"deny", "denied", "block", "blocked", "negative", "cannot", "禁止", "不得"}


def detect_conflict_exceptions(payload: ConflictExceptionInput | dict) -> ConflictExceptionReport:
    data = (
        payload
        if isinstance(payload, ConflictExceptionInput)
        else ConflictExceptionInput.model_validate(payload)
    )
    statements_by_topic: dict[str, list[ConflictStatement]] = {}
    exceptions: list[ExceptionRecord] = []

    for statement in data.statements:
        statements_by_topic.setdefault(_key(statement.topic), []).append(statement)
        if statement.exception_of.strip():
            exceptions.append(
                ExceptionRecord(
                    exception_id=f"exception-{len(exceptions) + 1:03d}",
                    statement_id=statement.statement_id,
                    exception_of=statement.exception_of,
                    topic=statement.topic,
                )
            )

    conflicts: list[ConflictRecord] = []
    for topic_key, statements in statements_by_topic.items():
        positive_ids = [item.statement_id for item in statements if _is_positive(item.polarity)]
        negative_ids = [item.statement_id for item in statements if _is_negative(item.polarity)]
        if positive_ids and negative_ids:
            conflicts.append(
                ConflictRecord(
                    conflict_id=f"conflict-{len(conflicts) + 1:03d}",
                    topic=statements[0].topic or topic_key,
                    positive_statement_ids=positive_ids,
                    negative_statement_ids=negative_ids,
                )
            )

    status = "pass"
    if conflicts and exceptions:
        status = "conflicts_with_exceptions_found"
    elif conflicts:
        status = "conflicts_found"
    elif exceptions:
        status = "exceptions_found"

    return ConflictExceptionReport(
        status=status,
        conflict_count=len(conflicts),
        exception_count=len(exceptions),
        conflicts=conflicts,
        exceptions=exceptions,
        checked_statement_ids=[statement.statement_id for statement in data.statements],
        summary=f"{len(conflicts)} conflict(s) and {len(exceptions)} exception(s) found.",
    )


def _is_positive(value: str) -> bool:
    return _key(value) in {_key(item) for item in _POSITIVE_POLARITIES}


def _is_negative(value: str) -> bool:
    return _key(value) in {_key(item) for item in _NEGATIVE_POLARITIES}


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())

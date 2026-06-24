from heitang_kb_forge.schemas.scope_resolver_schema import ScopeCandidate, ScopeResolverInput, ScopeResolverReport


def resolve_scope(payload: ScopeResolverInput | dict) -> ScopeResolverReport:
    data = payload if isinstance(payload, ScopeResolverInput) else ScopeResolverInput.model_validate(payload)
    allowed = {_key(scope_id) for scope_id in data.allowed_scope_ids if scope_id.strip()}
    candidate_by_id = {_key(candidate.scope_id): candidate for candidate in data.candidates}
    candidate_ids = [candidate.scope_id for candidate in data.candidates]

    explicit_key = _key(data.explicit_scope_id)
    if explicit_key:
        if allowed and explicit_key not in allowed:
            return _blocked(data, candidate_ids, "explicit_scope_not_allowed")
        if explicit_key not in candidate_by_id:
            return _blocked(data, candidate_ids, "explicit_scope_not_found")
        return _selected(data, candidate_ids, candidate_by_id[explicit_key].scope_id, "explicit_scope")

    query_key = _key(data.query)
    for candidate in data.candidates:
        if allowed and _key(candidate.scope_id) not in allowed:
            continue
        labels = [_key(label) for label in [candidate.scope_id, *candidate.labels] if label.strip()]
        if any(label and label in query_key for label in labels):
            return _selected(data, candidate_ids, candidate.scope_id, "query_label_match")

    for candidate in data.candidates:
        if candidate.is_default and (not allowed or _key(candidate.scope_id) in allowed):
            return _selected(data, candidate_ids, candidate.scope_id, "default_scope")

    return _blocked(data, candidate_ids, "no_scope_resolved")


def _selected(data: ScopeResolverInput, candidate_ids: list[str], scope_id: str, reason: str) -> ScopeResolverReport:
    return ScopeResolverReport(
        status="resolved",
        selected_scope_id=scope_id,
        selection_reason=reason,
        allowed_scope_ids=data.allowed_scope_ids,
        candidate_scope_ids=candidate_ids,
        summary=f"scope resolved by {reason}: {scope_id}",
    )


def _blocked(data: ScopeResolverInput, candidate_ids: list[str], reason: str) -> ScopeResolverReport:
    return ScopeResolverReport(
        status="blocked",
        selection_reason="blocked",
        allowed_scope_ids=data.allowed_scope_ids,
        candidate_scope_ids=candidate_ids,
        blocked_reason=reason,
        summary=f"scope resolution blocked: {reason}",
    )


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())

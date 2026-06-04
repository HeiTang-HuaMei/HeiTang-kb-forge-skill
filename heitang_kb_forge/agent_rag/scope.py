def parse_scope(scope: str | None = None, **filters: str | None) -> dict[str, str]:
    parsed = {key: value for key, value in filters.items() if value}
    if scope and ":" in scope:
        key, value = scope.split(":", 1)
        parsed[key.strip()] = value.strip()
    return parsed


def record_matches_scope(record: dict, scope: dict[str, str]) -> bool:
    if not scope:
        return True
    metadata = record.get("metadata", {})
    for key, value in scope.items():
        haystack = str(record.get(key) or metadata.get(key) or record.get("source_path") or "")
        if value not in haystack:
            return False
    return True

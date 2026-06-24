from heitang_kb_forge.scope_resolver import resolve_scope


def test_scope_resolver_prefers_allowed_explicit_scope():
    report = resolve_scope(
        {
            "query": "draft notes",
            "explicit_scope_id": "kb-a",
            "allowed_scope_ids": ["kb-a"],
            "candidates": [{"scope_id": "kb-a", "labels": ["alpha"]}],
        }
    )

    assert report.status == "resolved"
    assert report.selected_scope_id == "kb-a"
    assert report.selection_reason == "explicit_scope"


def test_scope_resolver_matches_query_label_then_default():
    matched = resolve_scope(
        {
            "query": "use finance handbook",
            "allowed_scope_ids": ["kb-finance", "kb-default"],
            "candidates": [
                {"scope_id": "kb-default", "labels": ["general"], "is_default": True},
                {"scope_id": "kb-finance", "labels": ["finance handbook"]},
            ],
        }
    )

    fallback = resolve_scope(
        {
            "query": "unknown area",
            "allowed_scope_ids": ["kb-default"],
            "candidates": [
                {"scope_id": "kb-default", "labels": ["general"], "is_default": True},
                {"scope_id": "kb-finance", "labels": ["finance handbook"]},
            ],
        }
    )

    assert matched.selected_scope_id == "kb-finance"
    assert matched.selection_reason == "query_label_match"
    assert fallback.selected_scope_id == "kb-default"
    assert fallback.selection_reason == "default_scope"


def test_scope_resolver_blocks_disallowed_explicit_scope():
    report = resolve_scope(
        {
            "query": "finance",
            "explicit_scope_id": "kb-secret",
            "allowed_scope_ids": ["kb-public"],
            "candidates": [{"scope_id": "kb-secret", "labels": ["secret"]}],
        }
    )

    assert report.status == "blocked"
    assert report.blocked_reason == "explicit_scope_not_allowed"

from __future__ import annotations


def build_dedup_report(registries: dict[str, list[dict]]) -> dict:
    by_hash: dict[str, list[dict]] = {}
    for entries in registries.values():
        for entry in entries:
            digest = entry.get("content_hash")
            if digest:
                by_hash.setdefault(digest, []).append(entry)
    duplicate_groups = [
        {
            "content_hash": digest,
            "asset_count": len(entries),
            "asset_paths": [entry["path"] for entry in entries],
            "recommendation": "review_duplicate_assets_no_auto_delete",
        }
        for digest, entries in sorted(by_hash.items())
        if len(entries) > 1
    ]
    return {
        "dedup_report_version": "3.9.0-alpha.1",
        "duplicate_group_count": len(duplicate_groups),
        "duplicate_groups": duplicate_groups,
        "destructive_action_taken": False,
        "recommendation_only": True,
    }
